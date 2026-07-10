import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Dark-first theme. Users are photophobic: dark is the default and only
/// theme in v1, and no flashing/emphasis animations are added here.
abstract final class AppTheme {
  static ThemeData get dark {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          surfaceContainerHigh: AppColors.surfaceElevated,
          surfaceContainerHighest: AppColors.surfaceElevated,
          onSurface: AppColors.textPrimary,
          onSurfaceVariant: AppColors.textSecondary,
          error: AppColors.error,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surfaceElevated,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
