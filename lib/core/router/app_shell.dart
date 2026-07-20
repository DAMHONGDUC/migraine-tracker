import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';
import 'package:step_progress/step_progress.dart';

import '../../features/attacks/presentation/controllers/log_controller.dart'
    show LogStep;
import '../../features/attacks/providers.dart';
import '../extensions/context_extensions.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_style.dart';
import '../widgets/glass/liquid_glass_theme.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  /// How long without any touch before the bar minimises to 80%.
  static const _idleDelay = Duration(seconds: 5);

  Timer? _idleTimer;
  bool _idle = false;

  @override
  void initState() {
    super.initState();
    if (kLiquidGlassEnabled) _armIdleTimer();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  void _armIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleDelay, () {
      if (mounted) setState(() => _idle = true);
    });
  }

  /// Any touch anywhere counts as interaction: restore the bar and restart
  /// the idle countdown.
  void _onPointerDown(PointerDownEvent _) {
    if (!kLiquidGlassEnabled) return;
    if (_idle) setState(() => _idle = false);
    _armIdleTimer();
  }

  @override
  Widget build(BuildContext context) {
    final navigationShell = widget.navigationShell;
    final l10n = context.l10n;
    final logState = ref.watch(logControllerProvider);
    final tracking = ref.watch(logFlowInProgressProvider);

    return Listener(
      // Translucent: observes every pointer-down without eating it.
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      child: Scaffold(
        // Let the branch content flow behind the floating glass bar so it
        // refracts through it (hard rule 3: the effect stays calm and dark).
        extendBody: kLiquidGlassEnabled,
        body: navigationShell,
        // Mid-track the tabs are meaningless — morph the nav bar into the
        // step progress; Cancel in the log screen's app bar exits the flow.
        // ONE _FloatingBar stays mounted for both states so the glass layer
        // never rebuilds mid-swap (re-creating it caused a visible hitch);
        // inside it, AnimatedSize morphs the height while the switcher
        // cross-fades + slides the content.
        // Mid-log the bar is the 3-tap progress — always full size; the idle
        // minimise only applies to the tab nav.
        bottomNavigationBar: _FloatingBar(
          shrunk: _idle && !tracking,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.12),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: tracking
                  ? _TrackingProgressBar(
                      key: const ValueKey('progress'),
                      currentStep: switch (logState.step) {
                        LogStep.location => 1,
                        LogStep.medication => 2,
                        _ => 0,
                      },
                    )
                  : _SlidingNavBar(
                      key: const ValueKey('tabs'),
                      selectedIndex: navigationShell.currentIndex,
                      onSelected: (index) => navigationShell.goBranch(
                        index,
                        initialLocation: index == navigationShell.currentIndex,
                      ),
                      items: [
                        _NavItem(
                          icon: Icons.add_circle_outline,
                          selectedIcon: Icons.add_circle,
                          label: l10n.navLog,
                        ),
                        _NavItem(
                          icon: Icons.calendar_month_outlined,
                          selectedIcon: Icons.calendar_month,
                          label: l10n.navHistory,
                        ),
                        _NavItem(
                          icon: Icons.insights_outlined,
                          selectedIcon: Icons.insights,
                          label: l10n.navInsights,
                        ),
                        _NavItem(
                          icon: Icons.settings_outlined,
                          selectedIcon: Icons.settings,
                          label: l10n.navSettings,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A tab bar whose highlight *slides* under the selected destination (same
/// mechanic as the History view toggle) instead of Material's fade-in
/// indicator. Calm 250ms ease — no flash (hard rule 3).
class _SlidingNavBar extends StatelessWidget {
  const _SlidingNavBar({
    required this.selectedIndex,
    required this.onSelected,
    required this.items,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<_NavItem> items;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final count = items.length;
    return Container(
      // Same height as the tracking progress bar — the morph between the
      // two states is then a pure cross-fade, no size jump.
      height: AppSpacingConstant.h56,
      decoration: BoxDecoration(
        color: kLiquidGlassEnabled ? null : scheme.surfaceContainer,
      ),
      child: Stack(
        children: [
          // The sliding thumb: 1/N wide, aligned to the selected segment.
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: AlignmentDirectional(
              count == 1 ? 0 : -1 + 2 * selectedIndex / (count - 1),
              0,
            ),
            child: FractionallySizedBox(
              widthFactor: 1 / count,
              heightFactor: 1,
              child: Padding(
                // Slim inset so the thumb hugs the container border.
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacingConstant.w6,
                  vertical: AppSpacingConstant.w6,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.22),
                    // Oversized radius = stadium caps, matching the bar.
                    borderRadius: BorderRadius.circular(AppSpacingConstant.r64),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < count; i++)
                Expanded(
                  child: _NavSegment(
                    item: items[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _NavSegment extends StatelessWidget {
  const _NavSegment({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Icon(
            selected ? item.selectedIcon : item.icon,
            size: AppSpacingConstant.r26,
            color: color,
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
///
/// While [shrunk] the pill scales down to 80%, anchored to the bottom — the
/// idle "minimised" state; any touch restores it (see _AppShellState). The
/// scale is paint-only, so the layout slot and body insets never move.
class _FloatingBar extends StatelessWidget {
  const _FloatingBar({required this.child, this.shrunk = false});

  final Widget child;
  final bool shrunk;

  @override
  Widget build(BuildContext context) {
    if (!kLiquidGlassEnabled) return child;
    return Padding(
      // Sit the bar right on the safe-area line — the only gap below it.
      // Slim side margins: the wider the pill, the bigger each item's
      // tappable slice.
      padding: EdgeInsets.fromLTRB(
        AppSpacingConstant.w8,
        0,
        AppSpacingConstant.w8,
        MediaQuery.paddingOf(context).bottom,
      ),
      child: AnimatedScale(
        scale: shrunk ? 0.8 : 1,
        alignment: Alignment.bottomCenter,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: LiquidGlass.withOwnLayer(
          settings: kChromeGlass,
          // Half the bar height (h68) → a true stadium: the short edges are
          // full semicircles, no straight segment left.
          shape: LiquidRoundedSuperellipse(
            borderRadius: AppSpacingConstant.h34,
          ),
          clipBehavior: Clip.antiAlias,
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: child,
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
    // With glass, [_FloatingBar] supplies the surface + safe-area padding, so
    // this is transparent and skips its own SafeArea to avoid a double gap.
    return Material(
      color: kLiquidGlassEnabled ? Colors.transparent : AppColors.surface,
      child: SafeArea(
        top: false,
        bottom: !kLiquidGlassEnabled,
        child: SizedBox(
          height: AppSpacingConstant.h56,
          child: Padding(
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
          ),
        ),
      ),
    );
  }
}
