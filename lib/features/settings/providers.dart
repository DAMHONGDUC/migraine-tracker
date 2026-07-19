import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../attacks/providers.dart';
import '../medications/providers.dart';
import 'data/share_plus_export_sink.dart';
import 'data/share_plus_pdf_sharer.dart';
import 'domain/services/data_export_service.dart';
import 'domain/services/data_wipe_service.dart';
import 'domain/services/export_sink.dart';
import 'domain/services/pdf_sharer.dart';

final dataExportServiceProvider = Provider<DataExportService>(
  (ref) => const DataExportService(),
);

final exportSinkProvider = Provider<ExportSink>(
  (ref) => const SharePlusExportSink(),
);

final pdfSharerProvider = Provider<PdfSharer>(
  (ref) => const SharePlusPdfSharer(),
);

final dataWipeServiceProvider = Provider<DataWipeService>(
  (ref) => DataWipeService(
    ref.watch(attackRepositoryProvider),
    ref.watch(medicationRepositoryProvider),
  ),
);
