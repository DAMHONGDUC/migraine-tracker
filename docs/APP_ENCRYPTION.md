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

## The filing record

What was actually given to Apple, kept verbatim. A regulatory answer is only
useful later if the exact words are recoverable — "roughly what we said" is not
something to reconstruct under a follow-up question.

### App Encryption Documentation, step 1 of 3 — "App Purpose" (10 Aug 2026)

> BaroEase is a consumer health-tracking app for people who experience migraine
> attacks, in particular those whose attacks are associated with changes in
> barometric pressure.
>
> The app allows a user to record a migraine attack in a few taps — intensity,
> head location, and any medication taken — and stores that history on their
> device. Each entry is paired with the barometric pressure at the time it was
> recorded. The app presents the user's own history back to them as charts and
> summaries, shows a 48-hour barometric pressure forecast, can send a
> notification when a significant pressure drop is forecast for their area,
> manages medication reminders, and can generate a PDF summary the user may
> choose to share with their physician. With the user's explicit permission, it
> can also read sleep and step data from Apple Health to display alongside
> their history. Subscriptions are offered for the forecasting and analysis
> features.
>
> The app's primary function is personal health tracking. It is not an
> information-security product: it provides no security capability to the user,
> offers no key management, and exposes no cryptographic interface. Its use of
> cryptography is ancillary and limited to protecting the user's own records —
> TLS for network communication, and AES-256-GCM applied to the user's records
> only if they choose to enable the optional account-based sync feature.

Three things in it are deliberate, and a rewrite should keep them:

- **The third paragraph answers Note 4, not the question asked.** The whole
  classification turns on whether the cryptography is ancillary, so the case is
  made at the first opportunity rather than left for a reviewer to infer.
- **No word promises diagnosis, treatment or prevention.** That is hard rule 11,
  and it also keeps the app out of the medical end-use exemption, which
  BaroEase would not qualify for and should not appear to claim.
- **"on their device", "only if they choose", "explicit permission"** are load
  bearing. Each one narrows what the encryption protects to the user's own
  data, which is the ancillary argument in miniature.

### Step 2 of 3 — "Which encryption algorithms does your app implement" (10 Aug 2026)

Two checkboxes were offered. **Only the second was selected:**

| Selected | Option |
|---|---|
| No | Proprietary, or not accepted as standard by international standard bodies |
| **Yes** | **Standard algorithms instead of, or in addition to, the encryption within Apple's operating system** |

The first is false and answering it would be costly as well as wrong:
AES-256-GCM and SHA-256 are NIST/IETF standards, and proprietary cryptography
is the case that draws the heaviest review.

The second is true for the reason set out in the table above — `cryptography`
resolves `AesGcm.with256bits()` to a pure-Dart implementation, so the AES runs
as the app's own code rather than through CryptoKit or CommonCrypto. This
answer is a direct consequence of that dependency choice: adding
`cryptography_flutter` would route the same algorithm through Apple's
implementation and change what is true here, so it is not a dependency to add
or drop casually.

### Step 3 of 3 — "Available for distribution in France" (10 Aug 2026)

**Yes.**

Not a fact about the code — it asks whether the app is sold in France. App
Store availability is left at all territories, so France is included, and any
other answer would be inconsistent with what is actually shipped.

**This answer carries an obligation.** France regulates the import and use of
cryptography and expects a declaration to ANSSI. Mass-market software using
standard algorithms normally falls under the simplified regime, but "simplified"
is not "none" — see checklist item 24. The two are tied: if France is ever
removed from availability, this answer and that obligation both change.
