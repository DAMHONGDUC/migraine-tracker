import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/daily_factor_picker.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/entities/daily_log.dart';
import '../../../providers.dart';
import '../../controllers/daily_log_controller.dart';
import '../../widgets/daily_cycle_section.dart';
import '../../widgets/daily_rating_row.dart';

/// The 30-second check-in: how the night was, how the day was, and what else the day carried.
///
/// It always writes today. A day is answered where it is lived, and a screen
/// that let the user pick any date would invite filling a week in from memory —
/// which is the one thing that would make the control group worse than none.
class DailyLogScreen extends HookConsumerWidget {
  const DailyLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final DailyLog? today = ref.watch(todayDailyLogProvider).value;
    final DailyCheckInState state = ref.watch(dailyLogControllerProvider);

    // Once per mount: after that the screen owns the answers, and re-loading would undo what the user just tapped.
    useEffect(() {
      ref.read(dailyLogControllerProvider.notifier).load(today);
      return null;
    }, const <Object?>[]);

    Future<void> save() async {
      try {
        await ref
            .read(dailyLogControllerProvider.notifier)
            .save(DateTime.now());
        if (!context.mounted) return;

        SdSnackBarUtilsV2.success(context, l10n.dailyLogSaved);
        context.pop();
      } catch (_) {
        // Already logged by the controller; the screen's job is to say so.
        if (!context.mounted) return;
        SdSnackBarUtilsV2.error(context, l10n.dailyLogSaveFailed);
      }
    }

    return SdScaffoldV2(
      title: Text(l10n.dailyLogTitle, style: AppTextStyle.titleLarge),
      body: ListView(
        padding: SdContentPaddingV2.screen(context),
        children: <Widget>[
          Text(
            l10n.dailyLogWhy,
            style: AppTextStyle.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: SdContentPaddingV2.sectionGap),
          DailyRatingRow(
            question: l10n.dailyLogSleepQuestion,
            labels: <String>[
              l10n.dailyLogSleep1,
              l10n.dailyLogSleep2,
              l10n.dailyLogSleep3,
              l10n.dailyLogSleep4,
              l10n.dailyLogSleep5,
            ],
            selected: state.sleepQuality,
            onSelected: ref
                .read(dailyLogControllerProvider.notifier)
                .pickSleepQuality,
          ),
          SizedBox(height: SdContentPaddingV2.sectionGap),
          DailyRatingRow(
            question: l10n.dailyLogStressQuestion,
            labels: <String>[
              l10n.dailyLogStress1,
              l10n.dailyLogStress2,
              l10n.dailyLogStress3,
              l10n.dailyLogStress4,
              l10n.dailyLogStress5,
            ],
            selected: state.stressLevel,
            onSelected: ref
                .read(dailyLogControllerProvider.notifier)
                .pickStressLevel,
          ),
          SizedBox(height: SdContentPaddingV2.sectionGap),
          Text(l10n.dailyLogFactorsQuestion, style: AppTextStyle.titleSmall),
          SizedBox(height: SdSpacingConstant.h12),
          DailyFactorPicker(
            selected: state.factors,
            onToggled: ref
                .read(dailyLogControllerProvider.notifier)
                .toggleFactor,
          ),
          SizedBox(height: SdContentPaddingV2.sectionGap),
          // Last, and below the Save button's business: it asks nothing, so it must not stand between the questions and the answer button.
          const DailyCycleSection(),
          SizedBox(height: SdContentPaddingV2.sectionGap),
          SdButtonV2(
            label: l10n.dailyLogSave,
            variant: SdButtonVariantV2.primary,
            loading: state.isSaving,
            // Nothing answered is nothing to write, and an empty save would blank a day the user filled in earlier.
            onPressed: state.hasAnswer ? save : null,
          ),
        ],
      ),
    );
  }
}
