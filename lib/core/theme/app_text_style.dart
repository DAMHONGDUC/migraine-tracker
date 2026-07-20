import 'package:flutter/painting.dart';

import '../constants/app_spacing_constant.dart';
import 'app_colors.dart';

/// Single home for every text style in the app — no inline `TextStyle(...)`
/// and no `context.textTheme.*` in widgets. Metrics follow the Material 3
/// type scale so swapping in was visually lossless; sizes go through
/// [AppSpacingConstant] `sp*`, colors through [AppColors].
///
/// Getters (not consts) because screenutil resolves at runtime, after
/// ScreenUtilInit. [AppTheme] feeds these into `ThemeData.textTheme`, so
/// ambient defaults (ListTile, buttons, AppBar) stay consistent too.
///
/// Default color is [AppColors.textPrimary]; for the muted variant use
/// `.secondary` (below) instead of a manual copyWith.
abstract final class AppTextStyle {
  static TextStyle get displaySmall => TextStyle(
    fontSize: AppSpacingConstant.sp36,
    height: 44 / 36,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle get headlineMedium => TextStyle(
    fontSize: AppSpacingConstant.sp28,
    height: 36 / 28,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle get headlineSmall => TextStyle(
    fontSize: AppSpacingConstant.sp24,
    height: 32 / 24,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle get titleLarge => TextStyle(
    fontSize: AppSpacingConstant.sp22,
    height: 28 / 22,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle get titleMedium => TextStyle(
    fontSize: AppSpacingConstant.sp16,
    height: 24 / 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    color: AppColors.textPrimary,
  );

  static TextStyle get titleSmall => TextStyle(
    fontSize: AppSpacingConstant.sp14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyLarge => TextStyle(
    fontSize: AppSpacingConstant.sp16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontSize: AppSpacingConstant.sp14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodySmall => TextStyle(
    fontSize: AppSpacingConstant.sp12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: AppColors.textPrimary,
  );

  static TextStyle get labelLarge => TextStyle(
    fontSize: AppSpacingConstant.sp14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  static TextStyle get labelSmall => TextStyle(
    fontSize: AppSpacingConstant.sp11,
    height: 16 / 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  /// Below the Material scale — bottom-nav / step-progress labels only.
  static TextStyle get labelTiny => TextStyle(
    fontSize: AppSpacingConstant.sp10,
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
