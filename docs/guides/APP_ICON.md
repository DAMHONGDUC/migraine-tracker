# App icon and launch screen

## Artwork

Owner V6 direction: integrate secondary symbols into minimalist V5.
Keep the head dominant and the pain bolt horizontally centered in the cranium,
excluding the nose. Integrate details inside the head to avoid an external
feature list; preserve dark negative space.

| Meaning | Integrated symbol |
|---|---|
| Head | Lavender outline inherited from V5 |
| Pain and weather | Centered coral bolt with a small teal cloud |
| Medication reminder | Capsule at the ear position with a notification dot |
| Recording and analysis | Small journal and trend line inside the neck |

Use flat colors on dark charcoal, balanced margins, and no text or pure white.
V1–V5 are retained for comparison. Market references for dominant-symbol
hierarchy: [Migraine Buddy](https://apps.apple.com/us/app/migraine-buddy-track-headache/id975074413)
and [Bearable](https://bearable.app/). Keep BaroEase artwork original.

## Sources and generation

| File | Role |
|---|---|
| `assets/images/app_icon_v1.png` | Approved V1 retained for comparison |
| `assets/images/app_icon_v2.png` | Refined V2 artwork |
| `assets/images/app_icon_v3.png` | V3 with a unified rounded pictogram style |
| `assets/images/app_icon_v4.png` | Minimalist head and pain mark |
| `assets/images/app_icon_v5.png` | V4 with the bolt centered horizontally |
| `assets/images/app_icon_v6.png` | Secondary symbols integrated inside V5 |
| `assets/images/app_icon.png` | **The one source.** Original artwork, 1024×1024, read directly by `pubspec.yaml` and by every step of the generator |
| iOS `AppIcon.appiconset` | Generated launcher sizes; opaque RGB |
| Android `mipmap-*` | Generated legacy launcher sizes |
| iOS `LaunchImage.imageset` | Rounded 112/224/336px launch images |
| Android `drawable-*` | Rounded launch images for each density |

Regenerate from the project root. No environment variable, no intermediate
file — owner's rule is that `assets/images/app_icon.png` is the only input, so
replacing that one file and running this is the whole procedure:

```sh
make app-icon
```

New artwork carrying the image generator's watermark gets its own command
first, once, before the one above:

```sh
make app-icon-strip-marker
```

It rewrites `assets/images/app_icon.png` in place through a temp file. The
current artwork is already clean, so it is not part of a regenerate — a
clone-stamp re-run over an already-clean corner degrades it.

Commit generated assets so a fresh clone cannot ship Flutter placeholders
(App Store rejection 2.3.8 previously occurred for that reason).

## Constraints and checks

| Check | Reason |
|---|---|
| Source is exactly 1024×1024 with square corners and full background | iOS applies its own corner mask |
| `remove_alpha_ios: true`, flatten to `#0C0C0E` | App Store rejects marketing icons carrying alpha (ITMS-90717) |
| Inspect the icon at 60px | Supporting details must not obscure the head |
| Review `project.pbxproj` after generation | Launcher generator can corrupt boolean asset-catalog settings; preserve any pre-existing edits |
| Keep Android legacy mipmaps | Adaptive icons require a separately padded foreground |

```sh
sips -g pixelWidth -g pixelHeight -g hasAlpha ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png
sips -Z 60 assets/images/app_icon.png --out /tmp/baroease-icon-60.png
make analyze
```

## Launch screens

Native launch backgrounds stay `#0C0C0E`. The generator rounds only the launch
image copies, using `round_icon_corners.dart`; launcher sources remain square.
Never resize the original in place: always provide a separate output path.

Every launch screen shows the icon the last run produced — three different
mechanisms, one regenerate command:

| Platform | What draws the icon | Where it comes from |
|---|---|---|
| iOS | `LaunchScreen.storyboard`'s image view | `LaunchImage.imageset`, 112/224/336px |
| Android ≤ 12 (API 30) | `launch_background.xml`, a bitmap layer over the colour — both the `drawable/` and the `drawable-v21/` copy, kept identical | `drawable-<density>/launch_image.png` |
| Android 12+ (API 31) | The OS's own splash, which ignores `windowBackground` entirely | The launcher mipmaps, masked into the system's circle |

The corners are baked into the alpha of every launch image: neither a storyboard
image view nor an Android bitmap layer can clip its own source.
