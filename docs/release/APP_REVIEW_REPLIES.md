# App Review replies — submission 1.0 (11)

Drafts for App Store Connect → Resolution Center, one per guideline in the
rejection of 2026-08-13 (submission `f4966c43-ec16-49ec-b89f-5a854d59a308`,
reviewed on iPad Air 11-inch (M3), iPadOS 26.6).

**Send them as one message, in this order**, with the guideline number
heading each part — that is how the rejection arrived, and a reply that
answers a different set of items than the one raised gets read as evasive.

**Do not send any of it before the console work behind it is actually done.**
Four of the five replies claim a state the repo cannot produce on its own; the
register of what is outstanding is `docs/rules/PENDING_SETUP.md`. A reply
saying "this is fixed" that a reviewer can disprove in one tap costs another
full review cycle and, on the paywall item, is what turns a 2.1 into a pattern.

---

## 5.1.2(i) — App Tracking Transparency

Send only after the App Privacy answers are corrected in App Store Connect.

> BaroEase does not track users, on any platform.
>
> We do not collect the IDFA, we use no advertising or attribution SDKs, and
> we do not share any data with data brokers or join it with data from other
> companies' apps or websites. The only third-party SDKs in the app are
> Firebase Crashlytics, Firebase Analytics and Firebase Cloud Messaging, all
> used solely for our own crash reporting, in-app usage measurement and the
> barometric-pressure alert notifications the app exists to send.
>
> The "Used to Track You" answers on Crash Data, Health and Fitness were our
> error in filling out the App Privacy questionnaire. We have corrected them:
> those categories remain declared as collected, and none of them is marked
> as used for tracking.
>
> Because the app performs no tracking, it does not present the App Tracking
> Transparency permission request — asking permission to track when we do not
> track would itself be misleading to the user.
>
> We have also renamed the Settings section previously headed "Tracking" to
> "Monitoring", so that nothing in the interface can be read as referring to
> cross-app tracking. That section covers only the barometric pressure,
> activity and sleep readings the app watches on the user's own behalf.

## 2.3.8 — App icon and launch screen

Send only once the real icon is in the build.

> This build ships the final BaroEase app icon and launch screen. The
> placeholder artwork from the development template that appeared in build 11
> has been replaced throughout — the App Store 1024×1024 icon, every device
> icon size, and the launch screen.

## 4.8 — Login Services

Send only once the capability is on the App ID and the Apple provider is
enabled in Firebase, and only after signing in with Apple has been tested on
a real device.

> Sign in with Apple is now fully implemented and is offered alongside Google.
>
> Where to find it: BaroEase is usable without an account, so the sign-in
> screen is reached from **Settings → Sign in** (it is also offered from the
> subscription screen). On that screen, **Sign in with Apple is the first and
> most prominent button**, above Sign in with Google.
>
> It meets the requirements of 4.8: it limits data collection to the user's
> name and email address, Apple's Hide My Email is supported so the user may
> keep their email private, and no advertising data is collected or shared
> without consent — we collect none at all.
>
> In build 11 the button was present but not yet connected to a working flow.
> That was our mistake and it is corrected in this build.

## 2.1 — Information Needed (in-app purchases)

Send only after a sandbox purchase has succeeded on a real device.

> Thank you for flagging this — the subscription screen was showing "No plans
> are available" because our in-app purchase products were not yet fully
> configured and attached to the build, so the app received an empty list of
> products from the App Store.
>
> This is now resolved. Both products — Monthly ($4.99) and Yearly ($29.99) —
> are configured, in Ready to Submit status, and submitted with this build. We
> have verified the full purchase and restore flow in the sandbox environment
> on a physical device, and the subscription screen now lists both plans with
> their prices.
>
> To reach it: **Settings → the premium banner at the top of the screen**, or
> any premium feature — for example the "Analysis" section of Settings →
> Monitoring → Sleep.

## 2.5.1 — HealthKit disclosure

This one needs a screen recording attached. HealthKit does not exist in the
Simulator, so record it on a physical device.

> BaroEase now identifies Apple Health directly in its interface.
>
> Settings has a dedicated **"Apple Health"** section, listing the two data
> types we read — **Sleep** and **Steps** — each with its own switch, above a
> line stating that the app reads them to look for patterns with the user's
> migraine attacks, that access is read-only, that sleep never leaves the
> device, and that the step count for the day of an attack is saved with that
> attack. The same switches also appear on the Sleep and Activity screens,
> next to the readings they produce.
>
> In build 11 these switches existed but were reachable only through rows
> labelled "Sleep" and "Activity", which did not name Apple Health, and the
> Sleep row additionally sat behind our subscription screen — which, due to
> the in-app purchase configuration issue in 2.1 above, could not be
> completed. We have removed that restriction: connecting Apple Health and
> viewing your own sleep and step data are free features and require no
> subscription.
>
> BaroEase reads sleep and step data only. It does not write to HealthKit and
> it never uses the data for advertising or marketing, nor shares it with any
> third party.
>
> One transmission exists and we want to be explicit about it. When the user
> logs a migraine attack, the app records the number of steps they had taken
> that day and stores it as a field of that attack, because how active
> someone was before an attack is part of the record their doctor reads. If —
> and only if — the user has signed in and turned on our cross-device sync,
> that attack, step count included, is uploaded to our own Firebase backend as
> an encrypted payload, to be restored on their other devices. It goes nowhere
> else. Sleep data is never transmitted anywhere under any circumstances, and
> a user who never signs in transmits nothing at all: the app is fully usable
> without an account. This is stated in the Apple Health line in Settings, in
> the `NSHealthShareUsageDescription` permission string, and in §5 of our
> privacy policy.
>
> A screen recording from a physical device showing the path from launch to
> the Apple Health section, and the permission sheet, is attached.

---

## Before any of this is sent

- [ ] App Privacy: "Used to Track You" unticked on Crash Data, Health,
      Fitness (Account Holder or Admin only)
- [ ] Final 1024×1024 icon in the build, no alpha, no rounded corners
- [ ] Sign in with Apple: capability on the App ID, Apple provider in
      Firebase, profiles re-minted, flow tested on a device
- [ ] Three IAPs Ready to Submit and attached to the build; RevenueCat
      offering marked Current under entitlement `premium`; a sandbox purchase
      completed on a device
- [ ] Screen recording of the Apple Health path, from a physical device
- [ ] App Privacy: **Fitness** declared as collected and linked — the step
      count leaves the device with a synced attack, so declaring it
      collected-but-not-linked would contradict the 2.5.1 reply
- [ ] A demo account is not needed — the app is fully usable signed out —
      but say so in the review notes rather than leaving the field empty
