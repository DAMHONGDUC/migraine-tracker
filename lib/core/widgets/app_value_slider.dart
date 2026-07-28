import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_style.dart';

/// A number the user drags: the current value, big, over the slider that
/// sets it. Used by the attack detail's intensity dialog and onboarding's
/// pressure threshold page — the same control, so it lives here rather than
/// being written twice.
///
/// [accent] colours the readout and the active track together. Callers pass
/// `AppColors.intensity(value)` so the number carries the app's one severity
/// ramp (green → yellow → orange → red) instead of each screen inventing a
/// tint. Colour is never the only signal: [label] is the value in words the
/// caller already localized ("7", "5 hPa").
class AppValueSlider extends StatelessWidget {
  const AppValueSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    this.accent,
    super.key,
  });

  /// The localized readout above the slider.
  final String label;

  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  /// Readout + active track colour. Defaults to the theme's primary.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final Color color = accent ?? AppColors.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: AppTextStyle.displaySmall.w600.copyWith(color: color),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: color,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
