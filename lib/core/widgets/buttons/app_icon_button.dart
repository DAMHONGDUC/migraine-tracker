import 'package:flutter/material.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

/// The app's only icon-button widget — built on [InkWell] instead of
/// [IconButton] so there is **no** implicit `visualDensity`-driven margin
/// around the tap area, only the [padding] you explicitly pass in.
///
/// Props are named to match [IconButton] as closely as possible so existing
/// `IconButton(...)` call sites can be swapped to `AppIconButton(...)` with
/// a straight find-and-replace.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    required this.onPressed,
    this.padding,
    this.color,
    this.disabledColor,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    this.borderRadius,
    this.tooltip,
    this.mouseCursor,
    this.focusNode,
    this.autofocus = false,
    this.enableFeedback = true,
    super.key,
  });

  /// The icon to display — typically an [AppIcon].
  final Widget icon;

  /// Called when the button is tapped. If null, the button is disabled.
  final VoidCallback? onPressed;

  /// Padding around [icon], inside the tap area. No margin is added outside
  /// the tap area — this fully controls the button's footprint.
  final EdgeInsetsGeometry? padding;

  /// Foreground color applied to [icon] via [IconTheme] when enabled.
  final Color? color;

  /// Foreground color applied to [icon] via [IconTheme] when [onPressed]
  /// is null.
  final Color? disabledColor;

  final Color? focusColor;
  final Color? hoverColor;
  final Color? highlightColor;
  final Color? splashColor;

  /// Shape of the ink splash/highlight. Defaults to an 8px rounded rect.
  final BorderRadius? borderRadius;

  final String? tooltip;
  final MouseCursor? mouseCursor;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enableFeedback;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    final iconTheme = IconTheme.of(context);
    final resolvedColor = enabled
        ? (color ?? iconTheme.color)
        : (disabledColor ?? iconTheme.color?.withValues(alpha: 0.38));
    final resolvedPadding = padding ?? EdgeInsets.all(AppSpacingConstant.w8);
    final resolvedBorderRadius = BorderRadius.all(
      Radius.circular(AppSpacingConstant.r999),
    );

    Widget button = InkWell(
      onTap: onPressed,
      borderRadius: resolvedBorderRadius,
      focusColor: focusColor,
      hoverColor: hoverColor,
      highlightColor: highlightColor,
      splashColor: splashColor,
      mouseCursor: mouseCursor,
      focusNode: focusNode,
      autofocus: autofocus,
      enableFeedback: enableFeedback,
      child: Padding(
        padding: resolvedPadding,
        child: IconTheme.merge(
          data: IconThemeData(color: resolvedColor),
          child: icon,
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
