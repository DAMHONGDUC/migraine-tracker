import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';
import 'package:step_progress/step_progress.dart';

import '../../features/attacks/presentation/controllers/log_controller.dart';
import '../extensions/context_extensions.dart';
import '../theme/app_colors.dart';
import '../widgets/glass/liquid_glass_theme.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final logState = ref.watch(logControllerProvider);
    final tracking = ref.watch(logFlowInProgressProvider);

    return Scaffold(
      // Let the branch content flow behind the floating glass bar so it
      // refracts through it (hard rule 3: the effect stays calm and dark).
      extendBody: kLiquidGlassEnabled,
      body: navigationShell,
      // Mid-track the tabs are meaningless — morph the nav bar into the
      // step progress; Cancel in the log screen's app bar exits the flow.
      // AnimatedSize interpolates the height difference between the two
      // bars so the swap never jolts the layout; the switcher only fades.
      bottomNavigationBar: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: const Interval(0.4, 1, curve: Curves.easeOut),
          switchOutCurve: const Interval(0.6, 1, curve: Curves.easeIn),
          child: tracking
            ? _FloatingBar(
                key: const ValueKey('progress'),
                child: _TrackingProgressBar(
                  currentStep: switch (logState.step) {
                    LogStep.location => 1,
                    LogStep.medication => 2,
                    _ => 0,
                  },
                ),
              )
            : _FloatingBar(
                key: const ValueKey('tabs'),
                child: NavigationBar(
                  // 56 is the standard height for icon + label tab bars.
                  height: 56,
                  // Transparent so the glass supplies the surface; the shadow
                  // line is dropped for the floating look.
                  backgroundColor: kLiquidGlassEnabled
                      ? Colors.transparent
                      : null,
                  elevation: kLiquidGlassEnabled ? 0 : null,
                  labelBehavior:
                      NavigationDestinationLabelBehavior.alwaysShow,
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: (index) => navigationShell.goBranch(
                    index,
                    initialLocation: index == navigationShell.currentIndex,
                  ),
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.add_circle_outline),
                      selectedIcon: const Icon(Icons.add_circle),
                      label: l10n.navLog,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.calendar_month_outlined),
                      selectedIcon: const Icon(Icons.calendar_month),
                      label: l10n.navHistory,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.insights_outlined),
                      selectedIcon: const Icon(Icons.insights),
                      label: l10n.navInsights,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.settings_outlined),
                      selectedIcon: const Icon(Icons.settings),
                      label: l10n.navSettings,
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }
}

/// Wraps a bottom bar in the floating frosted-glass treatment: side + bottom
/// margins so it "lifts" off the edges, rounded glass, and safe-area padding
/// consumed here (children have their bottom inset removed to avoid a double
/// gap). A no-op when [kLiquidGlassEnabled] is false.
class _FloatingBar extends StatelessWidget {
  const _FloatingBar({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kLiquidGlassEnabled) return child;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacingConstant.w16,
        0,
        AppSpacingConstant.w16,
        MediaQuery.paddingOf(context).bottom + AppSpacingConstant.h12,
      ),
      child: LiquidGlass.withOwnLayer(
        settings: kChromeGlass,
        shape: LiquidRoundedSuperellipse(borderRadius: AppSpacingConstant.r22),
        clipBehavior: Clip.antiAlias,
        child: MediaQuery.removePadding(
          context: context,
          removeBottom: true,
          child: child,
        ),
      ),
    );
  }
}

/// The 3-tap progress living in the nav bar slot while tracking.
class _TrackingProgressBar extends StatelessWidget {
  const _TrackingProgressBar({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final l10n = context.l10n;
    // With glass, [_FloatingBar] supplies the surface + safe-area padding, so
    // this is transparent and skips its own SafeArea to avoid a double gap.
    return Material(
      color: kLiquidGlassEnabled ? Colors.transparent : AppColors.surface,
      child: SafeArea(
        top: false,
        bottom: !kLiquidGlassEnabled,
        child: SizedBox(
          height: 68,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacingConstant.w48),
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
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
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
          ),
        ),
      ),
    );
  }
}
