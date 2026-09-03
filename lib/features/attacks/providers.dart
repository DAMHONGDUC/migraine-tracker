import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/constants/attack_progress_constant.dart';
import '../../core/constants/premium_limit_constant.dart';
import '../../core/db/database_provider.dart';
import '../health/providers.dart';
import '../premium/providers.dart';
import '../weather/providers.dart';
import 'data/repositories/drift_attack_repository.dart';
import 'data/temporary_share_file_store.dart';
import 'domain/entities/attack.dart';
import 'domain/repositories/attack_repository.dart';
import 'domain/services/attack_share_file_store.dart';
import 'domain/services/step_attach_service.dart';
import 'domain/services/weather_attach_service.dart';
import 'presentation/controllers/attack_detail_controller.dart';
import 'presentation/controllers/attack_share_controller.dart';
import 'presentation/controllers/log_controller.dart';

final attackRepositoryProvider = Provider<AttackRepository>(
  (ref) => DriftAttackRepository(ref.watch(databaseProvider)),
);

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
final attackElapsedProvider = StreamProvider.autoDispose.family<Duration, DateTime>(
  (ref, startedAt) => Stream<Duration>.periodic(
    AttackProgressConstant.tick,
    (_) => DateTime.now().toUtc().difference(startedAt.toUtc()),
  ),
);

/// Whether another attack may be logged.
final canLogAttackProvider = Provider<bool>((ref) {
  if (ref.watch(hasPremiumProvider)) return true;

  final List<Attack> attacks =
      ref.watch(attacksStreamProvider).value ?? const <Attack>[];

  return attacks.length < PremiumLimitConstant.attacks;
});

/// How many logs are left before the wall, once it is close enough to be worth saying.
final attacksLeftProvider = Provider<int?>((ref) {
  if (ref.watch(hasPremiumProvider)) return null;

  final List<Attack> attacks =
      ref.watch(attacksStreamProvider).value ?? const <Attack>[];
  final int left = PremiumLimitConstant.attacks - attacks.length;

  return left <= PremiumLimitConstant.attacksWarnAt && left > 0 ? left : null;
});

/// How many of the free plan's logs are spent, for [FreeLimitProgress].
final attacksUsedProvider = Provider<int?>((ref) {
  if (ref.watch(hasPremiumProvider)) return null;

  return (ref.watch(attacksStreamProvider).value ?? const <Attack>[]).length;
});

/// Owns the 3-tap flow state machine (see [LogController]).
final logControllerProvider = NotifierProvider<LogController, LogFlowState>(
  LogController.new,
);

/// Edits/deletes an already-logged attack (see [AttackDetailController]).
final attackDetailControllerProvider = Provider<AttackDetailController>(
  AttackDetailController.new,
);
