import 'dart:typed_data';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/db/database_provider.dart';
import '../alerts/providers.dart';
import '../attacks/providers.dart';
import '../auth/providers.dart';
import '../home_widget/providers.dart';
import '../medications/providers.dart';
import '../notifications/providers.dart';
import '../sync/providers.dart';
import '../weather/providers.dart';
import 'data/documents_export_file_store.dart';
import 'data/file_dialog_file_saver.dart';
import 'data/repositories/drift_export_record_repository.dart';
import 'data/services/url_mail_launcher.dart';
import 'data/share_plus_export_sharer.dart';
import 'domain/entities/export_date_filter.dart';
import 'domain/entities/export_preview.dart';
import 'domain/entities/export_record.dart';
import 'domain/entities/wipe_status.dart';
import 'domain/repositories/export_record_repository.dart';
import 'domain/services/data_export_service.dart';
import 'domain/services/data_wipe_service.dart';
import 'domain/services/dev_seed_service.dart';
import 'domain/services/export_file_store.dart';
import 'domain/services/export_record_filterer.dart';
import 'domain/services/export_sharer.dart';
import 'domain/services/file_saver.dart';
import 'domain/services/mail_launcher.dart';
import 'presentation/controllers/contact_controller.dart';
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

  return ref
      .watch(exportHistoryProvider)
      .whenData(
        (List<ExportRecord> records) =>
            const ExportRecordFilterer().apply(records, filter),
      );
});

/// One export by id, for the preview screen. Null once it is deleted — the
/// screen says so rather than reading a file that is no longer anybody's.
final exportRecordByIdProvider = Provider.family<ExportRecord?, String>((
  ref,
  id,
) {
  final List<ExportRecord> records =
      ref.watch(exportHistoryProvider).value ?? const <ExportRecord>[];

  for (final ExportRecord record in records) {
    if (record.id == id) return record;
  }
  return null;
});

/// A JSON or CSV export read back as text (see [ExportController.preview]).
final exportPreviewProvider = FutureProvider.family<ExportPreview, String>((
  ref,
  id,
) async {
  final ExportRecord? record = ref.watch(exportRecordByIdProvider(id));

  if (record == null) throw StateError('No export $id');

  return ref.watch(exportControllerProvider).preview(record);
});

/// A PDF export's bytes, for the page renderer.
final exportPreviewBytesProvider = FutureProvider.family<Uint8List, String>((
  ref,
  id,
) async {
  final ExportRecord? record = ref.watch(exportRecordByIdProvider(id));

  if (record == null) throw StateError('No export $id');

  return ref.watch(exportControllerProvider).previewBytes(record);
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
    ref.watch(notificationRepositoryProvider),
    ref.watch(exportRecordRepositoryProvider),
    ref.watch(exportFileStoreProvider),
    ref.watch(authRepositoryProvider),
    ref.watch(syncServiceProvider),
    ref.watch(alertRegistrationRepositoryProvider),
    ref.watch(dailyPressureRepositoryProvider),
    ref.watch(attackShareFileStoreProvider),
    ref.watch(homeWidgetRepositoryProvider),
  ),
);

/// Dev-only fixture generator (see [DevSeedService]). Its settings row is
/// hidden in prod, so nothing reads this provider there.
final devSeedServiceProvider = Provider<DevSeedService>(
  (ref) => DevSeedService(
    ref.watch(dataWipeServiceProvider),
    ref.watch(attackRepositoryProvider),
    ref.watch(medicationRepositoryProvider),
    ref.watch(medicationReminderRepositoryProvider),
    ref.watch(dataExportServiceProvider),
    ref.watch(exportFileStoreProvider),
    ref.watch(exportRecordRepositoryProvider),
    ref.watch(notificationRepositoryProvider),
    ref.watch(dailyPressureRepositoryProvider),
  ),
);

/// Orchestrates what is left of the settings actions — the GDPR wipe (see
/// [SettingsController]). Everything export-shaped moved to
/// [ExportController].
final settingsControllerProvider =
    NotifierProvider<SettingsController, WipeStatus>(SettingsController.new);

final mailLauncherProvider = Provider<MailLauncher>(
  (ref) => const UrlMailLauncher(),
);

/// Opens the support mail composer (see [ContactController]).
final contactControllerProvider = Provider<ContactController>(
  ContactController.new,
);
