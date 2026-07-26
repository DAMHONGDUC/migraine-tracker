import 'package:flutter/material.dart';

import '../constants/app_spacing_constant.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_style.dart';
import 'app_icon.dart';

/// What a message is telling the user. Drives the icon and the accent only —
/// the surface stays the same dark card either way, because a full-bleed red
/// or green bar is exactly the kind of brightness this app avoids (hard
/// rule 3).
enum AppSnackBarKind { success, error, info }

/// The one way to show a snackbar — feature code never calls
/// `ScaffoldMessenger.showSnackBar` directly.
///
/// Centralising it means the look, the timing and the "only one at a time"
/// rule are decided once. Messages arrive already localized: this takes a
/// finished string and has no opinion about where it came from.
abstract final class AppSnackBarUtils {
  /// Something the user asked for completed.
  static void success(BuildContext context, String message) =>
      _show(context, message, AppSnackBarKind.success);

  /// Something failed and the user may need to act.
  static void error(BuildContext context, String message) =>
      _show(context, message, AppSnackBarKind.error);

  /// Neutral confirmation — a value was noted, a job was queued.
  static void info(BuildContext context, String message) =>
      _show(context, message, AppSnackBarKind.info);

  static void _show(
    BuildContext context,
    String message,
    AppSnackBarKind kind,
  ) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    messenger
      // One message at a time. Queued snackbars replay stale state long
      // after the screen moved on — mid-attack, that is noise, not help.
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: _AppSnackBarBody(message: message, kind: kind),
          // The body draws its own surface, so the SnackBar itself is only
          // a positioner: no background, no padding, no elevation of its
          // own to fight the card's.
          backgroundColor: AppColors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(
            AppSpacingConstant.w16,
            0,
            AppSpacingConstant.w16,
            AppSpacingConstant.h16,
          ),
          // Errors get longer: they carry something to read and possibly
          // act on, the others are an acknowledgement.
          duration: kind == AppSnackBarKind.error
              ? const Duration(seconds: 5)
              : const Duration(seconds: 3),
          dismissDirection: DismissDirection.horizontal,
        ),
      );
  }
}

class _AppSnackBarBody extends StatelessWidget {
  const _AppSnackBarBody({required this.message, required this.kind});

  final String message;
  final AppSnackBarKind kind;

  ({IconData icon, Color accent}) get _style => switch (kind) {
    AppSnackBarKind.success => (
      icon: Icons.check_circle_outline,
      accent: AppColors.secondary,
    ),
    AppSnackBarKind.error => (
      icon: Icons.error_outline,
      accent: AppColors.error,
    ),
    AppSnackBarKind.info => (
      icon: Icons.info_outline,
      accent: AppColors.primary,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final ({IconData icon, Color accent}) style = _style;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacingConstant.w16,
        vertical: AppSpacingConstant.h12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacingConstant.r16),
        // The accent lives in the icon and a hairline edge, never a fill:
        // enough to read the kind at a glance without lighting up the
        // screen. Colour is never the only signal — the icon differs too.
        border: Border.all(color: style.accent.withValues(alpha: 0.4)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.background.withValues(alpha: 0.5),
            blurRadius: AppSpacingConstant.r12,
            offset: Offset(0, AppSpacingConstant.h4),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          AppIcon(
            style.icon,
            size: AppSpacingConstant.r20,
            color: style.accent,
          ),
          SizedBox(width: AppSpacingConstant.w12),
          Expanded(
            child: Text(message, style: AppTextStyle.bodyMedium),
          ),
        ],
      ),
    );
  }
}
