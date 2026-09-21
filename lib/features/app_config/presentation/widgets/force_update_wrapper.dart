import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/entities/app_update_config.dart';
import '../../providers.dart';
import 'force_update_sheet.dart';

/// Wraps the whole app (see `BaroEaseApp`) and puts the update sheet over it
/// once this build is too old to run.
///
/// **A layer, not a pushed route** (owner's report, 2026-09-21). It used to
/// push a non-dismissible bottom sheet onto `rootNavigatorKeyProvider`, which
/// is go_router's own navigator: the sheet appeared over the splash and then
/// vanished the moment the splash called `context.go('/dashboard')`, because
/// that rebuilds the stack the sheet was sitting in. `_sheetShown` was already
/// true by then, so nothing put it back and the user reached the dashboard on
/// a build the owner had blocked.
///
/// It is still a sheet over the app, not a screen instead of it (owner's rule,
/// 2026-09-21) — `ForceUpdateSheet` draws the same barrier and panel, without
/// a route to lose.
class ForceUpdateWrapper extends ConsumerStatefulWidget {
  const ForceUpdateWrapper({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ForceUpdateWrapper> createState() => _ForceUpdateWrapperState();
}

class _ForceUpdateWrapperState extends ConsumerState<ForceUpdateWrapper>
    with WidgetsBindingObserver {
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

  @override
  Widget build(BuildContext context) {
    final PlatformUpdateConfig? blocking = ref
        .watch(forceUpdateControllerProvider)
        .blockingUpdate;

    if (blocking == null) return widget.child;

    return ForceUpdateSheet(config: blocking, child: widget.child);
  }
}
