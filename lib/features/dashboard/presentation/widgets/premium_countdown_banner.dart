import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/v2/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/navigation_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../premium/providers.dart';
import 'highlighted_time_text.dart';

/// A limited-time premium-discount promo that sits right under the dashboard
/// app bar and counts down (a "today only" deal — the deadline is local
/// midnight, so it's evergreen). Tap anywhere, or the Unlock button, to open
/// the paywall. Free users only. Calm per hard rule 3 — the seconds tick but
/// nothing flashes; the countdown uses tabular figures so it doesn't jitter.
class PremiumCountdownBanner extends ConsumerStatefulWidget {
  const PremiumCountdownBanner({super.key});

  @override
  ConsumerState<PremiumCountdownBanner> createState() =>
      _PremiumCountdownBannerState();
}

class _PremiumCountdownBannerState
    extends ConsumerState<PremiumCountdownBanner> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Time left until local midnight, as HH:MM:SS.
  String get _remaining {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day + 1);
    final left = endOfDay.difference(now);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(left.inHours)}:${two(left.inMinutes % 60)}:'
        '${two(left.inSeconds % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(hasPremiumProvider)) return const SizedBox.shrink();

    final l10n = context.l10n;
    void openPaywall() => NavigationUtils.toPaywall(context, ref);

    return SdPressableScaleV2(
      pressedScale: 0.98,
      onTap: openPaywall,
      child: Container(
        padding: EdgeInsets.all(SdSpacingV2.w16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(SdSpacingV2.r16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const SdIconBadgeV2(
              icon: Icons.local_offer_outlined,
              color: AppColors.primary,
            ),
            SizedBox(width: SdSpacingV2.w16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.dashboardSaleTitle,
                    style: AppTextStyle.titleMedium,
                  ),
                  SizedBox(height: SdSpacingV2.h4),
                  Row(
                    children: [
                      SdIconV2(
                        icon: Icons.schedule_outlined,
                        size: SdSpacingV2.r16,
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: SdSpacingV2.w6),
                      Flexible(
                        child: HighlightedTimeText(
                          full: l10n.dashboardSaleEndsIn(_remaining),
                          highlight: _remaining,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: SdSpacingV2.w12),
            SdButtonV2(
              variant: SdButtonVariantV2.primary,
              compact: true,
              label: l10n.premiumUnlock,
              onPressed: openPaywall,
            ),
          ],
        ),
      ),
    );
  }
}
