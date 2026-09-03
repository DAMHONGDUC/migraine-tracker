import { randomBytes } from "node:crypto";

import { getAuth } from "firebase-admin/auth";
import { initializeApp } from "firebase-admin/app";
import {
  DocumentData,
  FieldValue,
  getFirestore,
  Timestamp,
} from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { defineSecret } from "firebase-functions/params";
import { logger } from "firebase-functions/v2";
import { HttpsError, onCall, onRequest } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";

import {
  ACCESS_COLLECTION,
  PREMIUM_FIELD,
  premiumEmailsFrom,
} from "./core/accessAllowlist";
import { AlertRunResult, runPressureAlerts } from "./core/alertRun";
import {
  ALERT_RUN_COLLECTION,
  alertRunDocument,
  alertRunId,
  alertRunRecord,
} from "./core/alertRunRecord";
import { geohashCenter } from "./core/geohash";
import { AlertUser } from "./core/grouping";
import { maxDrop24h } from "./core/pressure";
import { offsetFromLongitude } from "./core/quietHours";
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
  fetchWeatherBundle,
  weatherKitPrivateKey,
  WeatherCurrent,
  WeatherDay,
  WeatherHour,
  WeatherKitConfigError,
} from "./weather/weatherKit";

initializeApp();

const REGION = "europe-west1";
const revenuecatAuth = defineSecret("REVENUECAT_WEBHOOK_AUTH");

/** Firestore caps a batch at 500 writes. */
const BATCH_LIMIT = 500;

/** Every 3h: group alert-enabled premium users by geohash cell, fetch ONE forecast per cell, push to users whose personal threshold is exceeded. */
export const pressureAlertJob = onSchedule(
  {
    schedule: "every 3 hours",
    region: REGION,
    timeZone: "UTC",
    // Cost ceiling: one sequential run is all this job ever needs.
    maxInstances: 1,
    memory: "256MiB",
    timeoutSeconds: 540,
    // Without this the signing key is empty at runtime and every WeatherKit request 401s — a deploy-time binding, not something the code can check.
    secrets: [weatherKitPrivateKey],
  },
  async () => {
    const db = getFirestore();
    const now = new Date();

    let result: AlertRunResult | null = null;
    let thrown: unknown;

    try {
      result = await runAlertPass(db, now);
    } catch (error) {
      thrown = error;
      logger.error("pressureAlertJob failed", { error: String(error) });
    }

    // Best-effort, and after the catch: the history is a record OF the run, so a run that threw is the one it most needs to hold. A failure to write it must not become a second failure on top.
    const record = alertRunRecord({
      startedAt: now,
      finishedAt: new Date(),
      result,
      error: thrown,
    });
    try {
      await db
        .collection(ALERT_RUN_COLLECTION)
        .doc(alertRunId(now))
        .set(alertRunDocument(record));
    } catch (error) {
      logger.error("alert run history write failed", {
        runId: alertRunId(now),
        status: record.status,
        error: String(error),
      });
    }

    logger.info("pressureAlertJob done", {
      runId: alertRunId(now),
      status: record.status,
      users: record.users,
      cells: record.cells,
      failedCells: record.failedCellCount,
      pushesSent: record.pushesSent,
      silentPushes: record.silentPushes,
      onsetPushes: record.onsetPushes,
      // The one number that says whether a zero-push run was quiet weather or a broken run.
      maxDropHpa: record.maxDropHpa,
    });

    // Re-thrown so the run still shows as failed to the scheduler; the history is written either way.
    if (thrown !== undefined) throw thrown;
    if (record.failedCellCount > 0) {
      throw new Error(`${record.failedCellCount} cells failed weather fetch`);
    }
  },
);

/**
 * Everything `pressureAlertJob` does apart from writing its own history —
 * split out so the history write sits outside the try/catch that guards it
 * and cannot be skipped by an early return or a throw from inside.
 */
async function runAlertPass(
  db: FirebaseFirestore.Firestore,
  now: Date,
): Promise<AlertRunResult> {
  const rows = await db
    .collection(ACCESS_COLLECTION)
    .where(PREMIUM_FIELD, "==", true)
    .get();
  const emails = premiumEmailsFrom(
    rows.docs.map((doc) => ({ id: doc.id, premium: doc.get(PREMIUM_FIELD) })),
  );

  // The webhook is the only writer of `premium`, so an allow-listed account never carries it — without this the cron is the one surface that disagrees with the app.
  //
  // Resolved through Auth rather than a `users.email` query: Auth normalises an address to lower case, Firestore `==` does not, so a doc written "Review@BaroEase.app" is invisible to the query the allow-list can build. Auth also answers for an account that has no `users` doc yet, which the query cannot.
  const granted = new Set<string>();
  for (const email of emails) {
    try {
      granted.add((await getAuth().getUserByEmail(email)).uid);
    } catch (error) {
      // Normal, not broken: an address the owner added before that person ever signed in. Logged with the address because a list of two or three the owner typed themselves is exactly what this line has to name to be useful.
      logger.warn("allow-listed address has no account", {
        email,
        error: String(error),
      });
    }
  }

  const subscribers = await db
    .collection("users")
    .where("premium", "==", true)
    .get();
  const docs: { id: string; data: DocumentData }[] = subscribers.docs.map(
    (doc) => ({ id: doc.id, data: doc.data() }),
  );

  if (granted.size > 0) {
    const refs = [...granted].map((uid) => db.collection("users").doc(uid));
    for (const doc of await db.getAll(...refs)) {
      const data = doc.data();
      // No doc means the account exists but has never registered a device — nothing to push to.
      if (data !== undefined) docs.push({ id: doc.id, data });
    }
  }

  const users: AlertUser[] = [];
  const seen = new Set<string>();
  for (const doc of docs) {
    // A premium subscriber who is also allow-listed appears in both sets.
    if (seen.has(doc.id)) continue;
    seen.add(doc.id);

    const data = doc.data;
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
      tzOffsetMinutes: resolveOffsetMinutes(data, doc.id),
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

  return runPressureAlerts(users, {
    now,
    fetchCellDrop: async (cell) => {
      const { lat, lon } = geohashCenter(cell);
      const forecast = await fetchHourlyPressure(lat, lon);
      return maxDrop24h(forecast, now);
    },
    sendPush: async (user, drop, { silent, stage }) => {
      const onset = stage === "onset";

      await getMessaging().send({
        token: user.fcmToken,
        notification: {
          // Two pushes for one front, and the wording is the whole difference: one is a plan, the other is a dose.
          title: onset ? "Pressure is dropping now" : "Pressure drop ahead",
          body: onset
            ? `Barometric pressure is starting to fall ` +
              `${drop.dropHpa.toFixed(1)} hPa. Take what you take early.`
            : `Barometric pressure is forecast to fall ` +
              `${drop.dropHpa.toFixed(1)} hPa within 24 hours.`,
        },
        // - The app renders the row from its own ARB: the strings above are English whatever language the user picked, so only numbers travel.
        data: {
          type: "pressureAlert",
          eventId: drop.eventId,
          stage,
          dropHpa: String(drop.dropHpa),
          at: now.toISOString(),
        },
        // `content-available` is sent so a background handler can be added later without touching the cron.
        //
        // A push in the user's night carries no `sound` key at all — an empty string still plays the default — and `passive` on top of that keeps it off the lock screen until the phone is next picked up. The alert is still worth having at 03:00; being woken by it is not.
        apns: {
          payload: {
            aps: silent
              ? { "content-available": 1, "interruption-level": "passive" }
              : { sound: "default", "content-available": 1 },
          },
        },
      });
    },
    // lastAlertDropHpa is written for the client, not for dedupe.
    recordAlert: async (uid, drop, at, eventId) => {
      await db.collection("users").doc(uid).update({
        lastAlertAt: Timestamp.fromDate(at),
        // The STAGE's id, so the onset push is not read back as a repeat of the heads-up that preceded it.
        lastAlertEventId: eventId,
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
}

/**
 * How far east of UTC the user is, which is all the run needs to know whether a
 * push would land in their night.
 *
 * The device writes it at registration; longitude answers for one that
 * registered before the app started sending it, and is why an existing user
 * gets a quiet night without having to open the app. `tz` beside it is the zone
 * abbreviation ("ICT") and is for a human reading the document — it is not
 * parseable, which is exactly why this field exists.
 */
function resolveOffsetMinutes(data: DocumentData, uid: string): number {
  if (typeof data.tzOffsetMinutes === "number") return data.tzOffsetMinutes;
  try {
    return offsetFromLongitude(geohashCenter(data.geohash5).lon);
  } catch (error) {
    // A geohash the decoder refuses. UTC is the only answer left, and the run must not lose the user over it — the push still goes, it just may carry a sound at the wrong hour.
    logger.warn("offset fallback failed, assuming UTC", {
      uid,
      geohash5: data.geohash5,
      error: String(error),
    });
    return 0;
  }
}

/** Hands a signed-in user the key their devices encrypt attack payloads with, minting one on first use. */
export const getSyncKey = onCall(
  { region: REGION, maxInstances: 10, memory: "256MiB" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "sign in first");
    }
    // Anonymous sessions never sync (hard rule 1), and their uid dies with the install, so a key issued to one could never be recovered.
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

/** Deletes everything the backend holds about the caller, then their account. */
export const deleteAccount = onCall(
  { region: REGION, maxInstances: 10, memory: "256MiB" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "sign in first");
    }
    // An anonymous session has nothing on the server to delete, and letting it through would delete an auth user the app still believes it has.
    if (request.auth?.token.firebase?.sign_in_provider === ANONYMOUS_PROVIDER) {
      throw new HttpsError("permission-denied", "account required");
    }

    const db = getFirestore();

    return tearDownAccount(uid, {
      deleteRecords: async (owner, collection) => {
        let deleted = 0;
        // Paged: a long history would blow the 500-write batch limit, and a teardown that half-runs is what hard rule 8 forbids.
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

/** RevenueCat → Firestore premium flag. Auth via shared secret header configured in the RevenueCat dashboard. */
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

/** Sends a push to the caller's own registered device. */
/** The app's only weather source. */
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

    // Hours before and after now. Bounded so one caller cannot ask for a decade and turn a cache miss into an enormous fetch.
    const hoursBack = Math.min(Math.max(Number(request.data?.hoursBack) || 0, 0), 240);
    const hoursForward = Math.min(
      Math.max(Number(request.data?.hoursForward) || 0, 0),
      240,
    );

    // Whether the caller wants current conditions and the daily forecast on top of the hourly series.
    const full = request.data?.full === true;

    const now = new Date();
    const key = `${cellKey(lat, lon)}_${hoursBack}_${hoursForward}${full ? "_full" : ""}`;
    const doc = db.collection("weather_cache").doc(key);
    const cached = await doc.get();

    if (cached.exists && isFresh(cached.get("cachedAt")?.toDate(), now)) {
      return {
        hours: cached.get("hours") as WeatherHour[],
        current: cached.get("current") ?? null,
        days: cached.get("days") ?? [],
        cached: true,
      };
    }

    const center = cellCenter(cellKey(lat, lon));
    let hours: WeatherHour[];
    let current: WeatherCurrent | null = null;
    let days: WeatherDay[] = [];

    // Named rather than left to become a bare `internal`.
    try {
      const window = {
        start: new Date(now.getTime() - hoursBack * 3_600_000),
        end: new Date(now.getTime() + hoursForward * 3_600_000),
      };

      if (full) {
        const bundle = await fetchWeatherBundle(
          center.lat,
          center.lon,
          window,
          {},
        );

        hours = bundle.hours;
        current = bundle.current ?? null;
        days = bundle.days;
      } else {
        hours = await fetchHourlyWeather(center.lat, center.lon, window, {});
      }
    } catch (error) {
      if (error instanceof WeatherKitConfigError) {
        logger.error("weatherkit not configured", { missing: error.missing });
        throw new HttpsError("failed-precondition", error.message);
      }
      logger.error("weatherkit fetch failed", { key, error: String(error) });
      throw new HttpsError("unavailable", String(error));
    }

    // Best-effort: a cache that fails to write must not fail the request the caller actually made.
    try {
      await doc.set({ hours, current, days, cachedAt: now });
    } catch (error) {
      logger.warn("weather cache write failed", { key, error: String(error) });
    }

    return { hours, current, days, cached: false };
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
      // Not an error on our side: the device never registered, which is itself the diagnosis the caller is looking for.
      logger.warn("test push refused: no fcmToken", {
        uid,
        userDocExists: snapshot.exists,
      });
      throw new HttpsError("failed-precondition", "no fcmToken registered");
    }

    const now = new Date();

    // FCM's own refusals are the answer this row exists to get — a missing APNs key, a token from another project, a token the device dropped.
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
      // The code alone, because this message lands in a snackbar: `String(error)` beside it ran to several lines of SDK prose and pushed the card off the screen. The full text is in the log line above and in `details` for a caller that wants it.
      throw new HttpsError("unavailable", code, { error: String(error) });
    }

    logger.info("test push sent", { uid });
    return { sent: true };
  },
);
