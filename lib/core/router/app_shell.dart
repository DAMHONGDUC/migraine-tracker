import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:system_design/index.dart';

import '../analytics/app_analytics.dart';
import '../extensions/context_extensions.dart';
import '../theme/app_icon_constant.dart';
import 'app_router.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  /// Branch order of the shell's tabs — the analytics screen name for each.
  static const List<AppRoute> _tabs = <AppRoute>[
    AppRoutes.dashboard,
    AppRoutes.history,
    AppRoutes.medications,
    AppRoutes.insights,
    AppRoutes.settings,
  ];

  @override
  void initState() {
    super.initState();
    _logTabView();
  }

  /// Tabs are branches of an IndexedStack, so no route is pushed and the
  /// navigator observer sees nothing — the screen view is logged here.
  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigationShell.currentIndex !=
        widget.navigationShell.currentIndex) {
      _logTabView();
    }
  }

  void _logTabView() => AppAnalytics.logScreenView(
    _tabs[widget.navigationShell.currentIndex].name,
  );

  @override
  Widget build(BuildContext context) {
    final navigationShell = widget.navigationShell;
    final l10n = context.l10n;

    return Scaffold(
      // - Lets branch content flow behind the floating glass bar so it refracts (hard rule 3: calm and dark).
      // - Unconditional: the nav is always the floating pill, so the body always reaches under it.
      extendBody: true,
      // Tells anything drawn over the app — a snackbar goes into the root
      // overlay, above the shell — that the pill is down there to clear.
      body: SdFloatingBarScopeV2(child: navigationShell),
      // The log flow is a pushed route now, not a tab, so the bar always shows the tab nav (no step-progress morph mid-log).
      bottomNavigationBar: _FloatingBar(
        child: _SlidingNavBar(
          selectedIndex: navigationShell.currentIndex,
          onSelected: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
          items: [
            _NavItem(
              icon: AppIconConstant.home,
              label: l10n.navDashboard,
            ),
            _NavItem(
              icon: AppIconConstant.history,
              label: l10n.navHistory,
            ),
            _NavItem(
              icon: AppIconConstant.medication,
              label: l10n.navMedications,
            ),
            _NavItem(
              icon: AppIconConstant.insights,
              label: l10n.navInsights,
            ),
            _NavItem(
              icon: AppIconConstant.settings,
              label: l10n.navSettings,
            ),
          ],
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
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<_NavItem> items;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final count = items.length;
    return SizedBox(
      // Shared with the log flow's step bar and what content clears it — see SdContentPaddingV2.floatingBarHeight.
      height: SdContentPaddingV2.floatingBarHeight,
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
                  horizontal: SdSpacingConstant.w6,
                  vertical: SdSpacingConstant.w6,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.22),
                    // Oversized radius = stadium caps, matching the bar.
                    borderRadius: BorderRadius.circular(SdSpacingConstant.r64),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (int i = 0; i < count; i++)
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
  const _NavItem({required this.icon, required this.label});

  /// One glyph for both states. Material Symbols is a variable font, so the
  /// selected tab is the SAME icon filled in — see [_NavSegment.fill]. It
  /// used to be a pair of names (`home_outlined` / `home`), which is how the
  /// tab bar's filled glyph and the outlined one on the screen it opened
  /// came to be two different drawings of the same idea.
  final IconData icon;
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
          child: SdIconV2(
            icon: item.icon,
            size: SdSpacingConstant.r26,
            color: color,
            // Solid when selected, outline when not — colour is never the
            // only signal (hard rule 3), and this is the second one.
            fill: selected ? 1 : 0,
          ),
        ),
      ),
    );
  }
}

/// Wraps a bottom bar in the floating frosted-glass treatment: side margins so
/// it "lifts" off the edges, rounded glass, and
/// [SdContentPaddingV2.navBarOffset] below it — the home indicator where there
/// is one, a flat 16 where there is none — with the child's own bottom inset
/// removed so nothing re-adds the safe area inside. Applied
/// unconditionally — the nav pill is the one surface that stays glass even
/// where [SdGlassV2.isSupported] is false, because its floating geometry is
/// layout the tab screens already pad for; the renderer degrades the surface
/// itself to `FakeGlass` there.
///
/// Any tap on the bar plays a little overshoot pop ([SdPopScaleV2], the same
/// feedback the app bar's buttons use) — smaller here, and anchored to the
/// bottom edge so the pill grows upward off the line it rests on. The scale is
/// paint-only, so the layout slot and body insets never move.
class _FloatingBar extends StatelessWidget {
  const _FloatingBar({required this.child});

  /// Barely there: this is a wide surface, and the same 18% the small icons
  /// pop by would read as the whole bar lurching.
  static const double _popPeakScale = 1.02;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SdContentPaddingV2.floatingBarHorizontal,
        0,
        SdContentPaddingV2.floatingBarHorizontal,
        SdContentPaddingV2.navBarOffset(context),
      ),
      child: SdPopScaleV2(
        peakScale: _popPeakScale,
        alignment: Alignment.bottomCenter,
        child: LiquidGlass.withOwnLayer(
          settings: kChromeGlass,
          shape: LiquidRoundedSuperellipse(
            borderRadius: SdContentPaddingV2.floatingBarRadius,
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
