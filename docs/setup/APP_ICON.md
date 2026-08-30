# App icon and launch screen

How the icon is made, how the set is regenerated from it, and the traps that
bite every time.

Submission 1.0(11) was rejected under **App Store 2.3.8** for shipping the
default Flutter logo at every size. Closed — this file exists so it cannot
reopen quietly.

## The source of truth

One file: **`assets/images/final_app_icon.png`**, 1024×1024, named in the
`flutter_launcher_icons:` block of `pubspec.yaml`. Everything else — 21 iOS
entries, 5 Android mipmaps — is generated from it and must never be edited by
hand. The `app_icon_v*.png` beside it are the raw generated candidates the
watermark stripper reads; nothing builds from those.

| Constraint | Why |
|---|---|
| Exactly 1024×1024 | App Store Connect requires it for the marketing icon |
| No rounded corners | iOS applies its own mask; baked corners show as a double round |
| Full bleed, no transparent margin | The mask needs artwork to the edge |
| No pure white | Hard rule — the users are photophobic |

An **alpha channel in the source is tolerated**, because the generator flattens
it. Nothing else here is negotiable.

## Regenerating the set

```sh
dart run packages/system_design/tool/strip_icon_marker.dart assets/images/app_icon_v5.png assets/images/final_app_icon.png
dart run flutter_launcher_icons
```

**The generated files are committed on purpose.** A fresh clone that builds
without running the tool must not be able to ship placeholders again — which is
exactly what 2.3.8 was.

### Trap 0 — Gemini's watermark

Gemini stamps two four-point sparkles into the bottom-right corner of every
image it generates. At 1024 — the size App Store Connect shows the marketing
icon at — they are plainly a watermark, which is what
`packages/system_design/tool/strip_icon_marker.dart` removes.

It clone-stamps a clean patch of background over the corner, cross-faded so no
seam shows. A flat `#0C0C0E` rectangle would not do: the background is a
gradient with faint diagonal streaks, and a solid block reads as a patch. The
defaults are tuned to the shipped artwork; `--rect`, `--from` and `--feather`
retarget it. Check the corner at full size afterwards.

### Trap 1 — the tool corrupts the Xcode project, every run

`flutter_launcher_icons` 0.14.4 writes the value `AppIcon` into
`ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS`, which is a
**boolean** build setting, and does it in only two of the three build
configurations. The key it meant is `ASSETCATALOG_COMPILER_APPICON_NAME`, which
this project already sets to `AppIcon` in all three.

Nothing here needs the tool to touch the pbxproj, so discard the whole diff after
every run:

```sh
git diff ios/Runner.xcodeproj/project.pbxproj   # expect the bogus setting
git checkout -- ios/Runner.xcodeproj            # throw it away
```

`git checkout` is only right when the file was clean before the run. Opening the
project in Xcode reorders it, and that reordering is a real change worth keeping
— so when the file is already dirty, snapshot it first and put the snapshot back
instead of reverting to HEAD.

### Trap 2 — the alpha channel

`remove_alpha_ios: true` is mandatory, not a preference. App Store Connect
refuses the 1024 marketing icon if it carries an alpha channel — **`ITMS-90717
Invalid App Store Icon … can't be transparent nor contain an alpha channel`** —
and it raises that *after* the whole build has uploaded, so forgetting costs a
full build-and-upload cycle.

The flatten target is `background_color_ios: "#0C0C0E"`, the app's own
`AppColors.background`, so no seam can appear against the artwork.

### What the tool also does, and should be left alone

It minifies `Contents.json` onto one line and adds the legacy iOS 6/7 sizes (50,
57, 72). Both are ugly, both are harmless, and both come straight back on the
next run. The tool owns those files.

### Android is on legacy mipmaps, not adaptive icons

Deliberate. An adaptive icon hands the launcher the outer 18 of 108dp for its
own mask, which on a full-bleed design crops the edges — here, the teal scale
down the left side. Doing it properly needs a separately padded foreground asset:
Android polish, and this repo ships iOS first.

## Verifying before you submit

```sh
# The one that gets builds rejected. Must print "no".
sips -g hasAlpha ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png

# Every entry, size and alpha at a glance.
for f in ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-*.png; do
  printf '%-34s ' "$(basename "$f")"; sips -g pixelWidth -g hasAlpha "$f" | tail -2 | tr -d ' \n'; echo
done

# Legibility. An icon lives at 60px, not at 1024 — check it there.
sips -Z 60 assets/images/final_app_icon.png --out /tmp/check60.png && open /tmp/check60.png
```

**That last one is the check people skip.** Two earlier candidates were discarded
only because they were looked at small: one lost its outer arc to the corner
mask, another collapsed into an unreadable smear.

## The launch screen is a separate thing

`flutter_launcher_icons` does **not** touch it, and it is not an image.

- **iOS**: `ios/Runner/Base.lproj/LaunchScreen.storyboard`, the `backgroundColor`
  on the root view — `#0C0C0E`. The three `LaunchImage.imageset/*.png` are the
  Flutter template's 1×1 transparent placeholders, so that colour is the only
  thing ever on screen.
- **Android**: `@color/launch_background` in `values/colors.xml`, used by both
  `drawable/launch_background.xml` and `drawable-v21/launch_background.xml`, and
  by `NormalTheme` in both `styles.xml` files.

**Both shipped pure white before**, which the hard rule forbids anywhere: the
splash is the one screen a photophobic user cannot look away from.

Android's was the sneaky one, and only wrong in light mode — easy to miss on a
dark test device. `drawable-v21` used `?android:colorBackground`, which follows
the **OS** light/dark setting and so resolved to white through
`Theme.Light.NoTitleBar`. The colour is now an explicit resource rather than
theme-derived, because this app is dark whatever the OS is set to.

It duplicates `AppColors.background`, and that cannot be avoided — the launch
window is drawn by the platform before any Dart runs. Change one, change both.

## Generating the artwork with Gemini

The shipped icon came from Gemini, after several rounds of correction. The prompt
is below verbatim; the notes after it say what each correction was for, so the
next revision does not rediscover them.

### The prompt

```
App icon for a migraine tracking app.
Flat vector line-art illustration on a solid very dark charcoal
background (#0C0C0E). Square 1:1, full bleed, flat 2D.
Professional icon design, geometric, precise, clean.

ONE CONSISTENT STROKE WEIGHT for every stroked line in the icon — the
head outline, the ear and the measurement scale — with rounded caps and
joins. The lightning bolts are the single exception: they are solid
filled shapes with no stroke at all.

LAYOUT — three zones, left to right, none of them overlapping:
  - far left, 8-14% of the width: the measurement scale
  - 20-34% of the width: the pain marks
  - 38-90% of the width: the head
All three sit within the middle 80% of the frame height, with equal
generous margins top and bottom. Nothing enters the four corners.

HEAD: a minimal human head in profile facing right, an empty outline
with the dark background showing through, in soft lavender purple
(#CDC3FF fading to #8B77F0). Drawn as ONE smooth continuous flowing
curve with no wobbles, no kinks and no flat spots. Proportions: a large
rounded cranium, a short compact nose, a small defined chin, and a
thick sturdy neck about half the width of the head. Simple ear, one
small dot for the eye, nothing else. The style of a clean minimal
medical pictogram. The outline is closed and unbroken — nothing crosses
it, nothing overlaps it, no gaps anywhere.

PAIN MARKS — EXACTLY THREE lightning bolts. Three, not two, not four,
not five. No other marks anywhere.

FILL: each bolt is a SOLID FILLED shape — a solid block of flat
lavender purple with tapered pointed ends, like the standard solid bolt
glyph. Completely filled in. It is NOT an outline, NOT hollow, and has
no visible stroke around it.

OUTSIDE THE HEAD: all three bolts sit in the empty dark background
BEYOND the head outline. None of them is inside the head. The interior
of the head stays completely empty, with the dark background showing
through it. No bolt crosses, touches or enters the outline.

POSITION: the upper-left diagonal of the skull — halfway between the
top of the head and the left side of the head, at roughly the 10
o'clock position on the cranium. Not at the crown, not at the temple,
but on the diagonal between them.

THEY ALL CONVERGE ON ONE SINGLE POINT: the three bolts are arranged
around one specific spot like spokes of a wheel, evenly spaced by
angle, and every bolt's pointed inner tip aims directly inward at that
same point.

LENGTH: each bolt is about 25% of the height of the skull — small and
compact, a neat accent rather than a dominant element.

GAP: because the bolts are small, the gap between each pointed tip and
the head outline is correspondingly small — no wider than the width of
one bolt. They read as belonging to the head, not floating away from it.

MEASUREMENT: a graduated instrument scale standing at the far left
edge: one straight vertical line in muted teal (#7FB8B0) with five
short horizontal tick marks, evenly spaced, all the same length,
pointing right. Precise and even, like the scale printed on a
measuring instrument. Well separated from the lightning bolts.

STYLE CONSTRAINTS: completely flat matte vector artwork, single layer,
uniform stroke weight throughout, geometric and precise. Sharp square
corners with the artwork running edge to edge. A wordless symbol.

Calm, minimal, medical. Only two colours: lavender purple and muted teal.
```

### Gemini has no negative prompt — that is why the constraints read oddly

Stable Diffusion and Ideogram take a separate negative field; Midjourney takes
`--no a, b, c`. **Gemini takes neither**, and writing `no text` into a prompt for
a model without that mechanism can *summon* text, because the model sees the
token and not the negation.

So every constraint above is phrased **positively** — `sharp square corners`
rather than "no rounded corners", `the interior of the head stays completely
empty` rather than "no brain". Not verbosity: the only form that works here.

If the tool being used *does* have a negative field, this is the list:

```
irregular, random, scribbled, sketchy, hand-drawn, wobbly lines,
uneven stroke width, varying line thickness,
electricity bolt logo, power symbol, charging icon, thunderstorm,
clock, gauge, speedometer, brain, wrinkles,
outlined lightning, hollow lightning, unfilled bolt, stroked bolt,
lightning touching the head, lightning crossing the outline,
broken outline, gaps in the outline,
bolt inside the head, chart inside the head, marks around the head,
aura, halo, concentric arcs, curved arcs, ripple rings, wifi icon,
sound waves, sunburst, four bolts, five bolts,
text, letters, numbers, watermark, rounded corners, border, frame,
mockup, drop shadow, glow, 3D, glossy, photorealistic, white background,
cluttered
```

### What each correction was for

Every one of them cost a round.

| Symptom | Cause | Fix in the prompt |
|---|---|---|
| Pain marks read as a **wifi signal** | Concentric curved arcs radiating from a point *are* the signal glyph | Straight/angular marks only; `concentric arcs` banned |
| Bolts looked **messy** | The prompt asked for varied, irregular lengths | `three IDENTICAL` — repetition reads as intent, variation as a mistake |
| Bolts drifted to a **power/charging symbol** | A large bolt detached from the head is its own object | Keep them small, and the gap smaller than one bolt width |
| The head **outline broke** | The prompt said the bolts should overlap the outline | Bolts outside with a clear gap; outline explicitly closed |
| Head read as a **potato** | Adjectives instead of proportions | State the proportions: cranium, nose, chin, neck-width |
| Chart looked like a **brain** | Anything inside a head outline gets pulled toward brain | Keep the chart out of the head; ban `brain` |
| Wrong **number** of bolts | Image models cannot count reliably | `EXACTLY THREE` helps but does not guarantee — generate 8–10 and pick |

**On counting: do not iterate the prompt over it.** Wrong object counts are
random noise, not a prompt defect, and editing the prompt in response breaks the
parts that were already right. Generate a batch and select.

### Known limitation of the shipped icon

It is an AI-generated **raster**: visible mottled texture and soft edges at 1024,
which App Store product pages display large. Cosmetic, blocks nothing. Rebuilding
the design as vector would give flat exact colours, crisp edges and one source
for every size. Owner's call, still open.
