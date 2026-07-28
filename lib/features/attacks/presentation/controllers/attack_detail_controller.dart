import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/enums/head_location.dart';
import '../../providers.dart';

/// Edits/deletes an already-logged attack from the detail screen. The
/// widget only renders the streamed attack and calls these.
class AttackDetailController {
  const AttackDetailController(this._ref);

  final Ref _ref;

  /// Corrects a mis-tapped intensity / location / medication.
  Future<void> updateCore(
    String id, {
    required int intensity,
    required HeadLocation location,
    required String? medicationName,
  }) async {
    AppLogger.action('Edit attack', id);
    AppAnalytics.logAttackEdited();
    try {
      await _ref
          .read(attackRepositoryProvider)
          .updateCore(
            id,
            intensity: intensity,
            location: location,
            medicationName: medicationName,
          );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Update attack failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    AppLogger.action('Delete attack', id);
    AppAnalytics.logAttackDeleted();
    try {
      await _ref.read(attackRepositoryProvider).deleteById(id);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Delete attack failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
