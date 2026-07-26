import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_style.dart';

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
      // Ambient defaults (ListTile, AppBar, buttons) come from the same
      // single source as explicit styles: AppTextStyle.
      textTheme: TextTheme(
        displaySmall: AppTextStyle.displaySmall,
        headlineMedium: AppTextStyle.headlineMedium,
        headlineSmall: AppTextStyle.headlineSmall,
        titleLarge: AppTextStyle.titleLarge,
        titleMedium: AppTextStyle.titleMedium,
        titleSmall: AppTextStyle.titleSmall,
        bodyLarge: AppTextStyle.bodyLarge,
        bodyMedium: AppTextStyle.bodyMedium,
        bodySmall: AppTextStyle.bodySmall,
        labelLarge: AppTextStyle.labelLarge,
        labelSmall: AppTextStyle.labelSmall,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      // Facebook-style tabs: no M3 indicator pill; the active tab switches
      // outline → solid (icon/selectedIcon pairs) and tints primary.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : AppColors.textSecondary,
          ),
        ),
        // Fixed size/weight — only the color changes on tab switch, so
        // labels never jump.
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppTextStyle.labelSmall.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : AppColors.textSecondary,
          ),
        ),
      ),
      cardTheme: const CardThemeData(color: AppColors.surface, elevation: 0),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surfaceElevated,
      ),
      // A backstop only — the app's look lives in AppSnackBarUtils. Without
      // it, M3's default inverse surface is a bright bar on a dark screen.
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: AppTextStyle.bodyMedium,
        behavior: SnackBarBehavior.floating,
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
