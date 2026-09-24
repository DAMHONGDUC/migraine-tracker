/**
 * One-off: move every bare-id synced document to `<userId>_<recordId>`.
 *
 *   cd functions && npm run build
 *   node lib/scripts/migrateOwnedIds.js --project <project-id>           # dry run: counts only
 *   node lib/scripts/migrateOwnedIds.js --project <project-id> --apply   # writes
 *
 * Needs `gcloud auth application-default login` for an account with Firestore
 * access to that project. Dry run by default, and `--project` is never
 * inferred — a write to prod has to be typed.
 *
 * Each move is one batch: the owned copy written and the legacy one deleted
 * together, so a crash leaves a record in one place or the other, never lost
 * and never doubled. Safe to run twice: a moved document is skipped.
 */
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldPath } from "firebase-admin/firestore";

import { SYNCED_COLLECTIONS } from "../core/accountTeardown";
import { MigrationDoc, planMigration } from "../core/ownedIdMigration";

const PAGE = 300;

interface Counts {
  scanned: number;
  moved: number;
  droppedLegacy: number;
  alreadyOwned: number;
  noOwner: number;
}

function argument(name: string): string | undefined {
  const index = process.argv.indexOf(name);
  return index === -1 ? undefined : process.argv[index + 1];
}

async function main(): Promise<void> {
  const projectId = argument("--project");
  const apply = process.argv.includes("--apply");

  if (!projectId) {
    console.error("--project <project-id> is required");
    process.exit(1);
  }
  initializeApp({ projectId });
  const db = getFirestore();

  console.log(`${apply ? "APPLYING" : "DRY RUN"} on ${projectId}`);
  for (const collection of SYNCED_COLLECTIONS) {
    const counts: Counts = {
      scanned: 0,
      moved: 0,
      droppedLegacy: 0,
      alreadyOwned: 0,
      noOwner: 0,
    };
    let last: string | undefined;

    for (;;) {
      let query = db
        .collection(collection)
        .orderBy(FieldPath.documentId())
        .limit(PAGE);
      if (last !== undefined) query = query.startAfter(last);
      const page = await query.get();
      if (page.empty) break;

      for (const doc of page.docs) {
        counts.scanned++;
        const data = doc.data() as MigrationDoc;
        const userId = typeof data.userId === "string" ? data.userId : "";
        const target = userId
          ? await db.collection(collection).doc(`${userId}_${doc.id}`).get()
          : undefined;
        const step = planMigration(
          doc.id,
          data,
          target?.exists ? (target.data() as MigrationDoc) : null,
        );

        switch (step.kind) {
          case "skip":
            counts[step.reason]++;
            break;
          case "dropLegacy":
            counts.droppedLegacy++;
            if (apply) await doc.ref.delete();
            break;
          case "move":
            counts.moved++;
            if (apply) {
              const batch = db.batch();
              batch.set(db.collection(collection).doc(step.to), step.data);
              batch.delete(doc.ref);
              await batch.commit();
            }
            break;
        }
      }
      last = page.docs[page.docs.length - 1].id;
    }
    console.log(collection, counts);
  }
}

main().catch((error) => {
  console.error("migration failed", error);
  process.exit(1);
});
