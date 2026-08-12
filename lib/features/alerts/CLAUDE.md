# Pressure alerts

Hard rule 7. The controls themselves live on Insights' pressure card.

7. Pressure math: alerts trigger on **delta** (default ≥5 hPa drop within 24h forecast), not absolute values. Threshold is user-tunable and stored per-user.
    - **The server never pushes to an anonymous session, and that is a chain, not a check.** Owner's rule. Premium requires an account (`PurchaseIdentity` binds a purchase only when `isSignedIn`, so an anonymous uid is never bound), pressure alerts require premium (the cron reads `users` where `premium == true`), so an anonymous user cannot reach the push path at all. Anything that pushes — the cron, `sendTestPush` — may assume an account, and anything that appears to serve an anonymous device with a notification is a bug.
      - **Registration refuses a signed-out or anonymous device outright.** It used to write a token for one and lean on `premium == false` to stop the cron targeting it, and it called `signInAnonymously` itself. Both are gone: `FirebaseAlertRegistrationRepository` throws `AlertRegistrationError.accountRequired`, and the alerts switch opens the paywall rather than toggling. Note this is about ALERTS only — the app still holds an anonymous session for weather (hard rule 1), so "has a uid" and "may register for alerts" are different questions.
