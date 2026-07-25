import 'package:flutter/material.dart';

import '../constants/app_spacing_constant.dart';
import '../theme/app_colors.dart';
import 'app_icon.dart';

enum _AppButtonVariant {
  primary,
  secondary,
  outlined,
  text,
  destructive,
  positive,
}

/// The one button widget for the whole app — feature code never uses raw
/// [FilledButton]/[OutlinedButton]/[TextButton]. Pick the constructor by
/// semantics:
///
/// - [AppButton.primary] — the main CTA of a screen/dialog (filled).
/// - [AppButton.secondary] — supporting action, tonal fill (option tiles,
///   "Unlock" teasers).
/// - [AppButton.outlined] — alternative action next to a primary.
/// - [AppButton.text] — low-emphasis action (dialog "Cancel", "Not now").
/// - [AppButton.destructive] — irreversible confirm (delete); error-tinted
///   fill so it can never be mistaken for the safe action.
/// - [AppButton.positive] — an affirmative, additive action (add an item);
///   teal-tinted fill so it reads as the "good news" option next to a
///   destructive one.
class AppButton extends StatelessWidget {
  const AppButton.primary({
    required this.label,
    required this.onPressed,
    this.icon,
    this.compact = false,
    this.labelStyle,
    super.key,
  }) : _variant = _AppButtonVariant.primary;

  const AppButton.secondary({
    required this.label,
    required this.onPressed,
    this.icon,
    this.compact = false,
    this.labelStyle,
    super.key,
  }) : _variant = _AppButtonVariant.secondary;

  const AppButton.outlined({
    required this.label,
    required this.onPressed,
    this.icon,
    this.compact = false,
    this.labelStyle,
    super.key,
  }) : _variant = _AppButtonVariant.outlined;

  const AppButton.text({
    required this.label,
    required this.onPressed,
    this.icon,
    this.compact = false,
    this.labelStyle,
    super.key,
  }) : _variant = _AppButtonVariant.text;

  const AppButton.destructive({
    required this.label,
    required this.onPressed,
    this.icon,
    this.compact = false,
    this.labelStyle,
    super.key,
  }) : _variant = _AppButtonVariant.destructive;

  const AppButton.positive({
    required this.label,
    required this.onPressed,
    this.icon,
    this.compact = false,
    this.labelStyle,
    super.key,
  }) : _variant = _AppButtonVariant.positive;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Chrome-sized button (app-bar actions): tighter padding and height.
  final bool compact;

  /// Overrides the default M3 label style (e.g. option tiles use
  /// `AppTextStyle.titleMedium`).
  final TextStyle? labelStyle;

  final _AppButtonVariant _variant;

  ButtonStyle? _style() {
    ButtonStyle? style;
    if (_variant == _AppButtonVariant.destructive) {
      style = FilledButton.styleFrom(
        backgroundColor: AppColors.error,
        foregroundColor: AppColors.onPrimary,
      );
    }
    if (_variant == _AppButtonVariant.positive) {
      style = FilledButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.onPrimary,
      );
    }
    if (compact) {
      style = ButtonStyle(
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: AppSpacingConstant.w14),
        ),
        minimumSize: WidgetStatePropertyAll(Size(0, AppSpacingConstant.h34)),
        visualDensity: VisualDensity.compact,
      ).merge(style);
    }
    return style;
  }

  @override
  Widget build(BuildContext context) {
    final style = _style();
    final text = Text(label, style: labelStyle);

    if (icon != null) {
      final iconWidget = AppIcon(icon!);
      return switch (_variant) {
        _AppButtonVariant.primary ||
        _AppButtonVariant.destructive ||
        _AppButtonVariant.positive => FilledButton.icon(
          onPressed: onPressed,
          style: style,
          icon: iconWidget,
          label: text,
        ),
        _AppButtonVariant.secondary => FilledButton.tonalIcon(
          onPressed: onPressed,
          style: style,
          icon: iconWidget,
          label: text,
        ),
        _AppButtonVariant.outlined => OutlinedButton.icon(
          onPressed: onPressed,
          style: style,
          icon: iconWidget,
          label: text,
        ),
        _AppButtonVariant.text => TextButton.icon(
          onPressed: onPressed,
          style: style,
          icon: iconWidget,
          label: text,
        ),
      };
    }

    return switch (_variant) {
      _AppButtonVariant.primary ||
      _AppButtonVariant.destructive ||
      _AppButtonVariant.positive => FilledButton(
        onPressed: onPressed,
        style: style,
        child: text,
      ),
      _AppButtonVariant.secondary => FilledButton.tonal(
        onPressed: onPressed,
        style: style,
        child: text,
      ),
      _AppButtonVariant.outlined => OutlinedButton(
        onPressed: onPressed,
        style: style,
        child: text,
      ),
      _AppButtonVariant.text => TextButton(
        onPressed: onPressed,
        style: style,
        child: text,
      ),
    };
  }
}
