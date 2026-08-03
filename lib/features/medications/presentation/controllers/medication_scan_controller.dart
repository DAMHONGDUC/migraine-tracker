import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/logging/crash_reporter.dart';
import '../../domain/entities/medication_draft.dart';
import '../../domain/services/medication_label_parser.dart';
import '../../domain/services/medication_photo_source.dart';
import '../../providers.dart';

/// Takes a photo of a medicine box and turns it into a draft for the details
/// form. Nothing is saved here — the user reviews and edits every field
/// first, because a misread label is worse than an empty one.
class MedicationScanController {
  const MedicationScanController(this._ref);

  final Ref _ref;
  static const MedicationLabelParser _parser = MedicationLabelParser();

  /// Null when the user backed out of the picker; an empty draft when the
  /// photo had no legible text — the caller tells those two apart because
  /// only the second deserves a "nothing found" message.
  Future<MedicationDraft?> scan(MedicationPhotoOrigin origin) async {
    try {
      final String? path = await _ref
          .read(medicationPhotoSourceProvider)
          .pick(origin);

      if (path == null) return null;

      AppLogger.action('Scan medication label', origin.name);
      // Usage only: what the label says is health data and never leaves here.
      AppAnalytics.logMedicationScanned();

      final List<String> lines = await _ref
          .read(medicationTextRecognizerProvider)
          .recognize(path);

      return _parser.parse(lines);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Scan medication label failed',
        error: error,
        stackTrace: stackTrace,
      );
      CrashReporter.recordError(
        error,
        stackTrace,
        reason: 'medication label scan',
      );
      rethrow;
    }
  }
}
