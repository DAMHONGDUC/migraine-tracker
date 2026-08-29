import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_icon_constant.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/entities/export_preview.dart';
import '../../../domain/entities/export_record.dart';
import '../../../domain/enums/export_kind.dart';
import '../../../providers.dart';

part 'export_preview_screen_pdf.dart';
part 'export_preview_screen_text.dart';

/// What is actually inside one past export, before sharing it with anyone.
class ExportPreviewScreen extends ConsumerWidget {
  const ExportPreviewScreen({required this.exportId, super.key});

  final String exportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ExportRecord? record = ref.watch(exportRecordByIdProvider(exportId));

    // Deleted from under us, or a stale link: nothing to read.
    if (record == null) {
      return SdScaffoldV2(
        title: Text(l10n.exportPreviewTitle, style: AppTextStyle.titleLarge),
        body: SdEmptyStateV2(
          icon: AppIconConstant.document,
          message: l10n.exportFileMissing,
        ),
      );
    }

    return SdScaffoldV2(
      title: Text(l10n.exportPreviewTitle, style: AppTextStyle.titleLarge),
      body: record.kind == ExportKind.pdf
          ? _PdfBody(exportId: exportId)
          : _TextBody(exportId: exportId, filename: record.filename),
    );
  }
}
