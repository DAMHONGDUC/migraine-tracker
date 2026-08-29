import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'data/repositories/plugin_home_widget_repository.dart';
import 'domain/repositories/home_widget_repository.dart';
import 'domain/services/home_widget_snapshot_builder.dart';
import 'presentation/controllers/home_widget_controller.dart';

final homeWidgetRepositoryProvider = Provider<HomeWidgetRepository>(
  (ref) => PluginHomeWidgetRepository(),
);

final homeWidgetSnapshotBuilderProvider = Provider<HomeWidgetSnapshotBuilder>(
  (ref) => const HomeWidgetSnapshotBuilder(),
);

/// Whether the home-screen widget is fed, and every write to it.
final homeWidgetControllerProvider =
    NotifierProvider<HomeWidgetController, bool>(HomeWidgetController.new);

/// Whether this platform ships a widget extension at all. The Settings row is absent when it does not — a switch over nothing is worse than no switch.
final homeWidgetSupportedProvider = Provider<bool>(
  (ref) => ref.watch(homeWidgetRepositoryProvider).isSupported,
);
