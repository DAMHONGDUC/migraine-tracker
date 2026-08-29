import 'package:flutter/painting.dart';
import 'package:system_design/index.dart';

import 'app_colors.dart';

/// Single home for every text style in the app — no inline `TextStyle(...)` and no `context.textTheme.*` in widgets.
final class AppTextStyle {
  // - Line heights as M3 total-height / font-size ratios, defined once and reused. - Ratios are unitless, so they hold under `.sp`.
  static const double _height36 = 44 / 36;
  static const double _height28 = 36 / 28;
  static const double _height24 = 32 / 24;
  static const double _height22 = 28 / 22;
  static const double _height16 = 24 / 16;
  static const double _height14 = 20 / 14;
  static const double _height12 = 16 / 12;
  static const double _height11 = 16 / 11;

  static TextStyle get displaySmall => TextStyle(
    fontSize: SdSpacingConstant.sp36,
    height: _height36,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle get headlineMedium => TextStyle(
    fontSize: SdSpacingConstant.sp28,
    height: _height28,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle get headlineSmall => TextStyle(
    fontSize: SdSpacingConstant.sp24,
    height: _height24,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle get titleLarge => TextStyle(
    fontSize: SdSpacingConstant.sp22,
    height: _height22,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle get titleMedium => TextStyle(
    fontSize: SdSpacingConstant.sp16,
    height: _height16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    color: AppColors.textPrimary,
  );

  static TextStyle get titleSmall => TextStyle(
    fontSize: SdSpacingConstant.sp14,
    height: _height14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyLarge => TextStyle(
    fontSize: SdSpacingConstant.sp16,
    height: _height16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontSize: SdSpacingConstant.sp14,
    height: _height14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodySmall => TextStyle(
    fontSize: SdSpacingConstant.sp12,
    height: _height12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: AppColors.textPrimary,
  );

  static TextStyle get labelLarge => TextStyle(
    fontSize: SdSpacingConstant.sp14,
    height: _height14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  static TextStyle get labelSmall => TextStyle(
    fontSize: SdSpacingConstant.sp11,
    height: _height11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  /// Below the Material scale — bottom-nav / step-progress labels only.
  static TextStyle get labelTiny => TextStyle(
    fontSize: SdSpacingConstant.sp10,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
}

/// Shorthand tweaks for the two adjustments used all over the app.
extension AppTextStyleX on TextStyle {
  /// Muted variant for supporting copy.
  TextStyle get secondary => copyWith(color: AppColors.textSecondary);

  /// Semi-bold emphasis for headings and highlighted values.
  TextStyle get w600 => copyWith(fontWeight: FontWeight.w600);
}
