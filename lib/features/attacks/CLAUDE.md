# Attacks — the log flow

Hard rule 5 and the widgets that serve it.

5. **The 3-tap log flow is sacred**: intensity → head location → medication, then
   **one skippable exertion step**, then saved. The three taps are what must
   never grow — **any new REQUIRED field needs explicit approval**, and there is
   still only one optional step.

**Every step waits for Next — no step advances on the pick** (owner's call,
2026-09-16, reversing the 2026-09-14 call that had medication and exertion
commit on the tap). All three of location, medication and exertion call
`LogController.updateDraft`, which only arms the app bar's Next; `confirmStep`
is the one thing that moves the flow. The pick and the commit being two taps is
what lets a tile tapped by mistake be changed on the step it was made, instead
of only by backing out of the next one.

The three taps hard rule 5 protects are the *steps*, not the taps inside them:
the flow is still intensity → location → medication → exertion, and `saveNow`
still ends it from anywhere.

**`saveNow` is the way out, and it is not a fifth step.** A text button under
the content on every step after the first saves the attack with whatever has
been answered — two taps for the 9/10 attack, intensity then Save now. The rest
is editable on the detail screen, which is why this is not data loss.

- **An attack may carry NO area**, and `Attack`'s old `regions.isNotEmpty`
  assert is gone with this. Empty is an answer — "not recorded" — and
  `HeadRegionListLabel.label` says so in words wherever an area is printed, so
  no screen renders a blank value. The doctor report prints `-`, like every
  other unanswered cell.
- **`LogFlowState.startedAt` is how an attack that already passed gets logged.**
  The first step carries a button into `AttackStartSheet`; the label echoes the
  chosen instant back, because a time nobody sees again is a time nobody trusts.
  Null is the ordinary case and means "now", decided at save.

## Why exertion is in the flow, and how it cannot block

Exertion earned its place because it is the only insight the app asks the user to
supply by hand. Behind "Add details" it was fourth in a sheet nobody opened, so
`ExertionCorrelationEngine` counted almost nothing and its card sat at zero
forever.

- **It arrives on its answer**: `ExertionLevel.none` is a real value, not the
  absence of one, and the medication step likewise arrives on "No medication". So
  Next is armed on arrival at both, and location is the only step that waits for a
  pick.
- **A null exertion column means "never asked"**, which only attacks logged before
  the step existed carry. The detail screen renders those as "None" rather than
  inventing a fourth state.
- **`updateExertion` is a separate repository method**, because folding it into
  `updateDetails` let a save from `AttackDetailsSheet` blank an answer that sheet
  never displays. The attack detail screen edits it through `ExertionPickerSheet`.
- `LogFlowState.medicationName` exists because the save moved to the end of the
  exertion step: the medication pick has to survive one step longer than the
  `draft` slot it used to be read from. `back()` from exertion re-arms Next
  unconditionally, since "No medication" is a valid confirmed pick whose draft is
  null.
- `LogStepBar` draws four nodes now. It overflowed by 7px at the old padding, and
  because the bar renders on every step that broke every log-flow widget test at
  once — if it grows a fifth node, check the label `maxWidth` against the 393pt
  design width before anything else.

**Four more fields are recorded after the fact, and none is a step**:
`Attack.endedAt` (how long it lasted) and `Attack.medicationEffect` (whether the
medication helped). Both are answered from the detail screen, because at the
moment an attack is logged nobody knows how long it will run and the drug has not
had time to work — the questions could only be answered wrong there. Each has its
own repository method (`updateEndedAt`, `updateMedicationEffect`) for the same
reason `updateExertion` does. `endedAt` null means "still going, or never said" —
one state on purpose, since nothing can tell them apart — and
`medicationEffect` null means "never answered", which also covers every attack
where nothing was taken.

**`medicationTakenAt` and `reliefAt` are the third and fourth**, written
together by `updateMedicationTiming` — a relief time without the dose it
followed measures nothing, so neither may outlive the other. `timeToRelief` is
the gap between them, and it is measured from the DOSE rather than from the
attack: "how long did it take to work" is the question the medication is judged
on. `MedicationTimingSheet` asks in offsets, not clocks — nobody remembers
swallowing something at 09:20 and everybody remembers it was about half an hour
in — and both rows appear only where a medication was actually named, exactly as
the effect row does. The relief options stop at 4h because a triptan that has
not worked in four hours has not worked, and the app must not invite a guess
past that.

## The option grids

- **The log flow's option grids are two to a row.** `ExertionLevelPicker` and
  `MedicationGrid` both put two full-width-halves per row with
  `SdSpacingConstant.w8`/`h8` between them, so two adjacent steps read as one
  component; four exertion tiles across a row left every label a cramped two-line
  scrap. `LocationGrid` stays three-up — five tiles, one short word each.
- **Build them the way the existing two are built**: `GridView.builder` /
  `GridView.count`, `shrinkWrap: true`, `NeverScrollableScrollPhysics` — whatever
  holds the grid owns the scrolling. Uniform cells are also what keeps the
  *selected* tile, carrying 2px of border against everyone else's 1, exactly the
  size of the tile beside it. Hand-rolling the grid as a `Row` of `Expanded`
  reintroduces that, and such a row must then take
  `crossAxisAlignment: stretch`.
  - One unexplained failure, in case it returns: the exertion picker's first
    version used the bare `GridView(gridDelegate: …, children: [...])` constructor
    and **hung** `log_flow_test.dart` on a test it did not touch, rather than
    failing it. The same delegate through `GridView.builder` runs clean. Avoid the
    bare constructor here, not `GridView`.
  - A grid that hangs the suite looks like a slow machine, because `flutter test …
    | tail` buffers everything until the process exits. Redirect to a file when a
    run seems to stall.
- **An option outside a grid still takes the grid's cell size.**
  `AttackDurationSheet`'s "It just ended" is the same kind of answer as the ten in
  the grid below it, so it is the same kind of target — but outside the grid it
  gets no `mainAxisExtent` and shrank to its line of text, 22pt against 64.
  `AttackOptionTile.height` is the one owner and both read it — the tile left
  `AttackDurationSheet` when `AttackStartSheet` needed the same box, because two
  copies of one decoration is how two sheets on the same screen come to look
  like two different controls.
  `attack_duration_sheet_test.dart` compares the two heights, because a tile
  shrinking is invisible in a green run and obvious on a phone.

## The head diagram

**The pickable areas follow the drawing exactly** (owner's rule). Not
approximately, and not "close enough once it is clipped": a user who taps a cheek
and watches a strip of jaw light up stops trusting what the picker recorded, and
the record is the whole point of the step.

**The head is one solid the user turns, and the flat pair is the fallback.**
`HeadScene` renders `assets/models/head.glb` through `flutter_scene`;
`HeadDiagram` chooses, and falls back to the SVG pair whenever
`HeadSceneStore` comes back empty — Flutter GPU is a build flag and a device
capability, and a widget test has no GPU at all. **The fallback stays fully
pickable**, deliberately: see `docs/rules/DECISIONS.md`.

- **One mesh node per region, named `region_<enum name>`, and that is what
  keeps the rule above true in 3D.** `Scene.raycast` tests the very mesh it
  draws and hands back the `Node` that was hit, so what is filled and what is
  picked cannot drift — the same guarantee `HeadRegionGeometry` gives the flat
  diagram, by the same means. A model with a triangle-to-region side table
  would have been two owners again.
  - **The face is one `features` node with `raycastable` off.** The enum has no
    word for a brow or an ear, so a tap on one belongs to the region
    underneath. Ears are features for that reason and not regions — and without
    them the head reads as an egg in profile.
  - `head_model_test.dart` parses the shipped `.glb` and compares its node
    names with `HeadRegion.values` **in both directions**. The nose once
    shipped unpickable and was filed as missing rather than as broken; a name
    that drifts is that same failure, caught in CI instead.
- **The model is generated, not drawn**: `python3 tool/head_model.py` reads the
  cuts out of `head_region_geometry.dart` and revolves `_headPath`'s own
  outline, so the solid and the flat fallback come from one set of numbers. A
  hand-written width profile was tried first and produced a lemon. It writes a
  preview sheet next to it; look at that before shipping a shape change.
  - **The vertical cuts became constant longitudes**, not the drawing's
    straight vertical lines. On a flat view those are the same thing; on a head
    they are not, and a boundary that follows the side of the skull is the one
    a finger expects. It is the only place the 3D areas leave the drawing.
  - **No neck.** The flat back view draws one and the front does not; on one
    object that asymmetry has nowhere to live.
- **The camera frames the model's bounding sphere once and never moves.** A
  sphere is the same size from every angle, so the owner's rule that the head
  never moves is kept by construction rather than by watching for it.
- **L and R travel with the head, and face on the user's left is on the
  RIGHT.** The model is an ordinary head, not a mirror image, so meeting its
  face puts its left where a real person's is when you face them. The old flat
  front view was drawn mirrored to dodge exactly that, and one solid cannot be
  mirrored on one side and not the other. **This is measured, not reasoned**:
  `head_pose_test.dart` projects a point on the model's left through the very
  camera the widget uses — the first version of this rule was written backwards
  from a hand-derivation and the test is what caught it.
- **The tabs turn the head rather than cutting to it** — 380ms, the short way
  round, `HeadPose.shortestTurn`. They stay because they carry the per-side
  count and are the way in for anyone who does not drag. A drag turns it freely
  at `HeadPose.degreesPerPoint`, and takes the angle outright: an animation
  still running under a finger pulls the head out from under it.
- **The facing side is derived from the angle, never stored beside it**
  (`HeadPose.viewAt`, the quarter turn). A second copy of the angle is a second
  thing that can disagree with it, and `HeadRegionGrid` reads that one view.
- **iOS needs `FLTEnableFlutterGPU` in `Info.plist`, which `prepare-env` writes
  from `env_assets/<flavor>-Info.plist`** — putting it in the tracked file
  alone means the next environment switch erases it and the head silently falls
  back.

`HeadRegionGeometry` is the single owner that makes the FLAT path structural — the SVGs
carry line art only, and every fill, divider and hit test is built from the same
cuts, so the three cannot drift. The cuts are curves, not straight rules, because
the drawing's brow, cheek and jaw lines bow with the face; `HeadRegionGeometry._cut`
is the one curve they come from, a quadratic whose control x's are evenly spaced
*on purpose*, so `t = x / 200` exactly and a band can stop at the temple edge on
the same curve its neighbour continues on.

- **Order of work, owner's call: trace the reference app's diagram first, restyle
  it as ours after.** Getting the areas and the drawing to agree is the hard part
  and is independent of style, so the artwork is deliberately derivative *while
  that is being settled*. The areas must survive the restyle; the strokes need
  not. **Do not treat the current head as approved artwork.**
- **`nose` is one area, and the only one whose edge is a drawing rather than a
  cut** (owner's call, after reporting the nose as unpickable — it was never
  dead, it was filed as an eye or a cheek). `HeadRegionGeometry.nosePath` is a
  closed nose shape subtracted from `eyeL`, `eyeR`, `cheekL` and `cheekR`, so
  those four stop at its outline instead of running under it. A first pass split
  it at the under-eye line into a nose and a sinus; the owner merged them — nose
  and sinus are one place to somebody pointing at where it hurts. It joins no
  `HeadLocation`: the legacy coarse field has no word for the middle, and "left"
  would be a lie, so an attack naming only the nose degrades to `whole`.
  - **The SVGs do not stroke a nose.** Its outline is drawn by `HeadRegionPainter`
    in the divider colour, because it *is* a boundary and has to read as one; a
    white line-art nose beside it would be a second nose a millimetre away. The
    files keep three thin strokes inside it — nostrils, no outline (owner's rule).
  - `dividers` still runs the centre line and the under-eye cut straight at the
    nose and shortens neither. The painter clips the whole divider path to the
    face MINUS the nose, which erases exactly the stretches that would have
    crossed a single area — and keeps every nose special case out of the
    geometry's line list.
- The neck is part of the shape on the back view and not on the front, because
  `nape` is the only area drawn over it — `HeadRegionGeometry.outline` takes the
  view for that reason alone.
- **The design box is only as tall as the drawing needs, because the box's height
  is what sets the head's size.** The diagram is height bound everywhere it is
  used, so its width falls out of `designSize`'s ratio and every empty row is size
  the head does not get: trimming the box from 200x290 to 200x248 — the neck now
  runs off the bottom edge instead of ending inside it — drew the head 17% larger
  at the same widget height, without touching a curve. Reach for this before
  reaching for the layout when the head looks small.
- **The head is not the only way in: `HeadRegionGrid` names every area of the
  current view as a tile under it** (owner's rule). The bands carry no labels, so
  without the tiles "temple" and "eye" are told apart by where a finger lands
  rather than by a word, and the smallest areas are the hardest to hit. Both doors
  call the same `_toggle`, so a tile and its band light up together whichever was
  touched — a second door onto one answer, never a second answer.
- **The head never moves — not when the head is turned, not as the user picks**
  (owner's rule). It is the thing they are aiming at, and it sits in an `Expanded`,
  so anything below it that changes size hands the difference straight to the
  diagram. `HeadRegionGrid.reservedHeight` therefore sizes for the roomiest view
  (the front's eleven areas, three rows at four-up) so the back's four tiles leave
  empty rows rather than a taller head. `head_region_picker_test.dart` compares the
  diagram's `Rect` across the tab — identical, not merely close.
- **The head gets every point nothing else needs** (owner: bigger, three times).
  Things were given up in this order, the design box having already been trimmed:
  `LogFlowConstant.locationOptionsPerRow` went to **four** — against two everywhere
  else in the flow — turning eleven front areas from four rows into three; the line
  under the grid spelling the picked areas out was **deleted**, since the tiles
  name every area and light the picked ones up, taking `logLocationHint` out of all
  seven ARB files with it; then the padding, `LocationStep`'s 24pt above and below
  the picker going to none and the picker's own gaps from `h12`/`h24` to `h8`. That
  is 1.45x in the test harness and more on a real screen.
- **`HeadDiagram` wraps the switcher's child in `SizedBox.expand`, and that is
  load bearing.** `AnimatedSwitcher` lays its children out in a `Stack`, which
  hands them LOOSE constraints — and loose, a `CustomPaint` takes its child's size
  and an `SvgPicture` takes the asset's own 200x248. The drawing therefore rendered
  at 200x248 whatever box it was in, marooned in the middle of one twice that size,
  which is why three rounds of making the box bigger changed nothing the owner
  could see. **It also broke the taps**: `hitTest` maps the tap against the
  widget's size while the head was drawn to the asset's, so a finger on the visible
  cheek scored a different area. Never let this widget's child take loose
  constraints; `head_region_picker_test.dart` compares the `SvgPicture`'s rect to
  the diagram's.
- **One thin hand across the whole face: nothing above 0.9, every feature under
  0.4 opacity** (owner's rule, 2026-08-29, down from 1.4 at 0.62). The face is a
  hint, not a portrait: at the old weights the brows, eyes and mouth were nearly
  as heavy as the silhouette, and what the user is actually reading is the
  region fill painted underneath. The ears came down with them (1.1/0.85 at
  0.42–0.5) so they do not outweigh the features they frame — on both views,
  since the two files must stay drawn from the same numbers. The
  features are traced from the reference — arched brows tucked down at the outer
  end, a closed lid meeting its lash at a point in both corners, one continuous
  stroke down the bridge and round the nose with the wings set *inside* that curve
  (start them on it and the round caps pile up into a lump), a cupid's bow over a
  mouth line over a full lower lip — but all at the same weight as the hairlines
  inside the nose. This replaced a graded pass (2.5 brows down to 1.3 nostrils)
  that stopped working the moment the nose lost its outline to the painter: a 2.5
  brow beside a 1.3 nostril read as a different drawing pasted on. The silhouette
  at 2.0 is the only heavy line left, which is what makes it the silhouette —
  and the gap between it and the face is now the whole point, not a side effect.
- **The head is sized from its WIDTH, and sits 30pt in from everything around it**
  (owner's rule, after 40 and 24): the screen edge either side, the tabs above, the
  tiles below. The height falls out of the drawing's ratio; height only overrides
  it where a short column would otherwise overflow, and the `min` in the picker is
  that guard rather than a second opinion. An even ring of air is what stops a
  round thing in a column of rectangles reading as wedged between them. The tabs
  and tiles keep the step's usual 16pt gutter, because those two want the width and
  the head does not — which is why the horizontal padding lives on the three pieces
  rather than on `LocationStep`.
  - Sizing it this way also ended three rounds of "still too small": while the head
    took whatever height was left, it grew on a tall phone, stopped dead at its
    width on a wide one, and left the difference sitting between itself and the
    tiles. Now the leftover is knowable — it goes to the tiles up to
    `HeadRegionGrid.maxHeight`, and what remains is split above and below by the
    centred column, as margin rather than as a hole.
  - `_SideLabelled` puts L and R in that gutter, centred, costing the head nothing.
    Keep `child` a NON-positioned `Stack` child: `Positioned.fill` forces the box's
    ratio onto a 200x248 drawing and squashes the head sideways, which is worse
    than a small one. There is a test on the aspect for that reason.
- **The whole step renders on one screen and nothing scrolls** (owner's rule).
  `head_region_picker_test.dart` asserts it by walking every `Scrollable` and
  requiring `NeverScrollableScrollPhysics`, because an overflow here is invisible
  in a green run and shows up as a scroll on a real phone. `LocationPickerSheet`
  sizes itself from the screen with a ceiling for the same reason — a constant tall
  enough to seat eleven tiles on an 852pt phone is taller than a 667pt one has to
  give.

## The rest of the flow

- **The step's question is the app bar's title, not a headline in the body**
  (owner's rule). Every step used to spend its top twice — a bar reading "Log", a
  word the user already knew, and under it the one sentence that changes per step.
  The bar carries the question now and the body starts at the content; `LogScreen`
  falls back to `logTitle` on the saved step, which asks nothing. It is an
  `SdFittedTextV2` with `maxLines: 1`, because the bar has the back button on one
  side and Next on the other, so a long question must shrink rather than wrap.
- **`MedicationPickerSheet` puts the search field first in the list, not floating
  over it** (owner's rule). It is otherwise a copy of `MedicationStep` and now
  reads in the same order. The old version pinned it at the bottom in the shell's
  nav-pill slot with the tiles scrolling behind — over the answers it was meant to
  narrow, and the grid had to pad a hole for it. `SdSheetContentV2` scrolls its
  child under a pinned header, so being first in that child is the whole change.
  It also **fixed a ten-minute hang**: `attack_detail_test.dart`'s search test used
  to time out, and the `Positioned` bar reading `MediaQuery.viewInsetsOf` over a
  scroll view is the only thing that left the tree.

## The detail screen

- **Its rows put the value in the TITLE beside the label, both halves
  `Expanded`.** A `ListTile` lays `trailing` out at its intrinsic width first and
  tightens the title to what is left, so once `location` became a set of areas —
  "Right forehead, Back left, Back right" is one ordinary answer — a value in
  `trailing` squeezed "Location" into a column of single letters. Moving it into
  the title fixes that and reintroduces the opposite failure, a 7.5px overflow on a
  narrow tile, unless *both* sides carry a flex: a `Row` whose every text child is
  `Expanded` cannot overflow whatever either side is handed. `_EditableRow` and
  `_ReadOnlyRow` are the two shapes and must stay the same shape.
- **The weather section is the shared `WeatherCard`, the same widget the dashboard
  draws** (owner: "tôi muốn đồng nhất"). It was a list of `ListTile` rows here and
  a card there, so the reading a user checked one against the other was laid out
  two different ways. `_WeatherSection` builds a
  `WeatherCardData.ofSnapshot(attack.weather)` and hands it over; the card lives in
  `core/widgets/weather/` because two features draw it and neither may import the
  other's `presentation/`. Rules for the card itself:
  `lib/features/dashboard/CLAUDE.md`.
  - **What the snapshot never stored is simply absent**, not dashed — no condition
    code, so no headline glyph; no wind, UV or visibility, so no cells for them.
    What only it has, the 24-hour pressure change, is a cell like any other.
  - **It no longer marks a drop in red**: the old `_WeatherSection` bolded a delta
    at or below -5 hPa, and the shared card draws every reading the same way. Ask
    the owner before putting it back — a deliberate loss, not an oversight.
  - **The Apple Weather mark now reaches this screen too**, through the detail
    screen the card opens. The screen previously rendered WeatherKit data with no
    mark anywhere near it.
  - **"Weather at the time" names the sheet, not the card.** The card carries no
    heading (owner's call, see the dashboard's rules), so on this screen the
    reading is a temperature and three glyphs until it is opened. Deliberate.

## The step count on an attack

**An attack carries the day's step count, taken at the moment it was logged**
(owner's rule). `StepAttachService` runs unawaited beside `WeatherAttachService`
and for the same reason — hard rule 4, nothing in the log flow waits, and this one
asks another process. The attack is saved first, so a failure costs a number and
never a record.

- **The day SO FAR, not the whole day.** What belongs beside an attack is how much
  the person had moved *before* it; a total that keeps climbing afterwards answers
  a different question. The window is local midnight → the log, the same "reading
  taken at the time" shape as the weather snapshot.
- **No backfill, unlike weather.** A missing snapshot can be fetched later for the
  time it belonged to; this cannot — HealthKit would happily return the whole day's
  total instead, a different number filed under the same name. Better absent than
  wrong, which is also why `null` and `0` stay different answers all the way
  through the codec: null is a day Health would not talk about, zero is a day spent
  still.
- **It leaves the device**, inside the attack's encrypted payload. That is a
  privacy-label fact, not just a feature: `docs/privacy/` declares Fitness as
  collected and `NSHealthShareUsageDescription` says so too. Sleep still never
  leaves. Change this and all three change together.

## Aura, and the three states it needs

`Attack.aura` is `List<AuraType>?`, and **null and empty mean different
things**: null is "never asked", an empty list is the user answering "no
aura". Every other after-the-fact field on this entity collapses its two
absences into one — `endedAt` null is "still going, or never said" — and this
one deliberately does not.

- **Because they are different diagnoses.** Migraine with aura and migraine
  without aura are separate ICHD-3 entries, and the field reaches the doctor
  report. A recorded "no" is evidence; a question nobody put is not, and
  backfilling either would answer on the user's behalf.
- **Four kinds, not ICHD's six.** Visual, sensory, speech, motor. Retinal and
  brainstem aura both need a clinician to distinguish from the two above
  them, and offering them invites a self-diagnosis the app cannot support.
- **Not a step in the log flow** (hard rule 5), and it never can be: aura runs
  *before* the pain, so by the time an attack is logged it is already over.
  `updateAura` is its own repository method for the same reason
  `updateExertion` is — the details sheet never shows aura, so a save from
  there must not blank it.
- **The row sits above duration on the detail screen**, because the rows read
  in the order the attack happened.
- **`AuraPickerSheet`'s primary button says "No aura" while nothing is
  picked.** Saving an empty selection IS the "no aura" answer, so the button
  has to say which of the three states it is about to write; "Not recorded"
  is a separate text button and only appears once there is something to take
  back.
- **The sheet leads with one line explaining what an aura is.** The word means
  nothing to a good half of the people who get one.

## Sharing an attack as a picture

`AttackShareSheet` previews `AttackShareCard`, then captures **that very
boundary** and hands the PNG to the share sheet.

- **The preview is the mechanism, not a courtesy.** Capturing what is already
  on screen makes the preview and the file the same pixels by construction,
  so a card cannot carry anything the user was not shown.
- **The card never draws `notes`.** That is where the most private thing in
  the app gets written, and somebody who shared one six months ago will not
  remember that they did. The sheet says so under the preview.
- **Free, owner's call** — the acute use ("I'm down, text don't call") lands
  mid-attack, and that is the worst place in the app for a paywall.
- It reuses `ExportSharer` from `settings/` rather than a second `share_plus`
  call site, and writes through `AttackShareFileStore` into its own
  `attack_shares/` folder in temporary storage — never documents, which is
  where exports go because the export screen lists them again later.
- **The GDPR wipe clears that folder** (`DataWipeService`, step 11 of 11).
  The picture is a fourth copy of health data on the device; iOS reclaims
  temporary storage eventually, but eventually is not a deletion the user
  asked for. The folder is its own for exactly this: the wipe deletes the
  whole directory, and pointing that at the temp root would take plugin
  caches with it.
  - **Adding a step means moving `DataWipeService.steps` with it** — its own
    comment says so, and `data_wipe_service_test.dart` counts against that
    number.
  - The privacy policy names this file in two places (§7b and the
    "Delete your account" bullet), in `PRIVACY_POLICY.md` *and* `privacy.json`.
    Change what the wipe reaches and all four move together.
- `WidgetCaptureUtils` lives in `core/utils/` and NOT in any `domain/` —
  `domain/` is pure Dart by rule and cannot import `flutter/rendering.dart`.

## The attack that is happening now

**An attack with no end recorded, started inside `AttackProgressConstant.window`
(72h), is "running"** — `Attack.isRunningAt`. The window exists because the
`endedAt` column collapses "still going" and "never said" into one null, so time
is the only thing that can tell them apart; 72h is the top of the 4–72h band a
migraine is defined by, and past it a blank end is an unanswered question rather
than an attack in progress.

- **The dashboard card sits above everything, premium banner and log button
  included.** While it is true it is the only urgent thing on that screen. It
  carries the running clock, because a card that only said "an attack is
  running" would be telling the user what they already know.
- **`AttackNowScreen` is deliberately the emptiest screen in the app**: the
  clock, one line, and two full-width targets. The person reading it is in pain
  and photophobic (hard rule 3) — no cards, no readings, nothing to scroll past.
- **"I took medication" writes the dose TIME as well as the name.** Now is the
  only moment that time is known without guessing, which is the whole reason the
  question is asked here rather than on the detail screen.
- **It is offered only while nothing has been taken.** A second dose is a
  decision the app must not nudge, and medication-overuse is a warning this app
  already carries.
- **The ticker is `attackElapsedProvider`, `autoDispose` and family-keyed on the
  start time**, so it dies with the screen. A periodic timer outliving the tree
  is a leak a widget test reports as a hang rather than as a failure.
- **The Lock Screen card is a Live Activity, through the `live_activities`
  package** (owner's choice over hand-written ActivityKit).
  `AttackLiveActivity` is the interface, `PluginAttackLiveActivity` the iOS
  implementation, and everywhere else it is a no-op — the caller must not have
  to know which.
  - **The clock is `Text(timerInterval:)`, ticked by iOS.** Pushing an update a
    second would spend the activity's whole update budget on a number the
    system can count on its own, so the app writes the start instant once and
    never touches it again.
  - **Every word on the card is written by the app, already localized**, exactly
    as the home screen widget's are — the extension has no `AppLocalizations`.
    The controller resolves the locale through `LocaleUtils.resolve`, the way
    the reminders and the widget do, because there is no `BuildContext` there.
  - **The `ActivityAttributes` struct MUST be called
    `LiveActivitiesAppAttributes`.** The plugin looks it up by that name;
    rename it and the activity is created but never appears.
  - **The activity id is the attack's own id, kept in `SecureStore`.** The card
    outlives the process, so a relaunch has to be able to take down the one the
    last run started, and reusing the attack's id means a second start
    refreshes the card rather than stacking a second one.
  - **Three things take it down**: recording an end, deleting the attack, and
    the GDPR wipe (step 12 of 13) — a card for an attack that no longer exists
    is the one state it must never be left in.
