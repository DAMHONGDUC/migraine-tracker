import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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

    final title = switch (state.step) {
      LogStep.intensity => l10n.logIntensityTitle,
      LogStep.location => l10n.logLocationTitle,
      LogStep.medication => l10n.logMedicationTitle,
      LogStep.saved => l10n.logTitle,
    };

    final showBack =
        state.step == LogStep.location || state.step == LogStep.medication;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: showBack ? BackButton(onPressed: controller.back) : null,
      ),
      body: AnimatedSwitcher(
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
            LogStep.medication => MedicationStep(onSelected: controller.save),
            LogStep.saved => SavedStep(
              attackId: state.savedId!,
              onDone: controller.reset,
            ),
          },
        ),
      ),
    );
  }
}
