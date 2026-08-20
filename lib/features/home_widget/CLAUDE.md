# Home screen widget

Hard rule 18.

18. **The widget shows three things and one of them never changes: the log
    button, this week's count, the latest pressure.** iOS only, free for
    everyone — owner's call: it is a habit surface, not an insight, and gating
    the log shortcut would take something away from every user.

- **The extension is a real Xcode target, hand-written and checked in**:
  `ios/BaroEaseWidget/` plus a `BaroEaseWidgetExtension` target in
  `Runner.xcodeproj`, embedded into `Runner.app/PlugIns/`. Its
  `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` come from
  `Generated.xcconfig`'s `FLUTTER_BUILD_NAME` / `FLUTTER_BUILD_NUMBER`, so the
  app and the extension can never upload with different version numbers — App
  Store Connect rejects that. **Do not open `Generated.xcconfig` to check them**
  (hard rule 13).
- **The app pushes finished strings, not data.** The extension cannot reach the
  ARB files, and a label hardcoded in Swift would ignore the language the user
  picked (hard rule 6). So `HomeWidgetContent` carries already-worded text and
  SwiftUI only lays it out — the exact opposite of the notification list (hard
  rule 16), for the same underlying reason: strings get rendered wherever the
  locale is known. Which is why **a locale change republishes**, alongside
  launch, resume and every move of the attack list.
- **The keys in `HomeWidgetContent.toData()` are a contract with
  `BaroEaseWidgetEntry.swift`.** Renaming one means renaming it in both, and no
  test can catch the drift — two languages in two binaries.
- **The pressure reading is `DailyPressure`, not a fetch.** The recorder already
  writes one row per local day on launch and resume, so the widget costs no
  network; `_recordPressureThenRedraw` runs the two in that order, because
  racing them redraws with yesterday's row.
  - **It expires, and the extension does the expiring.**
    `HomeWidgetConstant.pressureMaxAge` (2 days from the reading's local
    midnight) is a Dart constant and stays one: the app computes the instant and
    ships it as `pressure_expires_at`, and the widget schedules a second timeline
    entry there that blanks the reading. Nothing republishes while the phone sits
    on a table, so without it a week-old number would sit on the home screen
    looking current — on a barometric app, the one number that must not lie.
- **The whole widget is one link to `/log`, through `NavigationUtils.toLog`** —
  the same gate and flow reset as the dashboard button. A second entry point
  skipping the free-plan check would be a wall the user could walk past.
- **The App Group is a copy of the user's data and the GDPR wipe clears it**
  (hard rule 8), last in `DataWipeService` so the redraw that follows cannot put
  the old numbers back. Turning the switch off empties it too, rather than
  freezing the last figures on the home screen.
- **Insets are asymmetric — 12 at the sides, 14 top and bottom — and a stat row
  puts its label and value on one line.** A small widget is ~155pt wide, so the
  16 it used to carry either side spent a fifth of that on air; stacking each
  label over its value then spent the height on two-line rows. Label left, value
  right also puts both readings on one edge, so they read as a pair. The value
  wins the squeeze (`layoutPriority`): a clipped label still names its row, a
  clipped number says nothing.
- **The switch defaults ON, because iOS will not let it be otherwise.** Owner's
  call, after off was tried and reversed. There is **no API for placing a widget
  on a home screen**, so adding it is the user's own explicit act and that act
  *is* the opt-in — nothing is published anywhere the user did not put it.
  Defaulting the feed off meant a widget the user had just added showing dashes,
  with the fix two taps deep in Settings.
- **The extension stays on the iOS 15 floor, and its side padding is worse on
  iOS 17 because of it.** Owner's call, asked and answered. iOS 17 adds ~16pt of
  content margin to every widget; `contentMarginsDisabled()` would remove it but
  is iOS 17+ and has **no conditional form** — it returns a different concrete
  type, `some WidgetConfiguration` admits only one, and `@WidgetBundleBuilder`
  rejects the `if #available` that would pick between two widgets ("Closure
  containing control flow statement cannot be used with result builder").
  Applying it means raising the deployment target and dropping the widget on 15
  and 16. So `widgetBackground` adds **no horizontal padding on 17+**, lets the
  system margin be all of it, and keeps its own below that — the `if #available`
  lives in the view, where `@ViewBuilder` allows one. **Do not re-propose the
  two-widget arrangement; it does not compile.**
- **`ios/BaroEaseWidget/BaroEaseWidgetPalette.swift` is the one sanctioned copy
  of `AppColors`.** A separate binary cannot read Dart, so the hexes are
  restated there and each names the field it mirrors. Nowhere else may do this.
- **Off iOS the Settings row is absent and every call is a no-op**
  (`HomeWidgetRepository.isSupported`). `taps` returns an empty stream rather
  than the plugin's `EventChannel`, so a widget test never opens a channel to a
  plugin that is not loaded.
- **The App Group id (`group.app.dd.migraine.tracker`) is written in three
  places and all three must agree**: `HomeWidgetConstant.appGroupId`,
  `ios/Runner/Runner.entitlements`,
  `ios/BaroEaseWidget/BaroEaseWidget.entitlements`. It also needs enabling on the
  App ID — see `docs/rules/PENDING_SETUP.md`.
