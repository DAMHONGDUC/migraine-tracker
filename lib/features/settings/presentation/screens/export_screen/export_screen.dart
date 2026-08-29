import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/file_size_utils.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/extensions/doctor_report_strings_l10n.dart';
import '../../../../../core/extensions/export_kind_label.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_icon_constant.dart';
import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/entities/export_date_filter.dart';
import '../../../domain/entities/export_record.dart';
import '../../../domain/enums/export_action.dart';
import '../../../domain/enums/export_kind.dart';
import '../../../providers.dart';
import '../../controllers/export_controller.dart';
import '../../widgets/export_actions_sheet.dart';
import '../../widgets/export_date_filter_sheet.dart';
import '../../widgets/export_kind_sheet.dart';

part 'export_screen_date_filter_pill.dart';
part 'export_screen_empty_state.dart';
part 'export_screen_history.dart';
part 'export_screen_no_match_state.dart';
part 'export_screen_record_tile.dart';

/// Export data, and everything already exported.
class ExportScreen extends ConsumerWidget {
  const ExportScreen({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ExportKind? kind = await const ExportKindSheet().show(context);

    if (kind == null) return;

    // The doctor report is localized and l10n lives here, not in the controller.
    await ref
        .read(exportControllerProvider)
        .create(
          kind,
          reportStrings: kind == ExportKind.pdf
              ? l10n.doctorReportStrings(DateTime.now())
              : null,
        );
    if (context.mounted) SdSnackBarUtilsV2.success(context, l10n.exportCreated);
  }

  Future<void> _openActions(
    BuildContext context,
    WidgetRef ref,
    ExportRecord record,
  ) async {
    final l10n = context.l10n;
    final ExportController controller = ref.read(exportControllerProvider);
    final ExportAction? action = await ExportActionsSheet(
      record: record,
    ).show(context);

    if (action == null || !context.mounted) return;

    // Delete is the one action that works on a missing file — clears a row whose file is gone.
    if (action != ExportAction.delete && !await controller.fileExists(record)) {
      if (context.mounted) {
        SdSnackBarUtilsV2.error(context, l10n.exportFileMissing);
      }
      return;
    }
    if (!context.mounted) return;

    switch (action) {
      case ExportAction.preview:
        await context.pushNamed<void>(
          AppRoutes.exportPreview.name,
          pathParameters: <String, String>{AppRoutes.exportIdParam: record.id},
        );
      case ExportAction.share:
        await controller.share(record);
      case ExportAction.saveToDevice:
        final bool saved = await controller.saveToDevice(record);
        // False means the user dismissed the picker — say nothing.
        if (saved && context.mounted) {
          SdSnackBarUtilsV2.success(context, l10n.exportSaved);
        }
      case ExportAction.delete:
        await _confirmDelete(context, controller, record);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ExportController controller,
    ExportRecord record,
  ) async {
    final l10n = context.l10n;
    final bool? confirmed = await showSdDialogV2<bool>(
      context,
      builder: (BuildContext dialogContext) => SdDialogV2(
        title: l10n.exportDeleteTitle,
        content: Text(l10n.exportDeleteBody, style: AppTextStyle.bodyMedium),
        actions: <Widget>[
          SdButtonV2(
            variant: SdButtonVariantV2.text,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            label: l10n.commonCancel,
          ),
          SdButtonV2(
            variant: SdButtonVariantV2.destructive,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            label: l10n.exportDeleteAction,
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await controller.delete(record);
    if (context.mounted) SdSnackBarUtilsV2.success(context, l10n.exportDeleted);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // Nothing to filter until something has been exported.
    final bool hasAny =
        ref.watch(exportHistoryProvider).value?.isNotEmpty ?? false;

    return SdCollapsingFilterScaffoldV2(
      title: Text(l10n.exportTitle, style: AppTextStyle.titleLarge),
      actions: <Widget>[
        SdButtonV2(
          variant: SdButtonVariantV2.primary,
          label: l10n.exportNewAction,
          icon: AppIconConstant.share,
          onPressed: () => _create(context, ref),
        ),
        SizedBox(width: SdSpacingConstant.w4),
      ],
      filter: hasAny ? const _DateFilterPill() : null,
      // - pads itself to scroll behind the frosted bar and strip.
      body: ListView(
        padding: EdgeInsets.only(
          top: hasAny
              ? SdContentPaddingV2.belowPinnedFilterBar(context)
              : SdContentPaddingV2.top(context),
          bottom: SdContentPaddingV2.bottom(context),
        ),
        children: <Widget>[
          _History(
            onRecordTap: (ExportRecord record) =>
                _openActions(context, ref, record),
          ),
        ],
      ),
    );
  }
}
