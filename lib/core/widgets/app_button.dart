import 'package:flutter/material.dart';

import '../constants/app_spacing_constant.dart';
import '../theme/app_colors.dart';
import 'app_icon.dart';

/// What a button *means*, passed to [AppButton] as a prop — never a named
/// constructor per variant.
///
/// - [primary] — the main CTA of a screen/dialog (filled).
/// - [secondary] — supporting action, tonal fill (option tiles, "Unlock"
///   teasers).
/// - [outlined] — alternative action next to a primary.
/// - [text] — low-emphasis action (dialog "Cancel", "Not now").
/// - [destructive] — irreversible confirm (delete); error-tinted fill so it
///   can never be mistaken for the safe action.
/// - [positive] — an affirmative, additive action (add an item); teal-tinted
///   fill so it reads as the "good news" option next to a destructive one.
enum AppButtonVariant {
  primary,
  secondary,
  outlined,
  text,
  destructive,
  positive,
}

/// The one button widget for the whole app — feature code never uses raw
/// [FilledButton]/[OutlinedButton]/[TextButton]:
///
/// ```dart
/// AppButton(variant: AppButtonVariant.primary, label: ..., onPressed: ...)
/// ```
///
/// With an [icon] the content is always the same shape whatever the variant:
/// a fixed [iconSize] glyph, a fixed [iconGap], then the label. Material's
/// own `.icon` constructors are deliberately not used — they carry their own
/// padding per variant, which is what made the filled Apple button and the
/// outlined Google button sit differently.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.variant,
    required this.label,
    required this.onPressed,
    this.icon,
    this.compact = false,
    this.labelStyle,
    super.key,
  });

  /// Leading glyph box — one size for every icon in every button, so two
  /// buttons stacked on top of each other line up.
  static double get iconSize => AppSpacingConstant.r20;

  /// Breathing room between the glyph and the label.
  static double get iconGap => AppSpacingConstant.w12;

  final AppButtonVariant variant;
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Chrome-sized button (app-bar actions): tighter padding and height.
  final bool compact;

  /// Overrides the default M3 label style (e.g. option tiles use
  /// `AppTextStyle.titleMedium`). Left null the button resolves its own,
  /// which is also what keeps the foreground colour per variant.
  final TextStyle? labelStyle;

  ButtonStyle? _style() {
    ButtonStyle? style;

    if (variant == AppButtonVariant.destructive) {
      style = FilledButton.styleFrom(
        backgroundColor: AppColors.error,
        foregroundColor: AppColors.onPrimary,
      );
    }
    if (variant == AppButtonVariant.positive) {
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

  Widget _child() {
    final Text text = Text(label, style: labelStyle);

    if (icon == null) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppIcon(icon!, size: iconSize),
        SizedBox(width: iconGap),
        Flexible(child: text),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle? style = _style();
    final Widget child = _child();

    return switch (variant) {
      AppButtonVariant.primary ||
      AppButtonVariant.destructive ||
      AppButtonVariant.positive => FilledButton(
        onPressed: onPressed,
        style: style,
        child: child,
      ),
      AppButtonVariant.secondary => FilledButton.tonal(
        onPressed: onPressed,
        style: style,
        child: child,
      ),
      AppButtonVariant.outlined => OutlinedButton(
        onPressed: onPressed,
        style: style,
        child: child,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: onPressed,
        style: style,
        child: child,
      ),
    };
  }
}
