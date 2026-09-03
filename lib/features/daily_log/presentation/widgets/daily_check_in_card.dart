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
import '../../../../l10n/gen/app_localizations.dart';
import '../../providers.dart';

/// The dashboard's one ask a day. It stays on the screen once answered, saying so — a card that vanished would read as the app forgetting.
class DailyCheckInCard extends ConsumerWidget {
  const DailyCheckInCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool done = ref.watch(isTodayCheckedInProvider);

    return Semantics(
      button: true,
      label: l10n.dailyLogA11yOpen,
      excludeSemantics: true,
      child: SdCardV2(
        surface: SdCardSurfaceV2.elevated,
        onTap: () => context.pushNamed<void>(AppRoutes.dailyLog.name),
        child: Padding(
          padding: EdgeInsets.all(SdSpacingConstant.w16),
          child: Row(
            children: <Widget>[
              SdIconV2(
                icon: done
                    ? AppIconConstant.saved
                    : AppIconConstant.dailyLog,
                color: done ? AppColors.primary : AppColors.textPrimary,
                size: AppIconSize.large,
              ),
              SizedBox(width: SdSpacingConstant.w16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      done ? l10n.dailyLogCardDone : l10n.dailyLogCardPrompt,
                      style: AppTextStyle.titleSmall,
                    ),
                    SizedBox(height: SdSpacingConstant.h4),
                    Text(
                      done
                          ? l10n.dailyLogCardDoneBody
                          : l10n.dailyLogCardPromptBody,
                      style: AppTextStyle.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
