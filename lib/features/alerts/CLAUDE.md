# Pressure alerts

Hard rule 7. The controls themselves live on Insights' pressure card.

7. **Pressure math triggers on delta**, not absolute values: by default a ≥5 hPa
   drop within the 24h forecast. The threshold is user-tunable and stored
   per-user.

- **The server never pushes to an anonymous session, and that is a chain, not a
  check.** Owner's rule. Premium requires an account (`PurchaseIdentity` binds a
  purchase only when `isSignedIn`), and alerts require premium (the cron reads
  `users` where `premium == true`, plus the `PREMIUM_EMAIL` account below, which
  only Google or Apple sign-in can produce), so an anonymous user cannot reach
  the push path at all. Anything that pushes — the cron, `sendTestPush` — may
  assume an account, and anything that appears to serve an anonymous device a
  notification is a bug.
- **The cron targets the build's `PREMIUM_EMAIL` account as well.** `premium` is
  written only by the RevenueCat webhook, so that account never carries it — and
  a reviewer the build grants premium would pass every gate in the app and still
  never get an alert, which is the one surface disagreeing with the rest.
  `pressureAlertJob` runs a second query on `users.email` and dedupes by uid.
  - The address comes from `PREMIUM_EMAIL` in `functions/.env`, the same name
    the app build uses. Unset, the second query is never issued.
  - Both spellings are asked for (`premiumEmailMatches` in
    `core/premiumAccount.ts`): Firestore `==` is case-sensitive, the app's match
    is not.
- **Registration refuses a signed-out or anonymous device outright.** It used to
  write a token for one and lean on `premium == false` to stop the cron
  targeting it, and it called `signInAnonymously` itself. Both are gone:
  `FirebaseAlertRegistrationRepository` throws
  `AlertRegistrationError.accountRequired`, and the switch opens the paywall
  rather than toggling.
  - This is about **alerts only**. The app still holds an anonymous session for
    weather (hard rule 1), so "has a uid" and "may register for alerts" are
    different questions.
