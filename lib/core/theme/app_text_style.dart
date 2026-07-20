import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Single home for every text style in the app — no inline `TextStyle(...)`
/// and no `context.textTheme.*` in widgets. Metrics follow the Material 3
/// type scale so swapping in was visually lossless; colors come from
/// [AppColors].
///
/// Font sizes are FIXED logical px, deliberately not screenutil `.sp`:
/// text already follows the user's system text-size setting via
/// `textScaler` (the accessibility-correct channel), and `.sp` on top of
/// that blows text up on wide viewports. [AppTheme] feeds these into
/// `ThemeData.textTheme`, so ambient defaults (ListTile, buttons, AppBar)
/// stay consistent too.
///
/// Default color is [AppColors.textPrimary]; for the muted variant use
/// `.secondary` (below) instead of a manual copyWith.
abstract final class AppTextStyle {
  static const TextStyle displaySmall = TextStyle(
    fontSize: 36,
    height: 44 / 36,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    height: 16 / 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  /// Below the Material scale — bottom-nav / step-progress labels only.
  static const TextStyle labelTiny = TextStyle(
    fontSize: 10,
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
