import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../controllers/log_controller.dart';
import '../widgets/intensity_step.dart';
import '../widgets/location_step.dart';
import '../widgets/medication_step.dart';
import '../widgets/saved_step.dart';

/// The sacred 3-tap flow: intensity → head location → medication → saved.
/// Pure rendering — all state lives in [logControllerProvider]. While
/// tracking (step 2+) the shell swaps the bottom nav for a progress bar.
class LogScreen extends ConsumerWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(logControllerProvider);
    final controller = ref.read(logControllerProvider.notifier);
    final tracking = ref.watch(logFlowInProgressProvider);

    final question = switch (state.step) {
      LogStep.intensity => l10n.logIntensityTitle,
      LogStep.location => l10n.logLocationTitle,
      LogStep.medication => l10n.logMedicationTitle,
      LogStep.saved => null,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.logTitle),
        leading: tracking ? BackButton(onPressed: controller.back) : null,
        actions: [
          if (tracking)
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: context.colorScheme.error,
                foregroundColor: context.colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(horizontal: AppSpacingConstant.w14),
                minimumSize: Size(0, AppSpacingConstant.h34),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: controller.reset,
              child: Text(l10n.commonCancel),
            ),
          SizedBox(width: AppSpacingConstant.w12),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The question, big and readable mid-attack.
          if (question != null)
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacingConstant.w24, AppSpacingConstant.h16, AppSpacingConstant.w24, AppSpacingConstant.h8),
              child: Text(
                question,
                style: context.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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
