import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../domain/enums/exertion_level.dart';
import '../../../domain/enums/head_region.dart';
import '../../../providers.dart';
import '../../controllers/log_controller.dart' show LogStep;
import '../../widgets/exertion_step.dart';
import '../../widgets/intensity_step.dart';
import '../../widgets/location_step.dart';
import '../../widgets/log_step_bar.dart';
import '../../widgets/medication_step.dart';
import '../../widgets/saved_step.dart';

/// The sacred flow: intensity → head location → medication → saved, with a
/// skippable exertion step before the save. Pure
/// rendering — all state lives in [logControllerProvider]. Intensity
/// advances immediately on tap (fastest way in, mid-attack); location and
/// medication are pick-then-confirm — the app bar's Next button commits
/// the active step's draft and advances (the last step's own "Done" is on
/// the saved screen itself, so Next never needs to relabel).
///
/// This is a full-screen pushed route (opened from the dashboard's log
/// button). The step progress lives in a floating bottom bar ([LogStepBar])
/// — the same slot the shell's bottom nav used to morph into. The app bar's
/// leading button cancels the flow (pops the route) on the first step and
/// steps back on later ones. "Done" on the saved screen pops back.
class LogScreen extends ConsumerWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(logControllerProvider);
    final controller = ref.read(logControllerProvider.notifier);
    final showNext =
        state.step == LogStep.location ||
        state.step == LogStep.medication ||
        state.step == LogStep.exertion;
    // Medication and exertion arrive pre-selected, so Next is armed on
    // arrival; location is the only step that waits for a pick.
    final canAdvance = state.hasDraft;

    final question = switch (state.step) {
      LogStep.intensity => l10n.logIntensityTitle,
      LogStep.location => l10n.logLocationTitle,
      LogStep.medication => l10n.logMedicationTitle,
      LogStep.exertion => l10n.logExertionTitle,
      LogStep.saved => null,
    };

    void closeFlow() {
      controller.reset();
      context.pop();
    }

    // - Body clears the floating step bar while it shows.
    // - Else just the home indicator + a gap, once saved.
    final bottomInset = question != null
        ? SdContentPaddingV2.bottomBar(context)
        : SdContentPaddingV2.bottom(context);
    // Medication step scrolls its grid behind the step bar (like the tab
    // flows); the grid applies [bottomInset] as its own scroll padding.
    final isMedication = state.step == LogStep.medication;

    return SdScaffoldV2(
      // The question IS the title. It used to be a headline inside the body
      // as well as a bar saying "Log", which spent the top of every step
      // twice: once on a word the user already knew and once on the only
      // sentence that changes. SdFittedTextV2 shrinks it rather than wrapping,
      // because the bar has a back button on one side and Next on the other.
      title: SdFittedTextV2(
        question ?? l10n.logTitle,
        style: AppTextStyle.titleLarge,
        maxLines: 1,
      ),
      // - First step: leading button cancels the whole flow (pops route).
      // - Later steps: leading button steps back via LogController.
      // - Saved: no leading — only "Done" leaves.
      leading: switch (state.step) {
        LogStep.saved => null,
        LogStep.intensity => SdAppBarButtonV2(
          icon: SdAppBarButtonV2.backIcon,
          onPressed: closeFlow,
        ),
        _ => SdAppBarButtonV2(
          icon: SdAppBarButtonV2.backIcon,
          onPressed: controller.back,
        ),
      },
      actions: [
        if (showNext)
          SdButtonV2(
            variant: SdButtonVariantV2.primary,
            size: SdButtonSizeV2.small,
            onPressed: canAdvance ? () => controller.confirmStep() : null,
            label: l10n.logNext,
          ),
        SizedBox(width: SdSpacingConstant.w12),
      ],
      // Step progress lives in the bottom bar slot (same floating spot the
      // shell's nav morphs into); hidden once saved, body uses a plain inset.
      bottomNavigationBar: question != null
          ? LogStepBar(step: state.step)
          : null,
      body: Padding(
        padding: EdgeInsets.only(
          top: SdContentPaddingV2.appBarInset(context),
          bottom: isMedication ? 0 : bottomInset,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                      selected:
                          (state.draft as List<HeadRegion>?) ??
                          const <HeadRegion>[],
                      onChanged: controller.updateDraft,
                    ),
                    LogStep.medication => MedicationStep(
                      hasSelection: state.hasDraft,
                      selectedName: state.draft as String?,
                      onSelected: controller.updateDraft,
                      scrollBottomInset: bottomInset,
                    ),
                    LogStep.exertion => ExertionStep(
                      selected: state.draft as ExertionLevel?,
                      onSelected: controller.updateDraft,
                    ),
                    LogStep.saved => SavedStep(
                      attackId: state.savedId!,
                      onDone: closeFlow,
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
