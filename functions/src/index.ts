import { randomBytes } from "node:crypto";

import { getAuth } from "firebase-admin/auth";
import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { defineSecret } from "firebase-functions/params";
import { logger } from "firebase-functions/v2";
import { HttpsError, onCall, onRequest } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";

import { runPressureAlerts } from "./core/alertRun";
import { geohashCenter } from "./core/geohash";
import { AlertUser } from "./core/grouping";
import { maxDrop24h } from "./core/pressure";
import { tearDownAccount } from "./core/accountTeardown";
import {
  ANONYMOUS_PROVIDER,
  resolveSyncKey,
  SYNC_KEY_BYTES,
} from "./core/syncKey";
import { premiumFromEvent } from "./revenuecat";
import {
  cellCenter,
  cellKey,
  isFresh,
} from "./weather/hourlyCache";
import {
  fetchHourlyPressure,
  fetchHourlyWeather,
  weatherKitPrivateKey,
  WeatherHour,
  WeatherKitConfigError,
} from "./weather/weatherKit";

initializeApp();

const REGION = "europe-west1";
const revenuecatAuth = defineSecret("REVENUECAT_WEBHOOK_AUTH");

/** Firestore caps a batch at 500 writes. */
const BATCH_LIMIT = 500;

/**
 * Every 3h: group alert-enabled premium users by geohash cell, fetch ONE
 * forecast per cell, push to users whose personal threshold is exceeded.
 * Idempotent: dedupe state lives on the user doc, so re-runs never
 * double-send. Weather failures are collected and re-thrown at the end —
 * fail loud, never silently skip a cohort.
 */
export const pressureAlertJob = onSchedule(
  {
    schedule: "every 3 hours",
    region: REGION,
    timeZone: "UTC",
    // Cost ceiling: one sequential run is all this job ever needs.
    maxInstances: 1,
    memory: "256MiB",
    timeoutSeconds: 540,
    // Without this the signing key is empty at runtime and every WeatherKit
    // request 401s — a deploy-time binding, not something the code can check.
    secrets: [weatherKitPrivateKey],
  },
  async () => {
    const db = getFirestore();
    const now = new Date();

    const snapshot = await db
      .collection("users")
      .where("premium", "==", true)
      .get();

    const users: AlertUser[] = [];
    for (const doc of snapshot.docs) {
      const data = doc.data();
      if (typeof data.fcmToken !== "string" || data.fcmToken.length === 0) {
        continue;
      }
      if (typeof data.geohash5 !== "string" || data.geohash5.length !== 5) {
        continue;
      }
      users.push({
        uid: doc.id,
        geohash5: data.geohash5,
        fcmToken: data.fcmToken,
        thresholdHpa:
          typeof data.alertThreshold === "number" ? data.alertThreshold : 5,
        history: {
          lastAlertAt:
            data.lastAlertAt instanceof Timestamp
              ? data.lastAlertAt.toDate()
              : undefined,
          lastEventId:
            typeof data.lastAlertEventId === "string"
              ? data.lastAlertEventId
              : undefined,
        },
      });
    }

    const result = await runPressureAlerts(users, {
      now,
      fetchCellDrop: async (cell) => {
        const { lat, lon } = geohashCenter(cell);
        const forecast = await fetchHourlyPressure(lat, lon);
        return maxDrop24h(forecast, now);
      },
      sendPush: async (user, drop) => {
        await getMessaging().send({
          token: user.fcmToken,
          notification: {
            title: "Pressure drop ahead",
            body:
              `Barometric pressure is forecast to fall ` +
              `${drop.dropHpa.toFixed(1)} hPa within 24 hours.`,
          },
          // - The app renders the row from its own ARB: the strings above are
          //   English whatever language the user picked, so only numbers travel.
          // - eventId is what keeps every writer of this row idempotent.
          data: {
            type: "pressureAlert",
            eventId: drop.eventId,
            dropHpa: String(drop.dropHpa),
            at: now.toISOString(),
          },
          // Sent so a background handler can be added later without touching
          // the cron. There is none today, so an alert arriving while the app
          // is shut reaches the list only via sync from a device that saw it.
          apns: {
            payload: { aps: { sound: "default", "content-available": 1 } },
          },
        });
      },
      // lastAlertDropHpa is written for the client, not for dedupe: the
      // launch reconcile rebuilds the missed notification row from these
      // three fields, and without the reading the row cannot say how far
      // pressure fell.
      recordAlert: async (uid, drop, at) => {
        await db.collection("users").doc(uid).update({
          lastAlertAt: Timestamp.fromDate(at),
          lastAlertEventId: drop.eventId,
          lastAlertDropHpa: drop.dropHpa,
        });
      },
      removeToken: async (uid) => {
        await db
          .collection("users")
          .doc(uid)
          .update({ fcmToken: FieldValue.delete() });
      },
      logError: (message, data) => logger.error(message, data),
      logInfo: (message, data) => logger.info(message, data),
    });

    logger.info("pressureAlertJob done", {
      users: result.users,
      cells: result.cells,
      failedCells: result.failedCells.length,
      pushesSent: result.pushesSent,
    });
    if (result.failedCells.length > 0) {
      throw new Error(`${result.failedCells.length} cells failed weather fetch`);
    }
  },
);

/**
 * Hands a signed-in user the key their devices encrypt attack payloads with,
 * minting one on first use. Read-or-create runs in a transaction so two
 * devices signing in at once cannot each mint a key, which would leave one
 * writing payloads the other could not read.
 *
 * The key lives in `sync_keys/{uid}`, which no client can reach: rules deny
 * that collection outright and only the Admin SDK bypasses them. This is
 * server-held custody, NOT end-to-end encryption — the copy shown to the user
 * must not claim otherwise.
 */
export const getSyncKey = onCall(
  { region: REGION, maxInstances: 10, memory: "256MiB" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "sign in first");
    }
    // Anonymous sessions never sync (hard rule 1), and their uid dies with
    // the install, so a key issued to one could never be recovered.
    if (request.auth?.token.firebase?.sign_in_provider === ANONYMOUS_PROVIDER) {
      throw new HttpsError("permission-denied", "account required");
    }

    const db = getFirestore();
    const ref = db.collection("sync_keys").doc(uid);
    const now = new Date();

    const key = await db.runTransaction(async (tx) =>
      resolveSyncKey(uid, {
        now,
        load: async () => {
          const snapshot = await tx.get(ref);
          const stored = snapshot.get("key");
          return typeof stored === "string" ? stored : null;
        },
        save: async (_uid, value, at) => {
          tx.set(ref, { key: value, createdAt: Timestamp.fromDate(at) });
        },
        generateKey: () => randomBytes(SYNC_KEY_BYTES).toString("base64"),
      }),
    );

    return { key };
  },
);

/**
 * Deletes everything the backend holds about the caller, then their account.
 *
 * Server-side of necessity, not convenience: firestore.rules denies a client
 * deleting users/{uid} — its write rule reads request.resource.data, which
 * does not exist on a delete — and denies sync_keys/{uid} to everyone. Only
 * the Admin SDK reaches them.
 *
 * The client still wipes its own device: this is the half it cannot do.
 */
export const deleteAccount = onCall(
  { region: REGION, maxInstances: 10, memory: "256MiB" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "sign in first");
    }
    // An anonymous session has nothing on the server to delete, and letting
    // it through would delete an auth user the app still believes it has.
    if (request.auth?.token.firebase?.sign_in_provider === ANONYMOUS_PROVIDER) {
      throw new HttpsError("permission-denied", "account required");
    }

    const db = getFirestore();

    return tearDownAccount(uid, {
      deleteRecords: async (owner, collection) => {
        let deleted = 0;
        // Paged: a long history would blow the 500-write batch limit, and a
        // teardown that half-runs is what hard rule 8 forbids.
        for (;;) {
          const page = await db
            .collection(collection)
            .where("userId", "==", owner)
            .limit(BATCH_LIMIT)
            .get();

          if (page.empty) return deleted;

          const batch = db.batch();
          for (const doc of page.docs) batch.delete(doc.ref);
          await batch.commit();
          deleted += page.size;
        }
      },
      deleteUserDoc: async (owner) => {
        await db.collection("users").doc(owner).delete();
      },
      deleteSyncKey: async (owner) => {
        await db.collection("sync_keys").doc(owner).delete();
      },
      deleteAuthUser: async (owner) => getAuth().deleteUser(owner),
      logInfo: (message, data) => logger.info(message, data),
    });
  },
);

/**
 * RevenueCat → Firestore premium flag. Auth via shared secret header
 * configured in the RevenueCat dashboard.
 */
export const revenuecatWebhook = onRequest(
  {
    region: REGION,
    secrets: [revenuecatAuth],
    // Cost ceiling: webhook volume is tiny; cap scale-out hard.
    maxInstances: 2,
    memory: "256MiB",
  },
  async (req, res) => {
    if (req.headers.authorization !== revenuecatAuth.value()) {
      res.status(401).send("unauthorized");
      return;
    }
    const event = (req.body as { event?: { type?: string; app_user_id?: string } })
      .event;
    if (!event?.type || !event.app_user_id) {
      res.status(400).send("malformed event");
      return;
    }

    const premium = premiumFromEvent(event.type);
    if (premium !== null) {
      await getFirestore()
        .collection("users")
        .doc(event.app_user_id)
        .set({ premium }, { merge: true });
      logger.info("premium updated", {
        uid: event.app_user_id,
        type: event.type,
        premium,
      });
    }
    res.status(200).send("ok");
  },
);

/**
 * Sends a push to the caller's own registered device. Dev tooling for the
 * one thing no test can prove: that the APNs key, the entitlement and the
 * token all line up on real hardware.
 *
 * **It never takes a token or a uid.** The target is always
 * `request.auth.uid`'s own `fcmToken`, so the worst anyone can do with it is
 * notify themselves. That is the whole of its security model, and it is why
 * it can ship to the same project real users are on — there is no dev
 * project to hide it in (`env/dev.json` and `env/prod.json` share one).
 *
 * Anonymous callers are refused, like `getSyncKey` and `deleteAccount`.
 * Premium requires an account, alerts require premium, so the cron can never
 * target an anonymous session — letting one test push here would prove a path
 * that does not exist in production.
 *
 * The payload mirrors a real pressure alert — same `data` keys, same
 * `content-available` — so a successful test exercises the path the cron
 * uses, not a simpler one. `eventId` is stamped `test:` so the client's
 * idempotent writers cannot mistake it for a real event.
 */
/**
 * The app's only weather source. It has none of its own: WeatherKit's signing
 * key cannot ship in a binary, so the app asks here and here asks Apple
 * (CLAUDE.md's tech-stack rule).
 *
 * **Any signed-in caller, anonymous included.** Weather is free: it is what
 * pairs a logged attack with the pressure at that moment, and hard rule 1
 * keeps every feature except sync and alerts working without an account. Auth
 * is required only so the endpoint has a caller at all — the app signs in
 * anonymously at launch, so this costs the user nothing.
 *
 * Only the *alert* is premium, and that is enforced in the cron, which reads
 * `users` where `premium == true`. Nothing about it belongs here.
 *
 * **The cache is what protects the quota.** Coordinates round to ~11km and a
 * series is reused for an hour, so WeatherKit calls scale with populated cells
 * rather than with users or taps — the 500k monthly quota now lands on one key
 * instead of being spread across users' own devices. The rounding pays twice:
 * no precise position is ever stored, matching what hard rule 1 allows.
 */
export const getWeather = onCall(
  {
    region: REGION,
    maxInstances: 10,
    memory: "256MiB",
    secrets: [weatherKitPrivateKey],
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "sign in first");
    }

    const db = getFirestore();

    const lat = Number(request.data?.lat);
    const lon = Number(request.data?.lon);

    if (!Number.isFinite(lat) || !Number.isFinite(lon)) {
      throw new HttpsError("invalid-argument", "lat and lon are required");
    }
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
      throw new HttpsError("invalid-argument", "lat or lon out of range");
    }

    // Hours before and after now. Bounded so one caller cannot ask for a
    // decade and turn a cache miss into an enormous fetch.
    const hoursBack = Math.min(Math.max(Number(request.data?.hoursBack) || 0, 0), 240);
    const hoursForward = Math.min(
      Math.max(Number(request.data?.hoursForward) || 0, 0),
      240,
    );

    const now = new Date();
    const key = `${cellKey(lat, lon)}_${hoursBack}_${hoursForward}`;
    const doc = db.collection("weather_cache").doc(key);
    const cached = await doc.get();

    if (cached.exists && isFresh(cached.get("cachedAt")?.toDate(), now)) {
      return { hours: cached.get("hours") as WeatherHour[], cached: true };
    }

    const center = cellCenter(cellKey(lat, lon));
    let hours: WeatherHour[];

    // Named rather than left to become a bare `internal`: the app treats any
    // weather failure as "no weather" (hard rule 4), so this log is the only
    // place the reason is ever stated.
    try {
      hours = await fetchHourlyWeather(
        center.lat,
        center.lon,
        {
          start: new Date(now.getTime() - hoursBack * 3_600_000),
          end: new Date(now.getTime() + hoursForward * 3_600_000),
        },
        {},
      );
    } catch (error) {
      if (error instanceof WeatherKitConfigError) {
        logger.error("weatherkit not configured", { missing: error.missing });
        throw new HttpsError("failed-precondition", error.message);
      }
      logger.error("weatherkit fetch failed", { key, error: String(error) });
      throw new HttpsError("unavailable", String(error));
    }

    // Best-effort: a cache that fails to write must not fail the request the
    // caller actually made.
    try {
      await doc.set({ hours, cachedAt: now });
    } catch (error) {
      logger.warn("weather cache write failed", { key, error: String(error) });
    }

    return { hours, cached: false };
  },
);

export const sendTestPush = onCall(
  { region: REGION, maxInstances: 5, memory: "256MiB" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "sign in first");
    }
    if (request.auth?.token.firebase?.sign_in_provider === ANONYMOUS_PROVIDER) {
      throw new HttpsError("permission-denied", "account required for alerts");
    }

    const snapshot = await getFirestore().collection("users").doc(uid).get();
    const token = snapshot.get("fcmToken");
    if (typeof token !== "string" || token.length === 0) {
      // Not an error on our side: the device never registered, which is
      // itself the diagnosis the caller is looking for. Logged all the same —
      // an HttpsError reaches the caller and nothing else, so without this
      // the run leaves no trace at all in the function's own log.
      logger.warn("test push refused: no fcmToken", {
        uid,
        userDocExists: snapshot.exists,
      });
      throw new HttpsError("failed-precondition", "no fcmToken registered");
    }

    const now = new Date();

    // FCM's own refusals are the answer this row exists to get — a missing
    // APNs key, a token from another project, a token the device dropped.
    // Unhandled they reach the app as a bare `internal` with nothing in it.
    try {
      await getMessaging().send({
        token,
        notification: {
          title: "BaroEase test",
          body: "If you can see this, push works on this device.",
        },
        data: {
          type: "pressureAlert",
          eventId: `test:${now.toISOString()}`,
          dropHpa: "0",
          at: now.toISOString(),
        },
        apns: {
          payload: { aps: { sound: "default", "content-available": 1 } },
        },
      });
    } catch (error) {
      const code = (error as { code?: string })?.code ?? "unknown";

      logger.error("test push failed", { uid, code, error: String(error) });
      throw new HttpsError("unavailable", `${code}: ${String(error)}`);
    }

    logger.info("test push sent", { uid });
    return { sent: true };
  },
);
