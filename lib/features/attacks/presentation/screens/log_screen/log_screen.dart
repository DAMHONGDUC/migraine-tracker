import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../domain/enums/exertion_level.dart';
import '../../../domain/enums/head_region.dart';
import '../../../providers.dart';
import '../../controllers/log_controller.dart' show LogStep;
import '../../widgets/attack_start_sheet.dart';
import '../../widgets/exertion_step.dart';
import '../../widgets/intensity_step.dart';
import '../../widgets/location_step.dart';
import '../../widgets/log_step_bar.dart';
import '../../widgets/medication_step.dart';
import '../../widgets/saved_step.dart';

/// The sacred flow: intensity → head location → medication → saved, with a skippable exertion step before the save.
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
    // Medication and exertion arrive pre-selected, so Next is armed on arrival; location is the only step that waits for a pick.
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

    // - Body clears the floating step bar while it shows. - Else just the home indicator + a gap, once saved.
    final bottomInset = question != null
        ? SdContentPaddingV2.bottomBar(context)
        : SdContentPaddingV2.bottom(context);
    // Medication step scrolls its grid behind the step bar (like the tab flows); the grid applies [bottomInset] as its own scroll padding.
    final isMedication = state.step == LogStep.medication;

    return SdScaffoldV2(
      // The question IS the title: a headline in the body under a bar saying "Log" spent the top of every step twice.
      //
      // Sized against every other step's question, not against itself: fitted
      // alone, "Where does it hurt?" came out at full size and "Were you
      // exerting yourself?" a few points smaller, and the title jumping size
      // step to step read as the bar moving rather than the question changing.
      title: SdFittedTextV2(
        question ?? l10n.logTitle,
        style: AppTextStyle.titleLarge,
        maxLines: 1,
        peers: <String>[
          l10n.logTitle,
          l10n.logIntensityTitle,
          l10n.logLocationTitle,
          l10n.logMedicationTitle,
          l10n.logExertionTitle,
        ],
      ),
      // - First step: leading button cancels the whole flow (pops route).
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
        // Next holds its slot on every step, shown or not. The app bar gives
        // the title whatever the actions leave, so a Next that vanished on
        // the intensity and saved steps handed those two a wider box — and
        // [SdFittedTextV2] sized the shared question larger there, which is
        // the very jump `peers` exists to prevent.
        Visibility(
          visible: showNext,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: SdButtonV2(
            variant: SdButtonVariantV2.primary,
            size: SdButtonSizeV2.small,
            onPressed: canAdvance ? () => controller.confirmStep() : null,
            label: l10n.logNext,
          ),
        ),
        SizedBox(width: SdSpacingConstant.w12),
      ],
      // Step progress lives in the bottom bar slot (same floating spot the shell's nav morphs into); hidden once saved, body uses a plain inset.
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
                      startedAt: state.startedAt ?? DateTime.now().toUtc(),
                      onDone: closeFlow,
                    ),
                  },
                ),
              ),
            ),
            // One slot under the content, one button per step — the first step asks WHEN, every step after it offers the way out.
            if (state.step == LogStep.intensity)
              Padding(
                padding: EdgeInsets.only(top: SdSpacingConstant.h8),
                child: SdButtonV2(
                  variant: SdButtonVariantV2.text,
                  onPressed: () async {
                    final ({DateTime startedAt})? picked =
                        await AttackStartSheet(
                          startedAt: state.startedAt ?? DateTime.now().toUtc(),
                        ).show(context);

                    if (picked != null) {
                      controller.setStartedAt(picked.startedAt);
                    }
                  },
                  label: state.startedAt == null
                      ? l10n.logStartEarlier
                      : l10n.logStartedAt(
                          DateFormat.MMMd(
                            l10n.localeName,
                          ).add_jm().format(state.startedAt!.toLocal()),
                        ),
                ),
              )
            // The way out for the attack that is too bad to finish answering. Under the content rather than in the app bar: the bar already carries Next, and this one belongs where the thumb is.
            else if (question != null)
              Padding(
                padding: EdgeInsets.only(top: SdSpacingConstant.h8),
                child: SdButtonV2(
                  variant: SdButtonVariantV2.text,
                  onPressed: () => controller.saveNow(),
                  label: l10n.logSaveNow,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
