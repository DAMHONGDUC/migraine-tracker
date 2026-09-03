import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../domain/enums/aura_type.dart';
import '../../domain/enums/exertion_level.dart';
import '../../domain/enums/head_region.dart';
import '../../domain/enums/medication_effect.dart';
import '../../providers.dart';

/// Edits/deletes an already-logged attack from the detail screen. The widget only renders the streamed attack and calls these.
class AttackDetailController {
  const AttackDetailController(this._ref);

  final Ref _ref;

  /// Corrects a mis-tapped intensity / location / medication.
  Future<void> updateCore(
    String id, {
    required int intensity,
    required List<HeadRegion> regions,
    required String? medicationName,
  }) async {
    SdLogger.action(LogTagConstant.attackDetail, 'Edit attack', id);
    AppAnalytics.logAttackEdited();
    try {
      await _ref
          .read(attackRepositoryProvider)
          .updateCore(
            id,
            intensity: intensity,
            regions: regions,
            medicationName: medicationName,
          );
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.attackDetail,
        'Update attack failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Corrects the exertion answer, which the log flow's fourth step set.
  Future<void> updateExertion(String id, ExertionLevel? exertionLevel) async {
    SdLogger.action(LogTagConstant.attackDetail, 'Edit attack exertion', id);
    AppAnalytics.logAttackEdited();
    try {
      await _ref
          .read(attackRepositoryProvider)
          .updateExertion(id, exertionLevel);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.attackDetail,
        'Update attack exertion failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Records (or takes back) which auras the attack came with.
  Future<void> updateAura(String id, List<AuraType>? aura) async {
    SdLogger.action(LogTagConstant.attackDetail, 'Update aura', <String,
        Object?>{'id': id, 'aura': aura?.map((AuraType a) => a.name).toList()});
    try {
      await _ref.read(attackRepositoryProvider).updateAura(id, aura);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.attackDetail,
        'Failed to update aura',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'id': id},
      );
      rethrow;
    }
  }

  /// Records (or takes back) when the dose was taken and when the pain eased. Both together, because relief without a dose measures nothing.
  Future<void> updateMedicationTiming(
    String id, {
    required DateTime? takenAt,
    required DateTime? reliefAt,
  }) async {
    SdLogger.action(
      LogTagConstant.attackDetail,
      'Update medication timing',
      <String, Object?>{
        'id': id,
        'takenAt': takenAt?.toIso8601String(),
        'reliefAt': reliefAt?.toIso8601String(),
      },
    );
    AppAnalytics.logAttackEdited();
    try {
      await _ref
          .read(attackRepositoryProvider)
          .updateMedicationTiming(id, takenAt: takenAt, reliefAt: reliefAt);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.attackDetail,
        'Update medication timing failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'id': id},
      );
      rethrow;
    }
  }

  /// Records (or takes back) when the attack stopped.
  Future<void> updateEndedAt(String id, DateTime? endedAt) async {
    SdLogger.action(LogTagConstant.attackDetail, 'Edit attack end', id);
    AppAnalytics.logAttackEdited();
    try {
      await _ref.read(attackRepositoryProvider).updateEndedAt(id, endedAt);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.attackDetail,
        'Update attack end failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Records (or takes back) whether the medication helped.
  Future<void> updateMedicationEffect(
    String id,
    MedicationEffect? effect,
  ) async {
    SdLogger.action(
      LogTagConstant.attackDetail,
      'Edit attack medication effect',
      id,
    );
    AppAnalytics.logAttackEdited();
    try {
      await _ref
          .read(attackRepositoryProvider)
          .updateMedicationEffect(id, effect);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.attackDetail,
        'Update attack medication effect failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    SdLogger.action(LogTagConstant.attackDetail, 'Delete attack', id);
    AppAnalytics.logAttackDeleted();
    try {
      await _ref.read(attackRepositoryProvider).deleteById(id);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.attackDetail,
        'Delete attack failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
