# Auth setup (Google / Apple)

The app code is complete; these are the console/Xcode steps it depends on.
Until they are done, tapping a sign-in button surfaces "Sign-in isn't set up
yet" (`AuthError.notConfigured`) instead of signing in.

> **Current state: both providers run the real flow.**
> `appleSignInImplementedProvider` (`lib/features/auth/providers.dart`) is
> `true` and `ios/Runner/Runner.entitlements` carries
> `com.apple.developer.applesignin`. What is left is console work only —
> step 4, which is now required rather than deferred.
>
> It used to be `false`: Apple's button showed and answered "coming soon".
> **Submission 1.0(11) was rejected under App Store 4.8 for that** — offering
> Google obliges us to offer Apple, and a "coming soon" button does not count
> as offering it. The provider stays as a kill switch (tests cover the state
> via `pumpApp(appleSignIn: false)`), so a broken console side becomes a
> sentence the user can read instead of a provider error. **Never ship it
> false** — such a build cannot be submitted.

## 1. Firebase console — enable the providers

Firebase console → Authentication → Sign-in method:

- **Google** — enable. This is what mints the `CLIENT_ID` /
  `REVERSED_CLIENT_ID` keys that `ios/Runner/GoogleService-Info.plist`
  currently does **not** have.
- **Apple** — enable. Needs the Services ID, Team ID, Key ID and the `.p8`
  private key from the Apple Developer portal, so do step 4 first. Until this
  provider exists the flow reaches Firebase and comes back
  `AuthError.notConfigured`, which reads as a bug in the app.
- **Anonymous** — must stay enabled: it is the default session (hard rule 1)
  and what `linkWithCredential` upgrades.

## 2. Re-download `GoogleService-Info.plist`

After enabling Google, download the file again and replace
`ios/Runner/GoogleService-Info.plist`. Verify it now contains `CLIENT_ID` and
`REVERSED_CLIENT_ID`:

```sh
grep -A1 "REVERSED_CLIENT_ID" ios/Runner/GoogleService-Info.plist
```

## 3. Info.plist — Google's callback URL scheme

`google_sign_in` needs the reversed client ID registered as a URL scheme.
Not added yet because the value does not exist until step 2. Add to
`ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
	<dict>
		<key>CFBundleTypeRole</key>
		<string>Editor</string>
		<key>CFBundleURLSchemes</key>
		<array>
			<string>com.googleusercontent.apps.XXXXXXXX-XXXXXXXX</string>
		</array>
	</dict>
</array>
```

…where the string is the `REVERSED_CLIENT_ID` value verbatim.

## 4. Apple Developer portal — Sign in with Apple capability (required)

`ios/Runner/Runner.entitlements` now declares
`com.apple.developer.applesignin = ["Default"]`, alongside the HealthKit and
push keys it already held, and it is wired into all three Runner build
configs. **The entitlement being in the repo is what makes the portal step
urgent, not optional**: an entitlement the App ID does not carry makes the
provisioning profile mismatch, and a device build fails with "Provisioning
profile doesn't include the com.apple.developer.applesignin entitlement" —
an error that names the entitlement rather than the missing portal step.
That is why it was left out until the flow was ready to ship.

Order matters:

1. **Enable the capability on the App ID.** Either the portal (Identifiers →
   the App ID behind `PRODUCT_BUNDLE_IDENTIFIER` → Sign in with Apple), or
   let Xcode do it: Runner target → Signing & Capabilities → + Capability →
   Sign in with Apple, which reconciles the checked-in entitlements file
   rather than replacing it.
2. **Create the Services ID, the Key ID and the `.p8`** — Certificates,
   Identifiers & Profiles → Keys, ticking Sign in with Apple. Downloadable
   once, like the APNs and WeatherKit keys, and a different key from both.
3. **Fill Firebase's Apple provider** with them (step 1 above).
4. **Re-run `fastlane certificates`** so the App Store profiles are minted
   carrying the new capability — existing profiles do not gain it. See the
   TestFlight section of `docs/rules/PENDING_SETUP.md`.

## Notes / known gaps

- **Simulator**: Google sign-in needs step 3 done. Sign in with Apple works
  on the simulator only when the simulator is signed into an Apple ID —
  a refusal there says nothing about the device.
- **Google button branding**: the button is label-only. Google's branding
  guidelines want the "G" mark; add it as an asset before submission.
- **Apple button styling**: rendered with the project's `AppButton` (filled,
  `Icons.apple`, "Sign in with Apple") rather than the plugin's
  `SignInWithAppleButton`, to stay inside the design system. Close to Apple's
  HIG but not pixel-identical — worth a look before review.
- **Orphaned alert registration**: signing out (or signing into an existing
  account, which abandons the anonymous UID) leaves the old `users/{uid}`
  document holding this device's FCM token. Harmless today because the alert
  cron only pushes to `premium == true` docs and nothing sets that flag yet;
  it must be cleaned up when RevenueCat lands.
