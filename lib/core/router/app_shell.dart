import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:step_progress/step_progress.dart';

import '../../features/attacks/presentation/controllers/log_controller.dart';
import '../extensions/context_extensions.dart';
import '../theme/app_colors.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final logState = ref.watch(logControllerProvider);
    final tracking = ref.watch(logFlowInProgressProvider);

    return Scaffold(
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
            ? _TrackingProgressBar(
                key: const ValueKey('progress'),
                currentStep: switch (logState.step) {
                  LogStep.location => 1,
                  LogStep.medication => 2,
                  _ => 0,
                },
              )
            : NavigationBar(
                key: const ValueKey('tabs'),
                // 56 is the standard height for icon + label tab bars.
                height: 56,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
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
    );
  }
}

/// The 3-tap progress living in the nav bar slot while tracking.
class _TrackingProgressBar extends StatelessWidget {
  const _TrackingProgressBar({required this.currentStep, super.key});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final l10n = context.l10n;
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 48.w),
            child: Center(
              child: StepProgress(
                totalSteps: 3,
                currentStep: currentStep,
                stepNodeSize: 20.r,
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
