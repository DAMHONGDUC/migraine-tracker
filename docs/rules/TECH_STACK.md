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

## iOS builds on Swift Package Manager. There is no CocoaPods

Every plugin resolves as a Swift Package — `flutter_file_dialog` included,
because Flutter adapts podspec-only plugins. `ios/Podfile`, `Podfile.lock` and
the `Pods` project are **deleted**, and the `#include?` lines are gone from all
three `ios/Flutter/*.xcconfig`. **If any of them reappears**, something added
scaffolding this project does not need: `pod deintegrate`, delete the files
again, drop the includes.

- **Proven by a build, not by inference** (2026-09-04, `flutter build ios
  --no-codesign --debug`, exit 0, no Podfile in the tree). The step before it
  was the `health` 13 upgrade, after which `Podfile.lock` held **Flutter and
  nothing else** — the last pod was Flutter's own, which the SPM integration
  supplies anyway.
- **What went with it**: the `cocoapods` gem in `ios/Gemfile`, the *Pods* step
  in `.github/workflows/release-ios.yml`, the `pod install` block in
  `tool/set-up.sh`, and `ios/Pods` from `tool/_clean.sh`. The Ruby pin and the
  UTF-8 `LANG` stay — fastlane is Ruby and reads `pubspec.yaml`.
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
- **`health` is at `^13.3.1`, and the pin that blocked it is gone.** The bump
  was made for menstrual-cycle data — `health 3.0.6` has no `MENSTRUATION_FLOW`
  type at all — and it is what removed the last podspec-only plugins:
  `health 13.3.2` resolves `device_info_plus 13.2.0` on `win32 6.3.0` beside
  `share_plus 13.2.0` and `package_info_plus 10.2.1`, and both ship a
  `Package.swift`.
  - **The API changed with it**: `HealthFactory()` → `Health()`, and
    `getHealthDataFromTypes` takes named `types`/`startTime`/`endTime`. A step
    sample's value is a typed `NumericHealthValue` now, not a bare number.
- **`Runner.xcworkspace` stays, holding `Runner.xcodeproj` alone.** Flutter
  builds the workspace when one exists, and Xcode reads its `Package.resolved`
  — deleting it would move SPM resolution to the project copy and lose the
  scheme settings with it.
