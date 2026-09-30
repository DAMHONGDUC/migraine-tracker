# Auth setup (Google / Apple)

The app code is complete; these are the console and Xcode steps it depends on.
Until they are done, a sign-in button surfaces "Sign-in isn't set up yet"
(`AuthError.notConfigured`).

> **Both providers run the real flow.** `appleSignInImplementedProvider`
> (`lib/features/auth/providers.dart`) is `true` and `Runner.entitlements`
> carries `com.apple.developer.applesignin`. What is left is console work —
> step 4, now required rather than deferred.
>
> It used to be `false`, with Apple's button answering "coming soon".
> **Submission 1.0(11) was rejected under App Store 4.8 for that**: offering
> Google obliges us to offer Apple, and "coming soon" does not count. The
> provider stays as a kill switch (tests cover it via
> `pumpApp(appleSignIn: false)`), so a broken console side becomes a sentence
> the user can read instead of a provider error. **Never ship it false** — such
> a build cannot be submitted.

## 1. Firebase console — enable the providers

Authentication → Sign-in method:

- **Google** — this is what mints the `CLIENT_ID` / `REVERSED_CLIENT_ID` keys
  that `ios/Runner/GoogleService-Info.plist` currently does **not** have.
- **Apple** — needs the Services ID, Team ID, Key ID and `.p8` from step 4, so
  do that first. Until this provider exists the flow reaches Firebase and comes
  back `AuthError.notConfigured`, which reads as an app bug.
- **Anonymous** — must stay enabled: it is the default session (hard rule 1) and
  what `linkWithCredential` upgrades.

## 2. Re-download `GoogleService-Info.plist`

After enabling Google, download it again and replace
`ios/Runner/GoogleService-Info.plist`. Verify it now carries the two keys:

```sh
grep -A1 "REVERSED_CLIENT_ID" ios/Runner/GoogleService-Info.plist
```

## 3. Info.plist — Google's callback URL scheme

`google_sign_in` needs the reversed client ID registered as a URL scheme. Not
added yet because the value does not exist until step 2. In
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

**Edit `env_assets/<env>-Info.plist`, not the file in the tree.** Each Firebase
project mints its own reversed client id, so `packages/script-tools/flutter/prepare_env.sh dev|prod`
installs `ios/Runner/Info.plist` alongside `GoogleService-Info.plist` and
overwrites whatever was there — a scheme typed straight into the tree survives
until the next environment switch and then vanishes, with the sign-in callback
going quiet and nothing pointing at this file.

## 4. Apple Developer portal — Sign in with Apple (required)

`Runner.entitlements` declares `com.apple.developer.applesignin = ["Default"]`
alongside the HealthKit and push keys, wired into all three Runner build configs.
**The entitlement being in the repo is what makes the portal step urgent**: an
entitlement the App ID does not carry makes the profile mismatch, and a device
build fails with an error naming the entitlement rather than the missing portal
step. That is why it was left out until the flow was ready to ship.

Order matters:

1. **Enable the capability on the App ID** — the portal (Identifiers → the App ID
   behind `PRODUCT_BUNDLE_IDENTIFIER`), or Xcode's Signing & Capabilities → +
   Capability, which reconciles the checked-in entitlements file rather than
   replacing it.
2. **Create the Services ID, Key ID and `.p8`** — Keys, ticking Sign in with
   Apple. Downloadable once, and a different key from the APNs and WeatherKit
   ones.
3. **Fill Firebase's Apple provider** with them (step 1).
4. **Re-run `fastlane certificates`** so the App Store profiles are minted
   carrying the new capability — existing profiles do not gain it. See
   `docs/rules/PENDING_SETUP.md`.

## Known gaps

- **Simulator**: Google sign-in needs step 3 done. Sign in with Apple works there
  only when the simulator is signed into an Apple ID — a refusal says nothing
  about the device.
- **Google button branding**: label-only today. Google's guidelines want the "G"
  mark; add the asset before submission.
- **Apple button styling**: drawn with `SdButtonV2` (filled, `Icons.apple`) rather than the plugin's `SignInWithAppleButton`, to stay inside
  the design system. Close to Apple's HIG but not pixel-identical — worth a look
  before review.
- **Orphaned alert registration**: signing out, or signing into an existing
  account (which abandons the anonymous UID), leaves the old `users/{uid}` doc
  holding this device's FCM token. Harmless while the cron only pushes to
  `premium == true` docs and nothing sets that flag — clean it up when RevenueCat
  lands.
