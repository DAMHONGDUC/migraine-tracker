# Tech stack — the parts with rules attached

The stack list is in `CLAUDE.md`. This is the detail behind the two entries
that carry real constraints.

## Weather is WeatherKit, and only Cloud Functions call it

Owner's call: one source for the whole app, no second provider anywhere.

- **The pressure-alert cron is included, and Open-Meteo goes with it.** Owner's
  rule, stated after a note in `docs/REMAINING_WORK.md` claimed the cron would
  stay on Open-Meteo permanently — that note was wrong.
  `functions/src/weather/openMeteo.ts` is replaced, not kept: two providers
  would let the alert that wakes a user at 3am disagree with the forecast shown
  at breakfast, which is the one inconsistency this feature cannot afford.
- **The app has no weather API of its own.** The private `.p8` signing
  WeatherKit's ES256 JWT must never ship in a binary, so the app asks the
  backend and the backend asks Apple. Everything still depends on the
  `WeatherRepository` interface, so the swap is a data source, not a rewrite.
- **Not yet built.** The code still calls the previous provider, and nothing can
  be tested until the WeatherKit key and Services ID exist (`PENDING_SETUP.md`).
- **Apple requires visible attribution** — the Weather trademark plus a link to
  Apple's legal page, wherever weather is shown. A shipping requirement.
- **Quota is 500k calls/month, and a proxy concentrates it.** Calls used to come
  from users' own devices; now every one lands on our key, so anything the app
  can reach must be rate-limited or one caller burns the month.
- **`getWeather` serves two shapes, and `full: true` is the whole difference.**
  Without it the callable answers the hourly series alone, which is all the
  pressure paths want. With it, `fetchWeatherBundle` asks Apple for
  `currentWeather,forecastHourly,forecastDaily` in **one** request and the
  callable returns `current` and `days` alongside `hours` — WeatherKit bills per
  call, not per dataset, so the whole weather card costs what the pressure-only
  fetch already cost. The two shapes cache under different keys (a `_full`
  suffix), so neither can be served the other's entry.
- **Every field below the top level is optional, on both sides of the wire.**
  Apple omits what it has no data for, so `WeatherReport` and its
  `WeatherConditions` / `WeatherHourly` / `WeatherDaily` are nullable throughout
  and the card draws what arrived. That is hard rule 4's "weather is
  best-effort" applied to a field, and why a missing reading is an absent row
  rather than a row reading "—".
- **`WeatherCondition` is a coarse enum, and an unknown code maps to null.**
  Apple has ~50 codes and distinguishes `Drizzle` from `Rain` from `HeavyRain`;
  a migraine tracker buys nothing with that precision but more strings to
  translate into seven locales. A code a build has never heard of degrades to
  "no glyph", never to a wrong one.
- **Token handling and backoff live in one `requestWeather`.** Both fetches go
  through it, because "a 401 resets the token before retrying" is exactly the
  rule that gets fixed in one copy and not the other.

## iOS builds on Swift Package Manager, not CocoaPods — except `health`

Every other plugin resolves as a Swift Package (`flutter_file_dialog` included;
Flutter adapts podspec-only plugins). **If an `ios/Podfile` reappears for any
other reason**, something added CocoaPods scaffolding this project does not
need: `pod deintegrate`, delete the `Podfile`, drop the `#include?` lines from
`ios/Flutter/{Debug,Release}.xcconfig`.

- **The reverse was tried and reverted — do not re-litigate without new facts.**
  The whole app was moved to CocoaPods (`flutter: config:
  enable-swift-package-manager: false`) to escape the `exact:` pin conflicts
  that break the Firebase plugin family whenever one of them bumps
  `firebase-ios-sdk`. Two things killed it: a cold build went from ~80s to
  ~390s, and — decisively — **Firebase is dropping CocoaPods**. Its own pod
  prints the notice: no new versions after **October 2026**, registry read-only
  from **December 2026**, SPM the recommended path
  (`firebase.google.com/docs/ios/cocoapods-deprecation`). Staying would have
  frozen the Firebase SDK at 12.17.0 with no security fixes, which is not a
  place a health app can sit.
- **So the pin conflicts stay a fact of life, and the fix is the known one:**
  bump every `firebase_*` plugin to the newest patch its existing caret allows
  so they all pin the same `firebase-ios-sdk`, then verify with `xcodebuild
  -resolvePackageDependencies`. **There are two `Package.resolved` files** —
  `ios/Runner.xcodeproj/…` and `ios/Runner.xcworkspace/…` — and Xcode reads the
  workspace one; fixing only the project copy leaves the mismatch one launch
  away from returning.
- **`health: ^3.0.6` is the exception: it pins an unmaintained `device_info`**
  (last published 2021, no SPM support and none coming). So `pod install` stays
  required for `health` + `device_info`, and `ios/Podfile` plus its `#include?`
  lines in `Debug`/`Release`/`Profile.xcconfig` are intentional, not leftovers.
  - **All three configs exist and each points at its own Pods xcconfig.**
    Flutter's template ships two and maps Profile onto `Release.xcconfig`, which
    makes `pod install` warn it never set the base configuration and leaves
    Profile builds on *release* pod settings.
  - The Podfile declares `platform :ios, '15.0'` to match
    `IPHONEOS_DEPLOYMENT_TARGET`; without it CocoaPods picks its own default and
    says so every run.
  - The build prints `"The following plugins do not support Swift Package
    Manager for ios: device_info, health"`. Expected and non-fatal.
  - **Do not "fix" that warning by bumping `health`.** Every version through
    13.3.1 caps `device_info_plus` below `win32 ^6`, which conflicts with
    `package_info_plus`/`share_plus`'s `win32 ^6.0.1` — and don't override
    `win32` to force it. Revisit if `health` widens to `device_info_plus
    ^13.0.0`+ or drops it.
  - If `ios/Podfile` is missing (a clean checkout), `pod install` fails at the
    post-install hook with `Flutter.xcframework must exist`. Run `flutter
    precache --ios` first.
