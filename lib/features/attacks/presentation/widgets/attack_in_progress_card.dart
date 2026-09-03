import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_icon_size.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/attack.dart';
import '../../providers.dart';

/// The dashboard's door onto a running attack, and the reason the length ever gets recorded: the question is asked while the answer is still known.
class AttackInProgressCard extends ConsumerWidget {
  const AttackInProgressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final Attack? attack = ref.watch(attackInProgressProvider);

    // The dashboard decides whether this is placed at all, so this can only be reached with an attack running — but the provider may empty under it.
    if (attack == null) return const SizedBox.shrink();

    final Duration since =
        ref.watch(attackElapsedProvider(attack.startedAt)).value ??
        DateTime.now().toUtc().difference(attack.startedAt);

    return SdCardV2(
      surface: SdCardSurfaceV2.elevated,
      onTap: () => context.pushNamed<void>(AppRoutes.attackNow.name),
      child: Padding(
        padding: EdgeInsets.all(SdSpacingConstant.w16),
        child: Row(
          children: <Widget>[
            SdIconV2(
              icon: AppIconConstant.duration,
              color: AppColors.primary,
              size: AppIconSize.large,
            ),
            SizedBox(width: SdSpacingConstant.w16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(l10n.attackNowCardTitle,
                      style: AppTextStyle.titleSmall),
                  SizedBox(height: SdSpacingConstant.h4),
                  Text(
                    l10n.attackNowCardBody,
                    style: AppTextStyle.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: SdSpacingConstant.w12),
            Text(
              DateTimeUtils.elapsed(since),
              style: AppTextStyle.titleMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
