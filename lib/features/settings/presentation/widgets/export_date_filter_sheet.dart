import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/app_sheet_content.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/export_date_filter.dart';
import 'date_range_calendar.dart';

/// Which end of the window the calendar is currently setting.
enum _Bound { from, to }

/// Picks the date window the export history is filtered to.
///
/// Two tiles say what the window is; tapping one aims the calendar at that end.
/// Picking a "from" date hands the calendar straight to the "to" tile, so the
/// common case is two taps and the tick. The footer clears the filter, and the
/// X leaves whatever was already applied alone.
///
/// Pops the picked window (an inactive one means "cleared"), or null when
/// dismissed. Show it with `ExportDateFilterSheet(initial: ...).show(context)`.
class ExportDateFilterSheet extends StatefulWidget {
  const ExportDateFilterSheet({required this.initial, super.key});

  /// Oldest day the calendar will go back to. Nothing older can exist — an
  /// export is created on the device, and the app is younger than this.
  static final DateTime firstSelectableDate = DateTime(2025);

  /// The window currently applied, so re-opening the sheet starts where the
  /// user left off.
  final ExportDateFilter initial;

  @override
  State<ExportDateFilterSheet> createState() => _ExportDateFilterSheetState();
}

class _ExportDateFilterSheetState extends State<ExportDateFilterSheet> {
  late DateTime? _from = widget.initial.from;
  late DateTime? _to = widget.initial.to;
  _Bound _editing = _Bound.from;

  void _pick(DateTime date) {
    setState(() {
      if (_editing == _Bound.from) {
        _from = date;
        // A start later than the end the user already picked would leave an
        // inverted window, so that end goes back to "any date".
        if (_to != null && date.isAfter(_to!)) {
          _to = null;
        }
        // Straight on to the other end: picking a start almost always means
        // an end is coming next.
        _editing = _Bound.to;
        return;
      }
      _to = date;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final DateTime today = DateTime.now();
    final bool editingTo = _editing == _Bound.to;
    final DateTime? active = editingTo ? _to : _from;
    // The end of the window can never be older than its start, so days before
    // it are greyed out rather than picked and silently swapped.
    final DateTime firstDate = editingTo && _from != null
        ? _from!
        : ExportDateFilterSheet.firstSelectableDate;

    return AppSheetContent(
      title: l10n.exportFilterTitle,
      onConfirm: () => Navigator.of(
        context,
      ).pop(ExportDateFilter.ordered(from: _from, to: _to)),
      footer: AppButton(
        variant: AppButtonVariant.text,
        label: l10n.exportFilterClear,
        onPressed: () => Navigator.of(context).pop(const ExportDateFilter()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _BoundTile(
                  label: l10n.exportFilterFromLabel,
                  date: _from,
                  selected: _editing == _Bound.from,
                  onTap: () => setState(() => _editing = _Bound.from),
                ),
              ),
              SizedBox(width: AppSpacingConstant.w8),
              Expanded(
                child: _BoundTile(
                  label: l10n.exportFilterToLabel,
                  date: _to,
                  selected: _editing == _Bound.to,
                  onTap: () => setState(() => _editing = _Bound.to),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacingConstant.h8),
          // Keyed on the bound, so switching ends re-centres the calendar on
          // that end's own month instead of staying where the other one was.
          DateRangeCalendar(
            key: ValueKey<_Bound>(_editing),
            from: _from,
            to: _to,
            initialMonth: active ?? today,
            firstDate: firstDate,
            // An export cannot have been made tomorrow.
            lastDate: today,
            onDateSelected: _pick,
          ),
        ],
      ),
    );
  }
}

/// One end of the window: its name, the day picked for it, and whether the
/// calendar is currently aimed at it. Wears the option-tile language of the
/// log flow's grids — one step above the sheet, primary-tinted when active.
class _BoundTile extends StatelessWidget {
  const _BoundTile({
    required this.label,
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String value = date == null
        ? context.l10n.exportFilterAnyDate
        : DateFormat.yMMMd(context.l10n.localeName).format(date!);

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacingConstant.r16),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacingConstant.w14,
            vertical: AppSpacingConstant.h12,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.14)
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppSpacingConstant.r16),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.textSecondary.withValues(alpha: 0.2),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: AppTextStyle.bodySmall.secondary),
              SizedBox(height: AppSpacingConstant.h2),
              Text(value, style: AppTextStyle.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sheets expose their opener as `.show(context)`, never a top-level
/// `showX` (CLAUDE.md § Code style).
extension ExportDateFilterSheetExt on ExportDateFilterSheet {
  Future<ExportDateFilter?> show(BuildContext context) =>
      showAppBottomSheet<ExportDateFilter>(
        context,
        isScrollControlled: true,
        builder: (_) => this,
      );
}
