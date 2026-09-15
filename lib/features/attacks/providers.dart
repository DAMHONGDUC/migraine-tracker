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

/// Every attack in the table, newest first — the ONE subscription to it.
///
/// **This provider never knows about the entitlement.** The free plan's window
/// is applied by [visibleAttacksProvider]; a stream whose creation watched the
/// premium flag was torn down and rebuilt every time the flag arrived, which
/// mid-layout is what Riverpod reports as "setState called during build".
final attacksStreamProvider = StreamProvider<List<Attack>>(
  (ref) => ref.watch(attackRepositoryProvider).watchAll(),
);

/// Where the free plan's readable history starts, or null while premium reads all of it.
///
/// **It is STATE, not a computation over the entitlement, and that is the whole
/// design.** The premium flag arrives asynchronously — RevenueCat in
/// production, a stream in the tests — so a provider that *watches* it is
/// recomputed while frames are still being laid out, and Riverpod reports that
/// as "setState called during build" on whatever screen was mid-transition.
/// The flag is absorbed here instead: `BaroEaseApp` listens for it and calls
/// [FreeHistoryStart.refresh] after the frame, so every provider below may
/// watch this one freely.
///
/// **Local midnight, not "now minus ninety days".** Providers watch it, so an
/// unstable value — a fresh `DateTime.now()` on each read — would make every
/// unrelated invalidation look like a change. Day granularity is also what the
/// banner prints.
class FreeHistoryStart extends Notifier<DateTime?> {
  @override
  DateTime? build() => _startFor(ref.read(hasPremiumProvider));

  /// Recomputed after the frame in which the entitlement changed.
  void refresh() => state = _startFor(ref.read(hasPremiumProvider));

  static DateTime? _startFor(bool hasPremium) {
    if (hasPremium) return null;

    final DateTime now = DateTime.now();

    return DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(PremiumLimitConstant.freeHistoryWindow);
  }
}

final freeHistoryStartProvider = NotifierProvider<FreeHistoryStart, DateTime?>(
  FreeHistoryStart.new,
);

/// The attacks a free user may READ BACK: the last [PremiumLimitConstant.freeHistoryWindow], or all of them with premium.
///
/// What History reads — list, calendar, charts and filter options — and the one
/// owner of the window, so no two surfaces can disagree about where it starts.
///
/// **The Insights analyses deliberately read [attacksStreamProvider] instead.**
/// Wiring them here re-broke the assertion below: their chain of derived
/// providers recomputes when this stream is rebuilt, and on the Insights tab
/// that lands mid-layout. Nothing is lost by it — every analysis that is worth
/// money sits behind `PremiumGate`, so a free user sees a lock rather than an
/// answer computed over a longer record. `docs/PREMIUM_RULES.md` records this.
///
/// **A stream of its own, not a sync provider over [attacksStreamProvider].**
/// A derived `Provider<AsyncValue<…>>` notifies its watchers the instant the
/// table emits — including while a route is popping, which Riverpod reports as
/// "setState called during build". Watching [freeHistoryStartProvider] is safe
/// precisely because that one is state updated after the frame.
///
/// Nothing here filters what is STORED: the repository still holds every
/// attack, sync still pushes them, and the weather backfill still reaches the
/// oldest one — premium reveals them rather than restoring them.
final visibleAttacksProvider = StreamProvider<List<Attack>>((ref) {
  final DateTime? from = ref.watch(freeHistoryStartProvider);

  return ref
      .watch(attackRepositoryProvider)
      .watchAll()
      .map((List<Attack> attacks) => AttackWindow.within(attacks, from));
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
