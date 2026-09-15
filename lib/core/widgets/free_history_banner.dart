import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../features/attacks/providers.dart';
import '../extensions/context_extensions.dart';
import '../router/navigation_utils.dart';
import '../theme/app_colors.dart';
import '../theme/app_icon_constant.dart';

/// Where the free plan's readable history starts, and that nothing older was lost.
///
/// It replaced `AttackLimitBanner`, which counted down the last five free logs
/// (owner's call, 2026-09-14). Logging is no longer capped, so the pitch has a
/// different reason attached: the record is complete on the device and Premium
/// is what opens the part of it the window hides.
///
/// **It lives in `core/widgets/` because two features draw it** — the
/// dashboard, above the log button, and History, above its first card — and
/// neither may import the other's `presentation/`.
///
/// **Absent until something is actually hidden.** A banner offering to reveal
/// nothing is the free plan's own limit advertised as a loss.
class FreeHistoryBanner extends ConsumerWidget {
  const FreeHistoryBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime? start = ref.watch(freeHistoryStartProvider);
    final bool hasHidden = ref.watch(hasHiddenHistoryProvider);

    if (start == null || !hasHidden) return const SizedBox.shrink();

    return SdBannerV2(
      icon: AppIconConstant.history,
      color: AppColors.primary,
      title: context.l10n.freeHistoryTitle(
        DateFormat.yMMMd(context.l10n.localeName).format(start),
      ),
      subtitle: context.l10n.freeHistoryBody,
      onTap: () => NavigationUtils.toPaywall(context, ref),
    );
  }
}
