import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:live_activities/live_activities.dart';

import '../../core/constants/attack_progress_constant.dart';
import '../../core/constants/home_widget_constant.dart';
import '../../core/db/database_provider.dart';
import '../../core/storage/secure_store.dart';
import '../health/providers.dart';
import '../weather/providers.dart';
import 'data/repositories/drift_attack_repository.dart';
import 'data/services/plugin_attack_live_activity.dart';
import 'data/temporary_share_file_store.dart';
import 'domain/entities/attack.dart';
import 'domain/repositories/attack_repository.dart';
import 'domain/services/attack_live_activity.dart';
import 'domain/services/attack_share_file_store.dart';
import 'domain/services/step_attach_service.dart';
import 'domain/services/weather_attach_service.dart';
import 'presentation/controllers/attack_detail_controller.dart';
import 'presentation/controllers/attack_share_controller.dart';
import 'presentation/controllers/head_controls_controller.dart';
import 'presentation/controllers/log_controller.dart';

final attackRepositoryProvider = Provider<AttackRepository>(
  (ref) => DriftAttackRepository(ref.watch(databaseProvider)),
);

/// Every attack in the table, newest first — the ONE subscription to it.
///
/// **It must never watch the entitlement.** A stream whose creation watched the
/// premium flag was torn down and rebuilt every time the flag arrived, which
/// mid-layout is what Riverpod reports as "setState called during build".
final attacksStreamProvider = StreamProvider<List<Attack>>(
  (ref) => ref.watch(attackRepositoryProvider).watchAll(),
);

/// One attack by id; emits null once it's deleted so the detail screen can show its gone-state instead of stale data.
final attackByIdProvider = StreamProvider.autoDispose.family<Attack?, String>(
  (ref, id) => ref.watch(attackRepositoryProvider).watchById(id),
);

/// Where a rendered share card is written before the share sheet reads it. The GDPR wipe clears the same folder.
final attackShareFileStoreProvider = Provider<AttackShareFileStore>(
  (ref) => const TemporaryShareFileStore(),
);

/// Renders an attack's share card and hands it to the OS share sheet.
final attackShareControllerProvider = Provider<AttackShareController>(
  AttackShareController.new,
);

final weatherAttachServiceProvider = Provider<WeatherAttachService>(
  (ref) => WeatherAttachService(
    ref.watch(attackRepositoryProvider),
    ref.watch(weatherRepositoryProvider),
  ),
);

/// Reads Apple Health the moment an attack is saved (see [StepAttachService]).
final stepAttachServiceProvider = Provider<StepAttachService>(
  (ref) => StepAttachService(
    ref.watch(attackRepositoryProvider),
    ref.watch(healthRepositoryProvider),
  ),
);

/// The Lock Screen card for a running attack. iOS 16.1+ only; a no-op everywhere else (see [AttackLiveActivity]).
final attackLiveActivityProvider = Provider<AttackLiveActivity>(
  (ref) => PluginAttackLiveActivity(
    LiveActivities(),
    ref.watch(secureStoreProvider),
    HomeWidgetConstant.appGroupId,
  ),
);

/// The attack that is happening right now, or null. The newest one wins: two unfinished attacks means the second is the one the user is in.
final attackInProgressProvider = Provider<Attack?>((ref) {
  final List<Attack> attacks =
      ref.watch(attacksStreamProvider).value ?? const <Attack>[];
  final DateTime now = DateTime.now().toUtc();

  for (final Attack attack in attacks) {
    if (attack.isRunningAt(now)) return attack;
  }
  return null;
});

/// Redraws the running timer once a second. `autoDispose` so the ticker dies with the screen — a timer outliving the tree is a leak a widget test reports as a hang.
final attackElapsedProvider = StreamProvider.autoDispose
    .family<Duration, DateTime>(
      (ref, startedAt) => Stream<Duration>.periodic(
        AttackProgressConstant.tick,
        (_) => DateTime.now().toUtc().difference(startedAt.toUtc()),
      ),
    );

/// Whether another attack may be logged — always, for everybody.
///
/// It stays a provider rather than being deleted: every door into the log flow
/// asks it (`NavigationUtils.toLog`, the home screen widget, the Siri intent),
/// and one place answering is what stopped those doors from each half-checking
/// a limit.
final canLogAttackProvider = Provider<bool>((_) => true);

/// Owns the 3-tap flow state machine (see [LogController]).
final logControllerProvider = NotifierProvider<LogController, LogFlowState>(
  LogController.new,
);

/// Edits/deletes an already-logged attack (see [AttackDetailController]).
final attackDetailControllerProvider = Provider<AttackDetailController>(
  AttackDetailController.new,
);

/// How the head picker is driven, kept between launches (see
/// [HeadControlsController]). App-scoped rather than `autoDispose`, so the log
/// flow and the detail screen's edit sheet drive the head the same way.
final headControlsProvider =
    NotifierProvider<HeadControlsController, HeadControls>(
      HeadControlsController.new,
    );
