import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:live_activities/live_activities.dart';

import '../../core/constants/attack_progress_constant.dart';
import '../../core/constants/home_widget_constant.dart';
import '../../core/constants/premium_limit_constant.dart';
import '../../core/db/database_provider.dart';
import '../../core/storage/secure_store.dart';
import '../health/providers.dart';
import '../premium/providers.dart';
import '../weather/providers.dart';
import 'data/repositories/drift_attack_repository.dart';
import 'data/services/plugin_attack_live_activity.dart';
import 'data/temporary_share_file_store.dart';
import 'domain/entities/attack.dart';
import 'domain/repositories/attack_repository.dart';
import 'domain/services/attack_live_activity.dart';
import 'domain/services/attack_share_file_store.dart';
import 'domain/services/attack_window.dart';
import 'domain/services/step_attach_service.dart';
import 'domain/services/weather_attach_service.dart';
import 'presentation/controllers/attack_detail_controller.dart';
import 'presentation/controllers/attack_share_controller.dart';
import 'presentation/controllers/log_controller.dart';

final attackRepositoryProvider = Provider<AttackRepository>(
  (ref) => DriftAttackRepository(ref.watch(databaseProvider)),
);

/// Every attack in the table, newest first.
///
/// **No provider here may depend on the entitlement, and that is a rule, not a
/// preference.** The premium flag arrives asynchronously — from RevenueCat in
/// production, from a stream in the tests — so a provider that watches it is
/// recomputed while the first frames are still being laid out, and Riverpod
/// reports that as "setState called during build" on whatever screen was
/// mid-transition. The free plan's 90-day window is therefore applied in the
/// WIDGET layer, through `AttackWindow` and [freeHistoryStartProvider], where
/// a rebuild is just a rebuild. `lib/features/attacks/domain/services/attack_window.dart`
/// carries the same warning.
final attacksStreamProvider = StreamProvider<List<Attack>>(
  (ref) => ref.watch(attackRepositoryProvider).watchAll(),
);

/// Where the free plan's readable history starts, or null while premium reads all of it. What the banner names.
///
/// **Local midnight, not "now minus ninety days".** Providers watch it, so an
/// unstable value — a fresh `DateTime.now()` on each read — would make every
/// unrelated invalidation look like a change. Day granularity is also what the
/// banner prints.
final freeHistoryStartProvider = Provider<DateTime?>((ref) {
  if (ref.watch(hasPremiumProvider)) return null;

  final DateTime now = DateTime.now();

  return DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(PremiumLimitConstant.freeHistoryWindow);
});

/// Whether anything at all sits behind the window, so the banner appears only where there is something to reveal.
final hasHiddenHistoryProvider = Provider<bool>(
  (ref) => AttackWindow.hides(
    ref.watch(attacksStreamProvider).value ?? const <Attack>[],
    ref.watch(freeHistoryStartProvider),
  ),
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
