import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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

  @override
  Widget build(BuildContext context) {
    final navigationShell = widget.navigationShell;
    final l10n = context.l10n;

    // The frame — glass pill, sliding thumb, behind-the-bar body and the
    // adjacent-tab swipe — is SdBottomNavigationV2's. The shell keeps what is
    // its own: which branches exist, what they are called, and the analytics.
    // The log flow is a pushed route, not a tab, so the bar always shows the
    // tab nav (no step-progress morph mid-log).
    return SdBottomNavigationV2(
      selectedIndex: navigationShell.currentIndex,
      onSelected: (int index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      ),
      destinations: <SdNavDestinationV2>[
        SdNavDestinationV2(
          icon: AppIconConstant.home,
          label: l10n.navDashboard,
        ),
        SdNavDestinationV2(
          icon: AppIconConstant.history,
          label: l10n.navHistory,
        ),
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
      ],
      body: navigationShell,
    );
  }
}
