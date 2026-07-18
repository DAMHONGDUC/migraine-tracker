import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// Master switch for the Liquid Glass chrome (app bar + bottom sheet).
///
/// When `false`, [MainAppBar] and [showAppBottomSheet] fall back to plain
/// Material surfaces, [AppScaffold] stops extending its body behind the bar,
/// and [MainAppBar.bodyTopInset] returns 0 — so a single flag cleanly removes
/// the effect everywhere without touching call sites.
const bool kLiquidGlassEnabled = true;

/// Shared Liquid Glass tuning for the app's chrome (app bar + bottom sheet).
///
/// Tuned for the dark, photophobia-first theme (hard rule 3): a dark glass
/// tint, gentle lighting, and no chromatic aberration, so the effect reads as
/// a calm frosted surface and never introduces a bright specular glare or
/// rainbow fringing. The glass falls back to a plain blur automatically on
/// engines without shader support (e.g. widget tests), so callers never need
/// to branch on platform.
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
