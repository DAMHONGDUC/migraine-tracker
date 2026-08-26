import 'package:hooks_riverpod/hooks_riverpod.dart';

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

/// One attack by id; emits null once it's deleted so the detail screen can
/// show its gone-state instead of stale data.
final attackByIdProvider = StreamProvider.autoDispose.family<Attack?, String>(
  (ref, id) => ref.watch(attackRepositoryProvider).watchById(id),
);

/// Where a rendered share card is written before the share sheet reads it.
/// The GDPR wipe clears the same folder.
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

/// Whether another attack may be logged.
///
/// Only the log button asks. A free user who already holds more — from
/// before this limit existed, or pulled down by a sync from a device that had
/// premium — keeps every one of them and never loses a record: taking back
/// someone's own medical history is not a paywall, it is data loss.
final canLogAttackProvider = Provider<bool>((ref) {
  if (ref.watch(hasPremiumProvider)) return true;

  final List<Attack> attacks =
      ref.watch(attacksStreamProvider).value ?? const <Attack>[];

  return attacks.length < PremiumLimitConstant.attacks;
});

/// How many logs are left before the wall, once it is close enough to be
/// worth saying. Null while premium, and while the end is still far off —
/// the dashboard shows its warning only for a non-null answer.
final attacksLeftProvider = Provider<int?>((ref) {
  if (ref.watch(hasPremiumProvider)) return null;

  final List<Attack> attacks =
      ref.watch(attacksStreamProvider).value ?? const <Attack>[];
  final int left = PremiumLimitConstant.attacks - attacks.length;

  return left <= PremiumLimitConstant.attacksWarnAt && left > 0 ? left : null;
});

/// How many of the free plan's logs are spent, for [FreeLimitProgress].
///
/// Null while premium, which is what hides the indicator — unlike
/// [attacksLeftProvider] it does not go quiet as the wall approaches: History
/// shows the count all the way along, and the dashboard banner is the one
/// that only speaks near the end.
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
