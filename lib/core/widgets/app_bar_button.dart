import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';

import '../constants/app_spacing_constant.dart';
import 'app_icon.dart';
import 'glass/glass_circle.dart';
import 'pop_scale.dart';

/// What an [AppBarButton] sits on — a prop, like `AppButtonVariant`.
///
/// - [glassCircle] — its own frosted circle. For a button on the app bar's
///   blurred strip or on a flat opaque panel (a bottom sheet's header):
///   either way there is real background under it to refract.
/// - [none] — the bare glyph, for a button on a surface that is ALREADY
///   Liquid Glass (the paywall's own header): nesting a glass layer inside
///   one has nothing left to catch the light and just reads flat.
enum AppBarButtonSurface { glassCircle, none }

/// Every icon button in an app bar — the leading back arrow and the trailing
/// actions alike — and the two actions of a sheet header. One class, so the
/// back button on one screen can never end up a different size from the
/// delete button next to it.
///
/// Three things it fixes in place:
/// - a small glyph, [iconSize] (20) rather than Material's 24, so the bar
///   stays quiet next to the title;
/// - a [tapSize] (48) target around it that is entirely invisible — the
///   finger gets the full Material touch area even though the mark it aims
///   at is small (mid-attack, a small target is a cruel one);
/// - a swell on touch ([PopScale]) — the icon grows out from under the
///   fingertip and settles back, which a small glyph needs because a
///   press-*in* would simply disappear under the finger.
///
/// Both a tap and a long press make it pop: the feedback rides the raw
/// pointer-down, so it never waits to find out which one it was.
///
/// The button owns its [surface] rather than letting the bar wrap one around
/// it — the swell has to take the circle with it, and a circle applied from
/// outside would sit still while its contents grew.
class AppBarButton extends StatelessWidget {
  const AppBarButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
    this.surface = AppBarButtonSurface.glassCircle,
    super.key,
  });

  /// The glyph. Deliberately below [AppIcon]'s 24 default.
  static double get iconSize => AppSpacingConstant.r20;

  /// The invisible square the touch may land in — Material's minimum, and
  /// the footprint `MainAppBar`'s glass circle takes for these.
  static double get tapSize => AppSpacingConstant.r44;

  /// Platform-native back arrow, for whoever needs to spell out a leading
  /// button rather than let `MainAppBar` insert one.
  static IconData get backIcon => switch (defaultTargetPlatform) {
    TargetPlatform.iOS || TargetPlatform.macOS => Icons.arrow_back_ios_new,
    _ => Icons.arrow_back,
  };

  final IconData icon;

  /// Null disables the button — it stops popping too, since nothing happens.
  final VoidCallback? onPressed;

  final String? tooltip;

  /// Falls back to the ambient icon theme, like every other [AppIcon].
  final Color? color;

  final AppBarButtonSurface surface;

  @override
  Widget build(BuildContext context) {
    final Widget target = GestureDetector(
      // Opaque so the whole invisible square takes the tap, not just the
      // glyph painted in the middle of it.
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: SizedBox.square(
        dimension: tapSize,
        child: Center(
          child: AppIcon(icon: icon, size: iconSize, color: color),
        ),
      ),
    );
    // Inside the pop, so the swell carries the surface and the glyph together
    // rather than growing the glyph inside a circle that stays put.
    final Widget dressed = switch (surface) {
      AppBarButtonSurface.glassCircle => GlassCircle(child: target),
      AppBarButtonSurface.none => target,
    };

    return Tooltip(
      message: tooltip ?? '',
      excludeFromSemantics: tooltip == null,
      child: onPressed == null ? dressed : PopScale(child: dressed),
    );
  }
}
