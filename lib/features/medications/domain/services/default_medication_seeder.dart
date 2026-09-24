import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../entities/medication.dart';
import '../repositories/medication_repository.dart';

/// Puts one medication in the list of a brand-new account, so the 3-tap log
/// flow has something to pick on the very first attack.
///
/// Owner's rule. The picker's empty state sends a user who is mid-attack to the
/// medications tab to type a name, which is the worst possible moment to ask
/// for typing; one row they can rename or delete costs them nothing and saves
/// that detour.
class DefaultMedicationSeeder {
  const DefaultMedicationSeeder(this._medications);

  /// **Not an ARB string, on purpose.** This is a record the user owns, edits
  /// and syncs between devices — localizing it would make the stored value
  /// depend on the locale the device happened to be in at sign-up, and the
  /// second device would then disagree with the first about what the row is
  /// called.
  static const String defaultName = 'Paracetamol 500mg';

  final MedicationRepository _medications;

  /// Adds [defaultName] when the account has no medications at all.
  ///
  /// The emptiness check is what makes this safe to call on an account that
  /// already existed elsewhere: an anonymous session that logged medications
  /// before signing in, or a sync pull that has already landed, both leave a
  /// non-empty list and nothing is added.
  Future<void> seedIfEmpty() async {
    try {
      final List<Medication> existing = await _medications.getAll();

      if (existing.isNotEmpty) {
        SdLogger.info(
          LogTagConstant.medications,
          'Default medication skipped — list is not empty',
          <String, Object?>{'count': existing.length},
        );

        return;
      }

      SdLogger.action(
        LogTagConstant.medications,
        'Seed default medication',
        defaultName,
      );
      await _medications.upsert(
        Medication(
          id: SdId.unique(),
          name: defaultName,
          createdAt: DateTime.now().toUtc(),
        ),
      );
      SdLogger.info(
        LogTagConstant.medications,
        'Default medication seeded',
        defaultName,
      );
    } catch (error, stackTrace) {
      // Swallowed: this runs off a sign-in listener with no UI behind it, and a
      // missing convenience row must never break the sign-in it hangs off.
      SdLogger.error(
        LogTagConstant.medications,
        'Seeding the default medication failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'name': defaultName},
      );
    }
  }
}
