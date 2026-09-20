import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../features/history/providers.dart';
import '../analytics/app_analytics.dart';
import '../constants/log_tag_constant.dart';
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

  /// Whether the tablet's nav panel is open. The shell owns it, so switching tab keeps it and the branch's own navigation state is untouched.
  ///
  /// Open on every cold start, and deliberately not persisted: the panel is what tells a user arriving on an iPad what the five destinations are called, and a remembered collapse would hide that from the one launch it matters on.
  bool _navPanelExpanded = true;

  @override
  void initState() {
    super.initState();
    _logTabView();
  }

  /// Tabs are branches of an IndexedStack, so no route is pushed and the navigator observer sees nothing — the screen view is logged here.
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

  /// What a tab drops on the way in, before its branch is shown.
  ///
  /// Here rather than in the screen because a branch of an `IndexedStack` is
  /// never rebuilt on a switch — the screen has no arrival to notice. Done on
  /// the tap and not a frame later, so the view it is leaving behind is gone
  /// before the branch is on screen.
  void _resetBranch(int index) {
    if (_tabs[index] != AppRoutes.history) return;

    // History always opens on the list (owner's rule).
    ref.read(historyViewModeProvider.notifier).reset();
  }

  /// Logs the value, not just that something changed — "toggled" is not a state anything can be read back out of.
  void _setNavPanelExpanded(bool expanded) {
    SdLogger.action(LogTagConstant.shell, 'Nav panel toggled', <String, Object>{
      'expanded': expanded,
    });
    setState(() => _navPanelExpanded = expanded);
  }

  @override
  Widget build(BuildContext context) {
    final navigationShell = widget.navigationShell;
    final l10n = context.l10n;

    // The frame — the glass pill or the side panel, the sliding capsule, the
    // behind-the-chrome body — belongs to the design system. The shell keeps
    // what is its own: which branches exist, what they are called, and the
    // analytics. The log flow is a pushed route, not a tab, so the chrome
    // always shows the tab nav (no step-progress morph mid-log).
    final List<SdNavDestinationV2> destinations = <SdNavDestinationV2>[
      SdNavDestinationV2(icon: AppIconConstant.home, label: l10n.navDashboard),
      SdNavDestinationV2(icon: AppIconConstant.history, label: l10n.navHistory),
      SdNavDestinationV2(
        icon: AppIconConstant.medication,
        label: l10n.navMedications,
      ),
      SdNavDestinationV2(
        icon: AppIconConstant.insights,
        label: l10n.navInsights,
      ),
      SdNavDestinationV2(
        icon: AppIconConstant.settings,
        label: l10n.navSettings,
      ),
    ];

    void select(int index) {
      _resetBranch(index);
      navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );
    }

    // A tablet puts the five tabs down the leading edge instead of across the
    // bottom: the bottom edge of a 1180-wide window is nowhere near a thumb,
    // and a pill stretched across it stops reading as one control. Switched on
    // the WINDOW, not the device — an iPad in Split View is a phone-shaped
    // window and gets the phone's chrome back.
    //
    // Same list, same order, both ways: the breakpoint chooses the frame and
    // never the contents.
    return switch (SdBreakpointV2.of(context)) {
      SdWindowClassV2.compact => SdBottomNavigationV2(
        selectedIndex: navigationShell.currentIndex,
        onSelected: select,
        destinations: destinations,
        body: navigationShell,
      ),
      SdWindowClassV2.medium || SdWindowClassV2.expanded => SdNavPanelV2(
        selectedIndex: navigationShell.currentIndex,
        onSelected: select,
        destinations: destinations,
        body: navigationShell,
        isExpanded: _navPanelExpanded,
        onExpansionChanged: _setNavPanelExpanded,
        expandLabel: l10n.navPanelExpand,
        collapseLabel: l10n.navPanelCollapse,
      ),
    };
  }
}
