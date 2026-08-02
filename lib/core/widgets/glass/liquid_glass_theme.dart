import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// Whether this device can actually render Liquid Glass.
///
/// The effect is a fragment-shader image filter, and only Impeller can run
/// one: true on iOS, true on Android devices that get the Vulkan backend,
/// false on Android's Skia fallback (and in widget tests). When false,
/// [MainAppBar] falls back to a plain Material surface, [AppScaffold] stops
/// extending its body behind the bar, and `AppContentPadding.appBarInset`
/// returns 0.
///
/// Bottom sheets are not on this list: they are a flat opaque card-coloured
/// panel on every engine, so a sheet never reads as a different dark from the
/// cards it covers.
///
/// The shell's bottom nav is the deliberate exception — it stays a floating
/// glass pill everywhere. Its geometry (side margins, the gap beneath it,
/// the inset tab screens pad by) is layout rather than decoration, and the
/// renderer degrades that one surface to `FakeGlass` by itself.
class AppGlass {
  const AppGlass._();

  static bool? _debugOverride;

  /// Test seam: the widget-test engine is Skia, so [isSupported] is false
  /// there and every test would exercise the fallback layout instead of the
  /// shipped one. `pumpApp` pins this to true.
  @visibleForTesting
  static set debugSupported(bool? value) => _debugOverride = value;

  static bool get isSupported =>
      _debugOverride ?? ImageFilter.isShaderFilterSupported;
}

/// Shared Liquid Glass tuning for the app's chrome (app bar, nav pill, the
/// log flow's step bar).
///
/// Tuned for the dark, photophobia-first theme (hard rule 3): a dark glass
/// tint, gentle lighting, and no chromatic aberration, so the effect reads as
/// a calm frosted surface and never introduces a bright specular glare or
/// rainbow fringing.
const LiquidGlassSettings kChromeGlass = LiquidGlassSettings(
  // AppColors.background at ~50% — keeps the bar dark and text legible while
  // the blur carries the "glass" read.
  glassColor: Color(0x800E0E10),
  thickness: 12,
  blur: 10,
  // Calm: dim the virtual light and drop the rainbow edge (hard rule 3).
  lightIntensity: 0.2,
  ambientStrength: 0,
  chromaticAberration: 0,
  saturation: 1,
);
