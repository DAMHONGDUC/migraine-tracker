import { readFileSync } from "node:fs";
import { resolve } from "node:path";

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";

/**
 * Runs firestore.rules against the emulator, which enforces them exactly as
 * production does.
 *
 * Worth the setup because the failure this catches is invisible any other
 * way: a read rule that cannot be *proved* safe for a query denies every
 * query while still looking correct, and reads identically to rules that were
 * never deployed. The unit tests over SyncCollection can only check the file
 * names a collection — never that Firestore will honour it.
 *
 * Needs the emulator: `firebase emulators:exec --only firestore "npm test"`,
 * and a JDK on PATH. Skipped when it is not running, so `npm test` alone
 * stays useful.
 */
const HOST = "127.0.0.1";
const PORT = 8080;

const SYNCED = ["attacks", "medications", "medication_reminders"] as const;

async function emulatorRunning(): Promise<boolean> {
  try {
    await fetch(`http://${HOST}:${PORT}/`);
    return true;
  } catch {
    return false;
  }
}

const available = await emulatorRunning();

describe.skipIf(!available)("firestore.rules", () => {
  let env: RulesTestEnvironment;

  beforeAll(async () => {
    env = await initializeTestEnvironment({
      projectId: "rules-test",
      firestore: {
        host: HOST,
        port: PORT,
        rules: readFileSync(resolve(__dirname, "../../firestore.rules"), "utf8"),
      },
    });
  });

  afterAll(async () => env?.cleanup());

  beforeEach(async () => env.clearFirestore());

  /** A record already on the server, written past the rules. */
  async function seed(collection: string, id: string, userId: string) {
    await env.withSecurityRulesDisabled(async (context) => {
      await context
        .firestore()
        .collection(collection)
        .doc(id)
        .set({ userId, updatedAt: new Date(), deleted: false });
    });
  }

  for (const collection of SYNCED) {
    describe(collection, () => {
      it("lets the owner query their own records", async () => {
        await seed(collection, "mine", "alice");
        const db = env.authenticatedContext("alice").firestore();

        // The whole point: an unprovable read rule denies this while looking
        // perfectly correct in the file.
        await assertSucceeds(
          db.collection(collection).where("userId", "==", "alice").get(),
        );
      });

      it("refuses a query that does not filter by owner", async () => {
        await seed(collection, "mine", "alice");
        const db = env.authenticatedContext("alice").firestore();

        await assertFails(db.collection(collection).get());
      });

      it("refuses reading someone else's record", async () => {
        await seed(collection, "hers", "alice");
        const db = env.authenticatedContext("mallory").firestore();

        await assertFails(db.collection(collection).doc("hers").get());
        await assertFails(
          db.collection(collection).where("userId", "==", "alice").get(),
        );
      });

      it("lets the owner write their own record", async () => {
        const db = env.authenticatedContext("alice").firestore();

        await assertSucceeds(
          db
            .collection(collection)
            .doc("new")
            .set({ userId: "alice", updatedAt: new Date(), deleted: false }),
        );
      });

      it("refuses creating a record owned by someone else", async () => {
        const db = env.authenticatedContext("mallory").firestore();

        await assertFails(
          db
            .collection(collection)
            .doc("planted")
            .set({ userId: "alice", updatedAt: new Date(), deleted: false }),
        );
      });

      it("refuses handing a record over by rewriting userId", async () => {
        await seed(collection, "mine", "alice");
        const db = env.authenticatedContext("alice").firestore();

        // Needs the incoming-document check; testing only the stored value
        // would let this through.
        await assertFails(
          db
            .collection(collection)
            .doc("mine")
            .set({ userId: "mallory", updatedAt: new Date(), deleted: false }),
        );
      });

      it("lets the owner delete their own record", async () => {
        await seed(collection, "mine", "alice");
        const db = env.authenticatedContext("alice").firestore();

        await assertSucceeds(db.collection(collection).doc("mine").delete());
      });

      it("lets the owner batch-delete, which is what the wipe does", async () => {
        await seed(collection, "one", "alice");
        await seed(collection, "two", "alice");
        const db = env.authenticatedContext("alice").firestore();

        // The GDPR wipe pages through and commits a batch; a batch is
        // evaluated per write, so this can fail where a single delete passes.
        const page = await db
          .collection(collection)
          .where("userId", "==", "alice")
          .get();
        const batch = db.batch();
        for (const doc of page.docs) batch.delete(doc.ref);

        await assertSucceeds(batch.commit());
      });

      it("refuses deleting someone else's record", async () => {
        await seed(collection, "hers", "alice");
        const db = env.authenticatedContext("mallory").firestore();

        await assertFails(db.collection(collection).doc("hers").delete());
      });

      it("refuses an anonymous caller", async () => {
        await seed(collection, "mine", "alice");
        const db = env.unauthenticatedContext().firestore();

        await assertFails(
          db.collection(collection).where("userId", "==", "alice").get(),
        );
      });
    });
  }

  it("keeps sync_keys away from every client", async () => {
    await env.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection("sync_keys").doc("alice").set({
        key: "secret",
      });
    });
    const db = env.authenticatedContext("alice").firestore();

    // Denied to its owner too: only the Admin SDK behind getSyncKey reads it.
    await assertFails(db.collection("sync_keys").doc("alice").get());
  });

  it("does not let the wildcard open an unlisted collection", async () => {
    const db = env.authenticatedContext("alice").firestore();

    await assertFails(
      db.collection("something_new").doc("x").set({ userId: "alice" }),
    );
  });
});
