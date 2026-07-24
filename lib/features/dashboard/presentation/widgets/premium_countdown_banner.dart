import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../../premium/providers.dart';

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
    void openPaywall() => context.pushNamed(AppRoutes.paywall.name);

    return PressableScale(
      pressedScale: 0.98,
      onTap: openPaywall,
      child: Container(
        padding: EdgeInsets.all(AppSpacingConstant.w16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacingConstant.r16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: AppSpacingConstant.r44,
              height: AppSpacingConstant.r44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_offer_outlined,
                size: AppSpacingConstant.r22,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: AppSpacingConstant.w16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.dashboardSaleTitle,
                    style: AppTextStyle.titleMedium,
                  ),
                  SizedBox(height: AppSpacingConstant.h4),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: AppSpacingConstant.r16,
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: AppSpacingConstant.w6),
                      Flexible(
                        child: Text(
                          l10n.dashboardSaleEndsIn(_remaining),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.bodySmall.secondary.copyWith(
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacingConstant.w12),
            AppButton.primary(
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
