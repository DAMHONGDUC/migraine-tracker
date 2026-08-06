import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:step_progress/step_progress.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../controllers/log_controller.dart' show LogStep;

/// The 3-tap progress as a floating bottom bar — the same slot, glass
/// treatment, side margin and bottom offset the shell's bottom nav used to
/// morph into while logging (both read `SdContentPaddingV2.
/// floatingBarHorizontal` and `.navBarOffset`, never their own copy). Sits in
/// [SdScaffoldV2.bottomNavigationBar]; the log flow's body scrolls behind it.
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
      height: SdContentPaddingV2.floatingBarHeight,
      child: _StepProgress(currentStep: currentStep),
    );

    // Glass off: plain surface bar, matching the old non-glass tracking bar.
    if (!SdGlassV2.isSupported) {
      return Material(
        color: AppColors.surface,
        child: SafeArea(top: false, child: content),
      );
    }

    // - Glass on: floating frosted pill, same margins/offset as the nav pill.
    // - Child's bottom inset removed to avoid a double gap.
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SdContentPaddingV2.floatingBarHorizontal,
        0,
        SdContentPaddingV2.floatingBarHorizontal,
        SdContentPaddingV2.navBarOffset(context),
      ),
      child: LiquidGlass.withOwnLayer(
        settings: kChromeGlass,
        shape: LiquidRoundedSuperellipse(
          borderRadius: SdContentPaddingV2.floatingBarRadius,
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
        horizontal: SdSpacingConstant.w48,
      ).copyWith(top: SdSpacingConstant.h2),
      child: Center(
        child: StepProgress(
          totalSteps: 3,
          currentStep: currentStep,
          stepNodeSize: SdSpacingConstant.r20,
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
