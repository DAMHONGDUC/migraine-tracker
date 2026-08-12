# BaroEase — App Encryption Documentation

| | |
|---|---|
| **App name** | BaroEase — Migraine Tracker |
| **Bundle identifier** | `app.dd.migraine.tracker` |
| **Platform** | iOS |
| **Developer** | Dam Hong Duc |
| **Contact** | ducdam.dev@gmail.com |
| **Date** | 10 August 2026 |

---

## 1. App purpose

BaroEase is a consumer health-tracking application for people who experience
migraine attacks, in particular those whose attacks are associated with changes
in barometric pressure.

A user records an attack in a few taps — intensity, head location, and any
medication taken. Each entry is stored on the device and paired with the
barometric pressure at the time it was recorded. The app presents the user's
own history back to them as charts and summaries, displays a 48-hour barometric
pressure forecast, can notify the user when a significant pressure drop is
forecast for their area, manages medication reminders, and can generate a PDF
summary the user may choose to share with their physician. With the user's
explicit permission it can also read sleep and step data from Apple Health for
display alongside their own history. Paid subscriptions unlock the forecasting
and analysis features.

The application's primary function is personal health tracking. It is not an
information-security product.

## 2. Encryption implemented

The app implements or relies on three cryptographic mechanisms. All algorithms
are published international standards; none is proprietary.

| # | Mechanism | Algorithm | Key length | Implementation | Purpose |
|---|---|---|---|---|---|
| 1 | Transport security | TLS | negotiated | Apple operating system | Protects all network communication |
| 2 | Authentication nonce | SHA-256 | n/a (hash) | `crypto` Dart package | Hashes the Sign in with Apple nonce so the returned token cannot be replayed |
| 3 | Record protection | AES-256-GCM | 256-bit | `cryptography` Dart package | Encrypts the user's own health records for the optional account-based sync feature |

Standards references:

- **AES** — FIPS PUB 197; **GCM mode** — NIST SP 800-38D; AEAD usage per RFC 5116.
- **SHA-256** — FIPS PUB 180-4.
- **TLS** — IETF RFC 8446 / 5246, as provided by the operating system.

### Mechanism 3, in detail

This is the only mechanism implemented outside the operating system, and the
reason this documentation is required.

- **What it protects.** Records the user has created in the app — logged
  attacks, medications, medication reminders, and the in-app notification list.
  Nothing else is encrypted by the application.
- **When it operates.** Only if the user creates an account and enables the
  optional sync feature. The application is fully functional without an
  account, in which case mechanism 3 never executes.
- **Where it runs.** In the application's own code. The `cryptography` package
  resolves AES-256-GCM to a portable software implementation rather than
  calling CryptoKit or CommonCrypto, which is why this is a standard algorithm
  used *in addition to* the encryption within Apple's operating system.
- **Why AES-GCM.** It is authenticated encryption: a payload altered in transit
  or at rest fails to authenticate rather than decrypting to unintended data.

## 3. Key management

Encryption keys for mechanism 3 are 256-bit AES keys generated per user
account, held server-side, and delivered to an authenticated client over TLS.
The application does not derive keys from user passwords, does not implement
key exchange or key agreement, and does not perform key rotation.

The system is therefore **not** end-to-end encrypted: the service operator is
able to decrypt the stored records. This is stated plainly in the app's own
privacy policy and is repeated here so the documentation is not read as
describing a stronger guarantee than the product provides.

## 4. The encryption is ancillary and not user-accessible

- The application provides **no information-security capability to the user**.
  There is no user-facing encryption feature, no file or message encryption, no
  password manager, no VPN, and no secure-communications function.
- It **exposes no cryptographic interface** — no API, no SDK, no callable
  cryptographic service to other software.
- The cryptography exists solely to protect the user's own health records in
  the course of the app's primary function, which is personal health tracking.
- The application does not implement, and does not permit the user to select,
  substitute or supply, any cryptographic algorithm.

## 5. Distribution in France

The app is intended for distribution in France as part of general worldwide
App Store availability.

---

*Prepared for Apple's App Encryption Documentation request. The facts above
describe the application as implemented and are verifiable in the application's
source.*
