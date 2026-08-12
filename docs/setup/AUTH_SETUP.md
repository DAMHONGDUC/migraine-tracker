# Auth setup (Google / Apple)

The app code is complete; these are the console/Xcode steps it depends on.
Until they are done, tapping a sign-in button surfaces "Sign-in isn't set up
yet" (`AuthError.notConfigured`) instead of signing in.

> **Current state: Google works, Apple is on screen but not wired up.**
> Both buttons show, so the login screen is laid out in its final shape;
> tapping Apple answers "coming soon" instead of starting a flow that can
> only fail. The switch is `appleSignInImplementedProvider`
> (`lib/features/auth/providers.dart`), and the real Apple path stays
> covered by tests via `pumpApp(appleSignIn: true)`.
>
> **This cannot ship as-is.** Offering Google sign-in makes Sign in with
> Apple mandatory (App Store 4.8), and a button that answers "coming soon"
> does not count as offering it. Do step 4, flip that provider to `true`.

## 1. Firebase console — enable the providers

Firebase console → Authentication → Sign-in method:

- **Google** — enable. This is what mints the `CLIENT_ID` /
  `REVERSED_CLIENT_ID` keys that `ios/Runner/GoogleService-Info.plist`
  currently does **not** have.
- **Apple** — deferred (see the note at the top). When you come back to it:
  needs the Services ID, Team ID, Key ID and the `.p8` private key from the
  Apple Developer portal.
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

## 4. Apple Developer portal — Sign in with Apple capability (deferred)

Not needed until Apple sign-in is switched back on.

The entitlements file and its `CODE_SIGN_ENTITLEMENTS` build settings were
deliberately **removed** again: an entitlement the App ID does not carry
makes the provisioning profile mismatch, and device builds then fail with
"Provisioning profile doesn't include the com.apple.developer.applesignin
entitlement". Declaring it early costs a broken build for no benefit.

To restore, let Xcode do both halves at once: Runner target → Signing &
Capabilities → + Capability → Sign in with Apple. That re-creates
`ios/Runner/Runner.entitlements`, wires `CODE_SIGN_ENTITLEMENTS`, and
enables the capability on the App ID (`flyd.migraine.tracker`). Then flip
`appleSignInImplementedProvider` to `true`.

## Notes / known gaps

- **Simulator**: Google sign-in needs step 3 done. Sign in with Apple, once
  switched back on, works on the simulator only when the simulator is signed
  into an Apple ID.
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
