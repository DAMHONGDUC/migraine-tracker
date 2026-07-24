import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../../premium/providers.dart';

/// A limited-time premium-discount promo that sits right under the dashboard
/// app bar and counts down (a "today only" deal — the deadline is local
/// midnight, so it's evergreen). Tapping opens the paywall. Free users only;
/// premium users never see it. Calm per hard rule 3 — the seconds tick but
/// nothing flashes.
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
    return PressableScale(
      pressedScale: 0.98,
      onTap: () => context.pushNamed(AppRoutes.paywall.name),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacingConstant.w16,
          vertical: AppSpacingConstant.h12,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacingConstant.r16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.local_offer_outlined,
              size: AppSpacingConstant.r22,
              color: AppColors.primary,
            ),
            SizedBox(width: AppSpacingConstant.w12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.dashboardSaleTitle, style: AppTextStyle.titleSmall),
                  SizedBox(height: AppSpacingConstant.h2),
                  Text(
                    l10n.dashboardSaleEndsIn(_remaining),
                    style: AppTextStyle.bodySmall.secondary,
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacingConstant.w8),
            _CountdownPill(time: _remaining),
          ],
        ),
      ),
    );
  }
}

/// The countdown value in a tinted pill, so the ticking clock reads as the
/// urgent part of the promo.
class _CountdownPill extends StatelessWidget {
  const _CountdownPill({required this.time});

  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacingConstant.w12,
        vertical: AppSpacingConstant.h6,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSpacingConstant.r999),
      ),
      child: Text(
        time,
        style: AppTextStyle.labelLarge.w600.copyWith(
          color: AppColors.onPrimary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
