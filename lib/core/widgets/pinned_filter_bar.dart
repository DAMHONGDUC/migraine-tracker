import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../constants/app_spacing_constant.dart';
import '../theme/app_colors.dart';
import 'glass/liquid_glass_theme.dart';

/// A filter row anchored just below the app bar and floating above a scrolling
/// list: a fixed frosted strip that stays put on top while the list scrolls
/// underneath it, blurring content out through the same treatment as
/// [MainAppBar] so the two read as one continuous chrome strip.
///
/// It's a plain overlay box (NOT a sliver): drop it into a [Stack] over the
/// scrollable, positioned at the top, and pad the scrollable's top by
/// [heightFor] so its first item starts below the strip.
///
/// [topInset] (the app-bar height the strip sits under) is passed in rather
/// than read from `MediaQuery` here: this widget builds inside the Scaffold
/// body, where a `MediaQuery` read can differ from the same read at the
/// body-building site that pads the list — measure it once at that site (via
/// `AppScaffold.bodyTopInset`) and hand the SAME value to both so the strip and
/// the list gap always line up.
class PinnedFilterBar extends StatelessWidget {
  const PinnedFilterBar({
    required this.topInset,
    required this.child,
    super.key,
  });

  /// The app-bar height this strip is anchored under (kept transparent — the
  /// app bar paints over it).
  final double topInset;

  /// The filter content (e.g. a row of chips). Laid out left-aligned and
  /// horizontally scrollable so an overflowing row can be swiped sideways.
  final Widget child;

  /// Height of the visible filter strip below the app bar.
  static double get barHeight => AppSpacingConstant.h56;

  /// Full height the strip occupies from the top of the body, for [topInset].
  /// Pad a scrollable's top by this so its first item clears the strip, and
  /// offset a [RefreshIndicator] past it so the spinner drops below the chips.
  static double heightFor(double topInset) => topInset + barHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: heightFor(topInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Transparent: the app bar paints over this region.
          SizedBox(height: topInset),
          Expanded(child: _strip(context)),
        ],
      ),
    );
  }

  Widget _strip(BuildContext context) {
    final content = Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppSpacingConstant.w16),
        child: child,
      ),
    );
    if (!kLiquidGlassEnabled) {
      return ColoredBox(color: AppColors.background, child: content);
    }
    // Same frosted treatment as the app bar so the strip continues it.
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: kChromeGlass.blur,
          sigmaY: kChromeGlass.blur,
        ),
        child: ColoredBox(
          color: AppColors.background.withValues(alpha: 0.65),
          child: content,
        ),
      ),
    );
  }
}
