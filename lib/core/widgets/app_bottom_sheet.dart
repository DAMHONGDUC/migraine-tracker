import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../constants/app_spacing_constant.dart';
import 'glass/liquid_glass_theme.dart';

/// Standard modal sheet for the app. Always use this instead of raw
/// [showModalBottomSheet]: `useRootNavigator: true` makes the sheet render
/// ABOVE the bottom navigation bar (the shell's branch navigators live
/// inside the Scaffold body, so a non-root sheet slides under the nav bar).
///
/// The sheet is a frosted Liquid Glass surface: the modal barrier is
/// transparent so the content behind the sheet refracts through it. We draw
/// our own drag handle inside the glass (instead of `showDragHandle`) so the
/// handle sits on the frosted surface rather than floating above it.
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = false,
}) {
  if (!AppGlass.isSupported) {
    // Plain Material sheet: let the framework draw the drag handle and surface.
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      isScrollControlled: isScrollControlled,
      builder: builder,
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    isScrollControlled: isScrollControlled,
    builder: (context) => LiquidGlass.withOwnLayer(
      settings: kChromeGlass,
      shape: LiquidRoundedSuperellipse(borderRadius: AppSpacingConstant.r22),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SheetDragHandle(),
          Flexible(child: builder(context)),
        ],
      ),
    ),
  );
}

/// Matches Material's default drag handle (32×4), drawn inside the glass.
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
