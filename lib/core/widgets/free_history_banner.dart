import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../features/attacks/providers.dart';
import '../extensions/context_extensions.dart';
import '../router/navigation_utils.dart';
import '../theme/app_colors.dart';
import '../theme/app_icon_constant.dart';
import '../theme/app_icon_size.dart';
import '../theme/app_text_style.dart';
import 'premium_gate.dart';

/// Where the free plan's readable history starts, and that nothing older was lost.
///
/// It replaced `AttackLimitBanner`, which counted down the last five free logs
/// (owner's call, 2026-09-14). Logging is no longer capped, so the pitch has a
/// different reason attached: the record is complete on the device and Premium
/// is what opens the part of it the window hides.
///
/// **It lives in `core/widgets/` because two features draw it** — the
/// dashboard, above the log button, and History, at its window boundary — and
/// neither may import the other's `presentation/`.
///
/// **On History it sits where the locked rows START, not at the top of the
/// list** (owner's rule, 2026-09-21). Its body names a date and says
/// everything before it is Premium, which is a statement about a *boundary* —
/// read at the top of the list it was a notice to scroll past, and read at the
/// boundary it labels the blurred rows underneath it. The dashboard has no
/// list to sit inside, so there it stays where it was.
///
/// **Outlined, because it is the one banner in its stack to be seen first.**
/// `SdCardV2.borderColor` is the design system's own lever for that, so the
/// prominence costs no new look.
///
/// **Compact, with the app's one Unlock button** (owner's call, 2026-09-24).
/// On History it sits between rows, and a full `SdBannerV2` there was taller
/// than the rows it labels; a chevron also said "more to read" where the only
/// thing on offer is the paywall. The button names that action outright, and
/// the whole card still opens the paywall for a thumb that misses it. The title
/// is one line and only says what is locked; the body, up to three lines,
/// carries the date, that nothing was deleted, and that Premium opens it
/// (owner's call, 2026-09-24).
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

    return SdCardV2(
      borderColor: AppColors.primary,
      onTap: () => NavigationUtils.toPaywall(context, ref),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SdSpacingConstant.w12,
          vertical: SdSpacingConstant.h10,
        ),
        child: Row(
          children: <Widget>[
            SdIconV2(
              icon: AppIconConstant.history,
              size: AppIconSize.small,
              color: AppColors.primary,
            ),
            SizedBox(width: SdSpacingConstant.w12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    context.l10n.freeHistoryTitle,
                    style: AppTextStyle.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: SdSpacingConstant.h2),
                  Text(
                    context.l10n.freeHistoryBody(
                      DateFormat.yMMMd(context.l10n.localeName).format(start),
                    ),
                    style: AppTextStyle.bodySmall.secondary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: SdSpacingConstant.w8),
            const PremiumUnlockButton(),
          ],
        ),
      ),
    );
  }
}
