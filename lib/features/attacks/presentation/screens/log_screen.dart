import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:step_progress/step_progress.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../controllers/log_controller.dart';
import '../widgets/intensity_step.dart';
import '../widgets/location_step.dart';
import '../widgets/medication_step.dart';
import '../widgets/saved_step.dart';

/// The sacred 3-tap flow: intensity → head location → medication → saved.
/// Pure rendering — all state lives in [logControllerProvider].
class LogScreen extends ConsumerWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(logControllerProvider);
    final controller = ref.read(logControllerProvider.notifier);
    final scheme = context.colorScheme;

    final showBack =
        state.step == LogStep.location || state.step == LogStep.medication;
    final isSaved = state.step == LogStep.saved;

    final question = switch (state.step) {
      LogStep.intensity => l10n.logIntensityTitle,
      LogStep.location => l10n.logLocationTitle,
      LogStep.medication => l10n.logMedicationTitle,
      LogStep.saved => null,
    };

    final stepIndex = switch (state.step) {
      LogStep.intensity => 0,
      LogStep.location => 1,
      LogStep.medication => 2,
      LogStep.saved => 2,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.logTitle),
        leading: showBack ? BackButton(onPressed: controller.back) : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress across the 3 taps — hidden on the saved confirmation.
          if (!isSaved) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 8.h),
              child: StepProgress(
                totalSteps: 3,
                currentStep: stepIndex,
                stepNodeSize: 26.r,
                visibilityOptions: StepProgressVisibilityOptions.nodeThenLine,
                theme: StepProgressThemeData(
                  activeForegroundColor: scheme.primary,
                  defaultForegroundColor: scheme.surfaceContainerHigh,
                  stepAnimationDuration: const Duration(milliseconds: 200),
                  stepLineStyle: StepLineStyle(
                    lineThickness: 3,
                    activeColor: scheme.primary,
                    foregroundColor: scheme.surfaceContainerHigh,
                    borderRadius: const Radius.circular(2),
                  ),
                ),
              ),
            ),
            // The question, big and readable mid-attack.
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 8.h),
              child: Text(
                question!,
                style: context.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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
                    onSelected: controller.selectLocation,
                  ),
                  LogStep.medication => MedicationStep(
                    onSelected: controller.save,
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
    );
  }
}
