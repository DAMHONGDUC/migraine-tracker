import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_content_padding.dart';
import '../../../../../core/constants/app_spacing_constant.dart';
import '../../../../../core/constants/file_size_utils.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/extensions/doctor_report_strings_l10n.dart';
import '../../../../../core/extensions/export_kind_label.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/buttons/app_button.dart';
import '../../../../../core/widgets/app_dialog.dart';
import '../../../../../core/widgets/app_filter_pill.dart';
import '../../../../../core/widgets/app_icon.dart';
import '../../../../../core/widgets/app_snack_bar.dart';
import '../../../../../core/widgets/collapsing_filter_scaffold.dart';
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

/// Export data, and everything already exported. Reached from Settings.
///
/// Exports are written to disk and recorded, so a row can be re-shared or
/// saved to the device later without rebuilding the file.
///
/// The history can be narrowed to a date window. The pill that does it rides in
/// a [CollapsingFilterScaffold], so it sits under the app bar while reading and
/// lifts into it once the list scrolls — the same behaviour as the medications
/// tab.
class ExportScreen extends ConsumerWidget {
  const ExportScreen({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ExportKind? kind = await const ExportKindSheet().show(context);

    if (kind == null) return;

    // The doctor report is localized and l10n lives here, not in the
    // controller — build its copy before handing over.
    await ref
        .read(exportControllerProvider)
        .create(
          kind,
          reportStrings: kind == ExportKind.pdf
              ? l10n.doctorReportStrings(DateTime.now())
              : null,
        );
    if (context.mounted) AppSnackBarUtils.success(context, l10n.exportCreated);
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

    // Delete is the one action that works on a missing file — it is how the
    // user clears a row whose file is already gone.
    if (action != ExportAction.delete && !await controller.fileExists(record)) {
      if (context.mounted) {
        AppSnackBarUtils.error(context, l10n.exportFileMissing);
      }
      return;
    }
    if (!context.mounted) return;

    switch (action) {
      case ExportAction.share:
        await controller.share(record);
      case ExportAction.saveToDevice:
        final bool saved = await controller.saveToDevice(record);
        // False means the user dismissed the picker — say nothing.
        if (saved && context.mounted) {
          AppSnackBarUtils.success(context, l10n.exportSaved);
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
    final bool? confirmed = await showAppDialog<bool>(
      context,
      builder: (BuildContext dialogContext) => AppDialog(
        title: l10n.exportDeleteTitle,
        content: Text(l10n.exportDeleteBody, style: AppTextStyle.bodyMedium),
        actions: <Widget>[
          AppButton(
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            label: l10n.commonCancel,
          ),
          AppButton(
            variant: AppButtonVariant.destructive,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            label: l10n.exportDeleteAction,
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await controller.delete(record);
    if (context.mounted) AppSnackBarUtils.success(context, l10n.exportDeleted);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // Nothing to filter until something has been exported, so the strip only
    // exists once the list does.
    final bool hasAny =
        ref.watch(exportHistoryProvider).value?.isNotEmpty ?? false;

    return CollapsingFilterScaffold(
      title: Text(l10n.exportTitle, style: AppTextStyle.titleLarge),
      actions: <Widget>[
        AppButton(
          variant: AppButtonVariant.primary,
          label: l10n.exportNewAction,
          icon: Icons.ios_share,
          onPressed: () => _create(context, ref),
        ),
        SizedBox(width: AppSpacingConstant.w4),
      ],
      filter: hasAny ? const _DateFilterPill() : null,
      // The list pads itself so it scrolls behind the frosted bar and the strip;
      // no gutter of its own — a ListTile brings one. The top inset stays put
      // whether the strip is showing or not (see CollapsingFilterScaffold).
      body: ListView(
        padding: EdgeInsets.only(
          top: hasAny
              ? AppContentPadding.belowPinnedFilterBar(context)
              : AppContentPadding.top(context),
          bottom: AppContentPadding.bottom(context),
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
