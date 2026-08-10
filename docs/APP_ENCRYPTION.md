# App encryption and export compliance

What BaroEase does with cryptography, and what that means for the
`ITSAppUsesNonExemptEncryption` key and App Store Connect's export-compliance
question.

**This is a record of the facts, not legal advice.** The facts below are drawn
from the code and are checkable. The classification drawn from them is a legal
determination and belongs to the owner and their counsel — the same bar as the
privacy policy (`REMAINING_WORK.md` item 16).

## The state of it today

`ios/Runner/Info.plist` declares `ITSAppUsesNonExemptEncryption` as **`false`**,
and its comment says the answer holds only while the app's one cryptographic
call is a SHA-256 of the Sign in with Apple nonce. It ends: *"REVISIT when the
encrypted attack sync in hard rule 1 actually ships."*

**That sync has shipped.** Hard rule 12 describes it as built, and
`AesGcmAttackCipher` encrypts every synced record. So the condition the comment
named has been met and the `false` is stale — it describes a version of the app
that no longer exists.

## What the app actually does

Three distinct mechanisms, and they are not in the same category:

| # | What | Where | Implementation |
|---|---|---|---|
| 1 | SHA-256 of the Sign in with Apple nonce | `firebase_auth_repository.dart` | `crypto` package |
| 2 | TLS for every network call (Firestore, Functions, FCM, weather) | throughout | the OS |
| 3 | **AES-256-GCM over synced record payloads** | `aes_gcm_attack_cipher.dart` | `cryptography` package |

**1 and 2 are the exempt pair the current `false` rests on.** A hash is not
encryption, and it is used for authentication — Apple signs the nonce into the
token so it cannot be replayed. TLS is the operating system's own.

**3 is the one that changes the answer**, and it is worth being precise about
why. AES-256-GCM is a standard algorithm, accepted by every international
standards body, so it is not the "proprietary algorithm" case. It is the
*second* case in Apple's list: a standard algorithm used **in addition to, and
not through, the encryption within Apple's operating system**. The
`cryptography` package resolves `AesGcm.with256bits()` to a pure-Dart
implementation here — `cryptography_flutter`, which would route it to
CryptoKit/CommonCrypto, is deliberately not a dependency. So the AES is the
app's own code, not Apple's.

Two further facts about mechanism 3, because both bear on the classification:

- **It is not the app's primary function.** BaroEase is a migraine tracker; the
  encryption is ancillary, protecting the user's own health records in transit
  to and at rest on the backend. It offers no information-security capability
  to the user and exposes no cryptographic interface.
- **It is not end-to-end, and the key is not the user's.** `getSyncKey` mints
  and holds a per-account AES-256 key server-side (hard rule 12). This matters
  here only because it rules out describing the app as an end-to-end encrypted
  messaging or storage product, which is a different and more heavily
  scrutinised category.

## What this means

The app contains item 3, which is the second bullet of Apple's
documentation-required list. On the plain reading of that list, **the honest
answer to `ITSAppUsesNonExemptEncryption` is now `true`**, with the app then
self-classified as mass-market software using standard encryption.

That path normally carries a filing obligation — an annual self-classification
report to BIS and the NSA, or a CCATS — and Apple will ask for the resulting
identifier at upload. **Do not flip the key to `true` without having decided
that half first**, or an upload can be blocked on a document that does not
exist yet.

There is a second reading worth putting in front of counsel rather than
deciding here: Note 4 to Category 5 Part 2 of the EAR excludes items whose
primary function is not information security and whose cryptography is limited
to supporting that primary function. The two bullets above are written to
answer exactly that question. Which reading applies is the lawyer's call, not
this document's.

## What to do

1. **Decide the classification** with counsel — Note 4 exclusion, or mass
   market with a self-classification report.
2. **File first if a report is needed**, and keep the identifier where the
   submission can find it.
3. **Then set `ITSAppUsesNonExemptEncryption` to match**, and update the
   comment in `Info.plist` so it stops pointing at a revisit that has happened.
4. **Keep this file true.** Anything new that encrypts — a second cipher, key
   rotation, an offline export that is encrypted at rest — changes the table
   above and must be added in the same change, the way hard rule 17 governs the
   privacy policy.

## Why the answer is pre-declared in `Info.plist` at all

The key answers App Store Connect's export question at upload time rather than
asking a human on every build. That is worth keeping — but it is also why a
stale value is dangerous rather than merely untidy: nothing prompts anyone to
re-read it, and the declaration goes out with every upload unexamined.
