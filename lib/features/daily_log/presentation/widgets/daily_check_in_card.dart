import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/dashboard_chevron.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../providers.dart';

/// The dashboard's one ask a day. It stays on the screen once answered, saying so — a card that vanished would read as the app forgetting.
///
/// **It wears `NextReminderBanner`'s shape** (owner's call): the tinted
/// `SdIconBadgeV2`, an accent-coloured name over a muted line, and the chevron
/// at the trailing edge. Both are one-line prompts on the same list that open
/// one screen each, and they were drawn two different ways — a bare glyph and a
/// title here, a badge and a chevron there — so the same kind of row read as
/// two kinds of thing. The colour is what still separates them: primary for the
/// day's own ask, secondary for a medication.
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
              // The glyph still carries the state — a tick once the day is answered — and the badge tint stays put, so the row does not change weight when it flips.
              SdIconBadgeV2(
                icon: done
                    ? AppIconConstant.saved
                    : AppIconConstant.dailyLog,
                color: AppColors.primary,
              ),
              SizedBox(width: SdSpacingConstant.w16),
              // Separate prompt and detail so neither depends on colour for emphasis.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      done ? l10n.dailyLogCardDone : l10n.dailyLogCardPrompt,
                      style: AppTextStyle.bodyLarge.w600.copyWith(
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: SdSpacingConstant.h2),
                    Text(
                      done
                          ? l10n.dailyLogCardDoneBody
                          : l10n.dailyLogCardPromptBody,
                      style: AppTextStyle.bodySmall.secondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: SdSpacingConstant.w8),
              const DashboardChevron(),
            ],
          ),
        ),
      ),
    );
  }
}
