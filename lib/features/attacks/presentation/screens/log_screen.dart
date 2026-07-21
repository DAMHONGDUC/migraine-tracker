import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/fitted_text.dart';
import '../../domain/enums/head_location.dart';
import '../../providers.dart';
import '../controllers/log_controller.dart' show LogStep;
import '../widgets/intensity_step.dart';
import '../widgets/location_step.dart';
import '../widgets/medication_step.dart';
import '../widgets/saved_step.dart';

/// The sacred flow: intensity → head location → medication → saved. Pure
/// rendering — all state lives in [logControllerProvider]. Intensity
/// advances immediately on tap (fastest way in, mid-attack); location and
/// medication are pick-then-confirm — the app bar's Next button commits
/// the active step's draft and advances (the last step's own "Done" is on
/// the saved screen itself, so Next never needs to relabel). While
/// tracking (any step but the first) the shell swaps the bottom nav for a
/// progress bar.
class LogScreen extends ConsumerWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(logControllerProvider);
    final controller = ref.read(logControllerProvider.notifier);
    final tracking = ref.watch(logFlowInProgressProvider);
    final showNext =
        state.step == LogStep.location || state.step == LogStep.medication;

    final question = switch (state.step) {
      LogStep.intensity => l10n.logIntensityTitle,
      LogStep.location => l10n.logLocationTitle,
      LogStep.medication => l10n.logMedicationTitle,
      LogStep.saved => null,
    };

    return AppScaffold(
      title: Text(l10n.logTitle),
      // Smaller than the default BackButton — it's a secondary action next
      // to the (now bigger) Next button.
      leading: tracking
          ? IconButton(
              onPressed: controller.back,
              icon: const BackButtonIcon(),
              iconSize: AppSpacingConstant.r18,
            )
          : null,
      actions: [
        if (showNext)
          AppButton.primary(
            onPressed: state.hasDraft ? () => controller.confirmStep() : null,
            label: l10n.logNext,
          ),
        SizedBox(width: AppSpacingConstant.w12),
      ],
      body: Padding(
        padding: EdgeInsets.only(
          top: AppScaffold.bodyTopInset(context),
          bottom: AppScaffold.bottomNavInset(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The question, big and readable mid-attack — always one line,
            // however long the localized string runs.
            if (question != null)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacingConstant.w24,
                  AppSpacingConstant.h16,
                  AppSpacingConstant.w24,
                  AppSpacingConstant.h8,
                ),
                child: FittedText(
                  question,
                  style: AppTextStyle.headlineMedium.w600,
                  maxLines: 1,
                ),
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final offset = Tween<Offset>(
                    begin: const Offset(0.06, 0),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: offset, child: child),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(state.step),
                  child: switch (state.step) {
                    LogStep.intensity => IntensityStep(
                      onSelected: controller.selectIntensity,
                    ),
                    LogStep.location => LocationStep(
                      selected: state.draft as HeadLocation?,
                      onSelected: controller.updateDraft,
                    ),
                    LogStep.medication => MedicationStep(
                      hasSelection: state.hasDraft,
                      selectedName: state.draft as String?,
                      onSelected: controller.updateDraft,
                    ),
                    LogStep.saved => SavedStep(
                      attackId: state.savedId!,
                      onDone: controller.reset,
                    ),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
