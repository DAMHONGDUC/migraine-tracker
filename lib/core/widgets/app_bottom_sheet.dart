import 'package:flutter/material.dart';

import '../constants/app_spacing_constant.dart';
import '../theme/app_colors.dart';

/// Standard modal sheet for the app. Always use this instead of raw
/// [showModalBottomSheet]: `useRootNavigator: true` makes the sheet render
/// ABOVE the bottom navigation bar (the shell's branch navigators live
/// inside the Scaffold body, so a non-root sheet slides under the nav bar).
///
/// The sheet is a flat opaque [AppColors.surface] panel — the one card colour,
/// so a sheet and the cards it covers never read as two different darks. We
/// draw our own drag handle instead of `showDragHandle`, which reserves a full
/// 48 tap row above the content and would push every sheet header down.
/// Pass `dismissible: false` for a sheet the user must act on (the force
/// update block): the barrier stops closing it, dragging is off and the
/// handle — which promises a swipe that no longer works — is dropped. The
/// sheet's own content still has to block the system back gesture
/// (`PopScope`); that is the route's job, not this presenter's.
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool dismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    showDragHandle: false,
    isDismissible: dismissible,
    enableDrag: dismissible,
    backgroundColor: AppColors.surface,
    barrierColor: AppColors.barrier,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacingConstant.r22),
      ),
    ),
    isScrollControlled: isScrollControlled,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dismissible) const _SheetDragHandle(),
        Flexible(child: builder(context)),
      ],
    ),
  );
}

/// Matches Material's default drag handle (32×4), without its 48 tap row.
class _SheetDragHandle extends StatelessWidget {
  const _SheetDragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacingConstant.h12),
      child: Center(
        child: Container(
          width: AppSpacingConstant.w32,
          height: AppSpacingConstant.h4,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppSpacingConstant.r3),
          ),
        ),
      ),
    );
  }
}
