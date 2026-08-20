# Notifications

Hard rule 16.

16. **The notification list syncs, and every device must show the same list.**
    Owner's call, and it shapes the whole feature. `AppNotifications` is a fourth
    `SyncCollection`, last in the order because a notification points at the
    reminder and medication it came from.

## Read state

- **Read state is per notification, and only opening its detail reads it.**
  Opening the list reads nothing: looking at a list is not reading its items, so
  the dot on a row means what it says and the bell's count comes down one at a
  time.
- **`markRead` is a no-op on a row already read** — re-entering a detail would
  otherwise bump its revision and push a row saying what the server already has.
- **Writes are insert-if-absent, never insert-or-replace** (`addMissing`). The
  materialiser re-derives the same occurrences on every run; replacing would wipe
  `readAt` each time and the unread badge would come back on every launch.

## Counts and colour

- **The bell's badge is `colorScheme.error`, not the accent.** A notification
  count is the one badge people already read as "unattended", and lavender is
  what every non-urgent highlight wears. It is also the one place a count chip
  may be red: the tab counts stay accent-tinted, because they say how much is
  there, not that something is owed.
- **The row's dot is `colorScheme.error` like the bell's badge**, and so is the
  list app bar's count — the three mark the same thing and must not read as
  three different things.
- **The bell carries a number, not a dot** — its count is how many are unread,
  which is what decides whether the user opens the list now or later.
- **The tab counts are how many of that type there ARE, not how many are
  unread**: the list is a history, and its tabs say how much of each kind it
  holds. They are **plain text, never a tinted chip** — a filled pill beside a
  label competes with the label for the same glance. A row keeps a plain dot,
  since per row there is only ever one. `SdBadgeV2` does all three: `count: null`
  draws the dot, a number draws the number, 0 draws nothing.
- **Count chips cap at `SdBadgeV2.maxCount`** — one number for how high a count
  chip counts anywhere in the system, `SdSegmentedTabsV2` included (uncapped, a
  four-figure count pushed its own tab label out of the segment). **Anything
  stating that number calls `SdBadgeV2.formatCount`**: the Settings row spelled
  its own `'$unread'` and so said "132" where the bell it mirrors said "99+".
- **The list's app bar carries the unread count in full, uncapped**, at the end
  of the trailing slot, absent at zero. Plain text rather than a chip — the bell
  stays the one place a count wears a filled pill — and uncapped because nothing
  needs protecting: a badge caps so it does not grow over the icon under it, and
  this has a bar to itself. The bare digits say nothing to a screen reader, so
  `notificationsA11yUnread` is its `Semantics` label and the text itself is
  `ExcludeSemantics`'d.
- **Two ways in, and they say the same thing.** The dashboard's bell is the fast
  one; `NotificationsSettingsTile` (`core/widgets/sections/`) is the one people
  find by looking. The Settings row's value is the same unread count, and is
  **absent** rather than "0" when nothing is unread — a row stating zero is noise.

## The list

- **Two tabs — reminders and pressure — and not one mixed list**, because a
  reminder arriving every day would bury the alerts entirely, and the two answer
  different questions. `SdSegmentedTabsV2` is the control, not Material's
  `TabBar`, which is an underline and a page-swipe and reads as Android on an
  iOS-first app.
- **The tab track is Liquid Glass**, like the shell's nav pill and History's view
  toggle. That widens the chrome rule slightly — a control inside a screen, not
  at its edge — and is deliberate: the track sits directly under the frosted app
  bar, and an opaque pill there reads as a second, lower bar.
- **Every row opens `NotificationDetailScreen`, whatever its type.** The type
  decides what the detail *offers* — a reminder gets a button through to its
  medication, an alert gets the reading and a way to the pressure card — never
  whether the user gets a screen at all. One tap, one stop, so the list is
  uniform to use. A reminder whose medication has since been deleted keeps the
  button,
  disabled: one that vanished would read as a bug.

## Sound

**A notification always makes a sound, and there is no switch for it.** Owner's
call, after one was built and taken back out: the app schedules reminders that
exist to be noticed, and the OS already owns this — Settings › Notifications ›
BaroEase, plus the ring switch and Focus. A second, app-level mute is one more
place for the two answers to disagree. So `NotificationScheduler.schedule`
carries no `sound` flag and iOS gets `presentSound: true` unconditionally.

**What actually silences a push is a missing setting, not a switch**:
`setForegroundNotificationPresentationOptions` in `AppBootstrap`, without which
iOS drops a push arriving while the app is open — no banner and no sound. A
pressure alert's sound is the payload's own (`aps.sound` in
`functions/src/index.ts`) and was never the client's to choose.

## The rows themselves

- **Ids are derived, never minted**: `rem:<reminderId>:<epochMinute>` and
  `pa:<eventId>` (`AppNotification.reminderOccurrenceId` / `.pressureAlertId`).
  Two devices computing the same reminder occurrence arrive at the same id
  without agreeing first, so **every writer is idempotent** — the materialiser,
  the foreground push, the background push and the launch reconcile can all write
  the same row and none can duplicate or fight. It is also what makes the reminder
  half of the list identical across devices almost for free.
- **No title or body is stored.** The row carries the facts — which medication,
  how far pressure fell — and the strings render from ARB at display time, so
  changing language changes the list (hard rule 6). A stored string would freeze
  whichever locale happened to be active, and the alert's own push text arrives
  from the server in English regardless.
- **The type field is `NotificationType`/`type`, not `kind`** — in the enum, the
  Drift column, the payload and the push's `data`. `ExportRecords.kind` is a
  different feature and keeps its own name.
- **`medicationId` and `reminderId` carry no foreign key**, unlike
  `MedicationReminders.medicationId`: deleting a medication cascades its reminders
  away, and the history of having been reminded must survive that. The detail
  screen already handles a medication that is gone.
- **`MedicationReminders.createdAt` exists for this and syncs.** The list
  materialises past occurrences over a window, and without a lower bound it
  invents months of "you were reminded" for a reminder created yesterday. Every
  device has to agree where that history starts, so it travels in the payload.
  Rows predating v8 get null = "unknown", bounded by the window alone — the same
  call as `Medications.createdAt` in v3: stamping the migration's clock would
  invent the very history the column exists to fence off.
- A pull that brings reminders down already reschedules them
  (`RemindersController.rescheduleAll`, hard rule 12), so "a reminder that arrives
  by sync sets itself up" is not new work.

## Push

- **The pressure-alert push carries `data` and `content-available: 1`**
  (`functions/src/index.ts`). The `notification` block stays for the banner, but
  its text is English whatever language the user picked — so only `eventId`,
  `dropHpa` and `at` travel, and the list renders its own strings from ARB.
  `PressureAlertMapper` is the pure half of that, and where the message's meaning
  is tested without a device or a token. **Needs `firebase deploy --only
  functions` to take effect.**
- **`sendTestPush` is the only way to prove push works, and it can only ever push
  to the caller.** A dev-only Settings row calls it; the callable reads
  `request.auth.uid`'s own `fcmToken` and **takes no uid and no token as an
  argument**, so the worst anyone can do with it is notify themselves. That is its
  whole security model, and it has to be: `env/dev.json` and `env/prod.json` share
  one Firebase project, so there is no dev project to hide it in.
  - **Anonymous callers are refused**, like `getSyncKey` and `deleteAccount`.
    Testing push as an anonymous session would prove a path production does not
    have.
  - Its payload mirrors a real alert — same `data` keys, same
    `content-available` — so a pass exercises the cron's path rather than a
    simpler one. `eventId` is stamped `test:` so the idempotent writers cannot
    mistake it for a real event.
- **An alert arriving while the app is shut is caught up by the launch reconcile,
  not by a background handler.** `FirebaseMessaging.onMessage` writes the row
  while the app is open; `NotificationsController.reconcileLastAlert` covers the
  rest, reading `lastAlertAt` / `lastAlertEventId` / `lastAlertDropHpa` off
  `users/{uid}` on launch and resume. `PressureAlertMapper.fromRecord` builds the
  row and `fromData` funnels into it, so the push and the reconcile cannot derive
  different ids for one event.
  - **`users/{uid}` holds only the LATEST alert, so this catches up one alert,
    not a backlog.** Enough while the cron sends at most one push per user per
    24h. A background isolate handler — its own Drift connection, a
    `@pragma('vm:entry-point')` static, not a top-level function — is what would
    close that, and is not built.
  - **It never rethrows**, unlike every other controller method here: it runs
    unawaited at launch, where a throw would take app start with it.
  - **`lastAlertDropHpa` is written for the client, not for dedupe** —
    `recordAlert` takes the whole `DropForecast` for it, because a reconciled row
    without the reading cannot say how far pressure fell. Records written before
    this exist without it, and `fromRecord` yields a row anyway.
  - **`pumpApp` must override `lastAlertRepositoryProvider`**
    (`FakeLastAlertRepository`, `test/helpers/notification_fakes.dart`) — the
    reconcile is a Firestore read fired from the app root, same trap as the sync
    fakes.
- **Pressure alerts cannot fire on every device yet**: `users/{uid}` holds ONE
  `fcmToken`, so the last device to register is the only one that gets the push.
  The row syncs afterwards, so the *list* converges — only the banner is
  single-device. Fixing it means tokens as a collection plus fan-out in the cron,
  and is not in scope.

## Shipping this

- **Deploy is part of it**: `firebase deploy --only firestore:rules` AND `--only
  firestore:indexes`, **to prod**. `sync_collection_rules_test.dart` proves the
  files agree with the enum; it can never prove the project has them.
- **The 12h sync throttle the owner asked about is deliberately NOT built**
  (owner: skip it for now). It conflicted with hard rule 12's
  push-after-logging-an-attack, which exists so a freshly logged attack is not
  lost with the phone. If it comes back, throttle the full pull+push pass and
  leave that push path immediate.
