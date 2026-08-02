import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/db/database_provider.dart';
import '../attacks/providers.dart';
import '../medications/providers.dart';
import 'data/documents_export_file_store.dart';
import 'data/file_dialog_file_saver.dart';
import 'data/repositories/drift_export_record_repository.dart';
import 'data/share_plus_export_sharer.dart';
import 'domain/entities/export_date_filter.dart';
import 'domain/entities/export_record.dart';
import 'domain/repositories/export_record_repository.dart';
import 'domain/services/data_export_service.dart';
import 'domain/services/data_wipe_service.dart';
import 'domain/services/dev_seed_service.dart';
import 'domain/services/export_file_store.dart';
import 'domain/services/export_record_filterer.dart';
import 'domain/services/export_sharer.dart';
import 'domain/services/file_saver.dart';
import 'presentation/controllers/export_controller.dart';
import 'presentation/controllers/export_filter_controller.dart';
import 'presentation/controllers/settings_controller.dart';

final dataExportServiceProvider = Provider<DataExportService>(
  (ref) => const DataExportService(),
);

final exportSharerProvider = Provider<ExportSharer>(
  (ref) => const SharePlusExportSharer(),
);

final exportFileStoreProvider = Provider<ExportFileStore>(
  (ref) => const DocumentsExportFileStore(),
);

final fileSaverProvider = Provider<FileSaver>(
  (ref) => const FileDialogFileSaver(),
);

final exportRecordRepositoryProvider = Provider<ExportRecordRepository>(
  (ref) => DriftExportRecordRepository(ref.watch(databaseProvider)),
);

/// The export history, newest first — every record on file.
final exportHistoryProvider = StreamProvider<List<ExportRecord>>(
  (ref) => ref.watch(exportRecordRepositoryProvider).watchAll(),
);

/// The date window the export screen is filtered to (see
/// [ExportFilterController]).
final exportFilterControllerProvider =
    NotifierProvider<ExportFilterController, ExportDateFilter>(
      ExportFilterController.new,
    );

/// [exportHistoryProvider] narrowed to that window — what the export screen
/// actually lists.
final filteredExportHistoryProvider = Provider<AsyncValue<List<ExportRecord>>>((
  ref,
) {
  final ExportDateFilter filter = ref.watch(exportFilterControllerProvider);

  return ref.watch(exportHistoryProvider).whenData(
    (List<ExportRecord> records) =>
        const ExportRecordFilterer().apply(records, filter),
  );
});

/// Produces exports and acts on past ones (see [ExportController]).
final exportControllerProvider = Provider<ExportController>(
  ExportController.new,
);

final dataWipeServiceProvider = Provider<DataWipeService>(
  (ref) => DataWipeService(
    ref.watch(attackRepositoryProvider),
    ref.watch(medicationRepositoryProvider),
    ref.watch(notificationSchedulerProvider),
    ref.watch(exportRecordRepositoryProvider),
    ref.watch(exportFileStoreProvider),
  ),
);

/// Dev-only fixture generator (see [DevSeedService]). Its settings row is
/// hidden in prod, so nothing reads this provider there.
final devSeedServiceProvider = Provider<DevSeedService>(
  (ref) => DevSeedService(
    ref.watch(dataWipeServiceProvider),
    ref.watch(attackRepositoryProvider),
    ref.watch(medicationRepositoryProvider),
    ref.watch(dataExportServiceProvider),
    ref.watch(exportFileStoreProvider),
    ref.watch(exportRecordRepositoryProvider),
  ),
);

/// Orchestrates what is left of the settings actions — the GDPR wipe (see
/// [SettingsController]). Everything export-shaped moved to
/// [ExportController].
final settingsControllerProvider = Provider<SettingsController>(
  SettingsController.new,
);
