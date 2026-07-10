import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { defineSecret } from "firebase-functions/params";
import { logger } from "firebase-functions/v2";
import { onRequest } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";

import { shouldAlert } from "./core/alerts";
import { geohashCenter } from "./core/geohash";
import { AlertUser, groupByGeohash } from "./core/grouping";
import { maxDrop24h } from "./core/pressure";
import { premiumFromEvent } from "./revenuecat";
import { fetchHourlyPressure } from "./weather/openMeteo";

initializeApp();

const REGION = "europe-west1";
const revenuecatAuth = defineSecret("REVENUECAT_WEBHOOK_AUTH");

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

    const cells = groupByGeohash(users);
    const failedCells: string[] = [];
    let pushesSent = 0;

    for (const [cell, cellUsers] of cells) {
      let drop;
      try {
        const { lat, lon } = geohashCenter(cell);
        const forecast = await fetchHourlyPressure(lat, lon);
        drop = maxDrop24h(forecast, now);
      } catch (error) {
        logger.error("cell forecast failed", {
          cell,
          users: cellUsers.length,
          error: String(error),
        });
        failedCells.push(cell);
        continue;
      }
      if (drop === null) continue;

      for (const user of cellUsers) {
        if (
          !shouldAlert({
            dropHpa: drop.dropHpa,
            thresholdHpa: user.thresholdHpa,
            eventId: drop.eventId,
            history: user.history,
            now,
          })
        ) {
          continue;
        }
        try {
          await getMessaging().send({
            token: user.fcmToken,
            notification: {
              title: "Pressure drop ahead",
              body:
                `Barometric pressure is forecast to fall ` +
                `${drop.dropHpa.toFixed(1)} hPa within 24 hours.`,
            },
            apns: { payload: { aps: { sound: "default" } } },
          });
          await db.collection("users").doc(user.uid).update({
            lastAlertAt: Timestamp.fromDate(now),
            lastAlertEventId: drop.eventId,
          });
          pushesSent++;
        } catch (error) {
          const code = (error as { code?: string }).code;
          if (code === "messaging/registration-token-not-registered") {
            // Stale token (app reinstalled) — drop it so this orphan doc
            // stops costing pushes and weather calls.
            await db
              .collection("users")
              .doc(user.uid)
              .update({ fcmToken: FieldValue.delete() });
            logger.info("stale token removed", { uid: user.uid });
          } else {
            logger.error("push failed", { uid: user.uid, error: String(error) });
          }
        }
      }
    }

    logger.info("pressureAlertJob done", {
      users: users.length,
      cells: cells.size,
      failedCells: failedCells.length,
      pushesSent,
    });
    if (failedCells.length > 0) {
      throw new Error(`${failedCells.length} cells failed weather fetch`);
    }
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
