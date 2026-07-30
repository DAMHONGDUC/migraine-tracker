import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';
import 'package:step_progress/step_progress.dart';

import '../../../../core/constants/app_content_padding.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/glass/liquid_glass_theme.dart';
import '../controllers/log_controller.dart' show LogStep;

/// The 3-tap progress as a floating bottom bar — the same slot and glass
/// treatment the shell's bottom nav used to morph into while logging. Sits in
/// [AppScaffold.bottomNavigationBar]; the log flow's body scrolls behind it.
class LogStepBar extends StatelessWidget {
  const LogStepBar({required this.step, super.key});

  final LogStep step;

  @override
  Widget build(BuildContext context) {
    final currentStep = switch (step) {
      LogStep.location => 1,
      LogStep.medication => 2,
      _ => 0,
    };
    final content = SizedBox(
      // Same height as the shell's nav pill, so the two bars line up.
      height: AppContentPadding.floatingBarHeight,
      child: _StepProgress(currentStep: currentStep),
    );

    // Glass off: a plain surface bar that reserves its own slot + safe area,
    // matching the old non-glass tracking bar.
    if (!AppGlass.isSupported) {
      return Material(
        color: AppColors.surface,
        child: SafeArea(top: false, child: content),
      );
    }

    // Glass on: the floating frosted pill — side margins so it lifts off the
    // edges, the safe-area gap below it, and the child's bottom inset removed
    // to avoid a double gap (see the shell's floating bar).
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacingConstant.w24,
        0,
        AppSpacingConstant.w24,
        MediaQuery.paddingOf(context).bottom,
      ),
      child: LiquidGlass.withOwnLayer(
        settings: kChromeGlass,
        shape: LiquidRoundedSuperellipse(
          borderRadius: AppContentPadding.floatingBarRadius,
        ),
        clipBehavior: Clip.antiAlias,
        child: MediaQuery.removePadding(
          context: context,
          removeBottom: true,
          child: content,
        ),
      ),
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacingConstant.w48,
      ).copyWith(top: AppSpacingConstant.h2),
      child: Center(
        child: StepProgress(
          totalSteps: 3,
          currentStep: currentStep,
          stepNodeSize: AppSpacingConstant.r20,
          nodeTitles: [
            l10n.stepIntensity,
            l10n.stepLocation,
            l10n.stepMedication,
          ],
          visibilityOptions: StepProgressVisibilityOptions.nodeThenLine,
          theme: StepProgressThemeData(
            activeForegroundColor: scheme.primary,
            defaultForegroundColor: scheme.surfaceContainerHigh,
            stepAnimationDuration: const Duration(milliseconds: 200),
            nodeLabelAlignment: StepLabelAlignment.bottom,
            nodeLabelStyle: StepLabelStyle(
              maxWidth: 72,
              activeColor: scheme.primary,
              defualtColor: AppColors.textSecondary,
              titleStyle: AppTextStyle.labelTiny,
              titleMaxLines: 1,
            ),
            stepLineStyle: StepLineStyle(
              lineThickness: 3,
              activeColor: scheme.primary,
              foregroundColor: scheme.surfaceContainerHigh,
              borderRadius: const Radius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}
