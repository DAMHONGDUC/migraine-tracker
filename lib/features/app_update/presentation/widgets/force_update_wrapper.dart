import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/entities/app_update_config.dart';
import '../../providers.dart';
import 'force_update_sheet.dart';

/// Wraps the whole app (see `BaroEaseApp`).
class ForceUpdateWrapper extends ConsumerStatefulWidget {
  const ForceUpdateWrapper({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ForceUpdateWrapper> createState() => _ForceUpdateWrapperState();
}

class _ForceUpdateWrapperState extends ConsumerState<ForceUpdateWrapper>
    with WidgetsBindingObserver {
  /// The sheet is a route, so it survives rebuilds — this stops a second copy being pushed on top of the first.
  bool _sheetShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// "Every time you enter the app" includes coming back from the store or from the background, not just a cold start.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  void _check() =>
      unawaited(ref.read(forceUpdateControllerProvider.notifier).check());

  /// The sheet needs a Navigator, and this wrapper sits ABOVE the router's one (it comes from `MaterialApp.builder`), so it is presented on the root.
  void _showSheet(PlatformUpdateConfig config) {
    final BuildContext? navigatorContext = ref
        .read(rootNavigatorKeyProvider)
        .currentContext;

    if (_sheetShown || navigatorContext == null) return;
    _sheetShown = true;
    AppAnalytics.logForceUpdateShown();
    unawaited(ForceUpdateSheet(config: config).show(navigatorContext));
  }

  @override
  Widget build(BuildContext context) {
    final PlatformUpdateConfig? blocking = ref
        .watch(forceUpdateControllerProvider)
        .blockingUpdate;

    // After the frame: the navigator must exist before pushing a route, and this runs during the first build on a cold start.
    if (blocking != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showSheet(blocking));
    }
    return widget.child;
  }
}
