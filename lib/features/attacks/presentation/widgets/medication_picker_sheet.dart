import 'package:flutter/material.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/constants/app_content_padding.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_sheet_content.dart';
import '../../../../core/widgets/app_sheet_header.dart';
import 'medication_grid.dart';
import 'medication_search_field.dart';

/// Corrects a logged attack's medication, with the same tile grid the log
/// flow's third tap uses — including "No medication" and "Add a medication".
///
/// A tap only moves the highlight; the tick applies it and the X leaves the
/// attack as it was. Adding a medication also highlights it, so the new name
/// is the pick waiting to be confirmed.
///
/// The name search floats at the bottom, over the grid rather than above it:
/// the tiles scroll behind it, and it sits in the slot the thumb is already
/// resting on — the shell's nav pill slot — rising above the keyboard when one
/// is up.
///
/// Pops the pick wrapped in a record, because the pick itself can be null:
/// `(name: null)` is "no medication", a null result is a dismissal.
class MedicationPickerSheet extends StatefulWidget {
  const MedicationPickerSheet({required this.selectedName, super.key});

  final String? selectedName;

  @override
  State<MedicationPickerSheet> createState() => _MedicationPickerSheetState();
}

class _MedicationPickerSheetState extends State<MedicationPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  late String? _selectedName = widget.selectedName;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearQuery() {
    _searchController.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    // What the grid adds so its last row can scroll clear of the bar: the bar
    // itself plus the gap above it. Everything below the bar — keyboard, home
    // indicator, the gap under it — is already in AppSheetContent's own
    // bottom padding.
    final double barClearance =
        AppContentPadding.floatingBarHeight + AppContentPadding.bottomGap;
    // A sheet is a route, not a screen, so it clears the keyboard and the home
    // indicator itself (same rule as AppSheetContent's own last row).
    final double barBottom =
        MediaQuery.viewInsetsOf(context).bottom +
        MediaQuery.paddingOf(context).bottom +
        AppContentPadding.bottomGap;

    return Stack(
      children: <Widget>[
        AppSheetContent(
          title: context.l10n.logMedicationTitle,
          action: AppSheetAction.edit,
          onConfirm: () => Navigator.of(context).pop((name: _selectedName)),
          child: Padding(
            padding: EdgeInsets.only(bottom: barClearance),
            child: MedicationGrid(
              // Editing an attack there is always a pick already: it either
              // names a medication or it says none was taken.
              hasSelection: true,
              selectedName: _selectedName,
              onSelected: (String? name) =>
                  setState(() => _selectedName = name),
              query: _query,
            ),
          ),
        ),
        Positioned(
          left: AppSpacingConstant.w24,
          right: AppSpacingConstant.w24,
          bottom: barBottom,
          child: MedicationSearchField(
            controller: _searchController,
            hasText: _query.trim().isNotEmpty,
            onChanged: (String value) => setState(() => _query = value),
            onClear: _clearQuery,
          ),
        ),
      ],
    );
  }
}

/// Sheets expose their opener as `.show(context)`, never a top-level
/// `showX` (CLAUDE.md § Code style).
extension MedicationPickerSheetExt on MedicationPickerSheet {
  Future<({String? name})?> show(BuildContext context) =>
      showAppBottomSheet<({String? name})>(
        context,
        isScrollControlled: true,
        builder: (_) => this,
      );
}
