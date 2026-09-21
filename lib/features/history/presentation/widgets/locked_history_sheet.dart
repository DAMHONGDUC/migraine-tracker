import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/constants/premium_limit_constant.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/navigation_utils.dart';
import '../../../../core/theme/app_text_style.dart';

/// Why one history row cannot be read, and the way to open it.
///
/// **A blurred row opens this rather than the paywall itself** (owner's rule,
/// 2026-09-21, and it is the exception to "a surface already labelled Premium
/// opens the paywall directly"). Those other surfaces are whole cards that say
/// what premium would show in them; this is a pill on a row, and a pill has no
/// space to say *why this attack in particular* is unreadable when the ten
/// above it are not. The sheet is where that sentence fits, and the paywall is
/// one tap further on.
///
/// It says nothing about the attack. The date, the intensity and the
/// medication are exactly what the blur is covering, so naming any of them
/// here would hand back through the explanation what the row withholds.
class LockedHistorySheet extends ConsumerWidget {
  const LockedHistorySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SdSheetContentV2(
      title: context.l10n.historyLockedTitle,
      closeTooltip: context.l10n.commonClose,
      // The sheet's own pinned commit, not `PremiumUnlockButton`: a sheet in
      // this app commits from the button along its bottom edge, and the label
      // is the same `premiumUnlock` string that button wears.
      confirmLabel: context.l10n.premiumUnlock,
      onConfirm: () {
        // Out of the way first, so backing out of the paywall lands on
        // History rather than on a sheet explaining what was just offered.
        Navigator.of(context).pop();
        NavigationUtils.toPaywall(context, ref);
      },
      child: Text(
        context.l10n.historyLockedBody(
          PremiumLimitConstant.freeHistoryWindow.inDays,
        ),
        style: AppTextStyle.bodyMedium,
      ),
    );
  }
}

/// Sheets expose their opener as `.show(context)`, never a top-level `showX` (CLAUDE.md § Code style).
extension LockedHistorySheetExt on LockedHistorySheet {
  Future<void> show(BuildContext context) =>
      showSdBottomSheetV2<void>(context, builder: (_) => this);
}
