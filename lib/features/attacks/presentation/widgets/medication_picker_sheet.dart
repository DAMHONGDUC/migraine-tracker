import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
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
    // - Grid clears the bar plus the gap above it, so its last row scrolls free.
    // - Rest (keyboard, home indicator) already in SdSheetContentV2's padding.
    final double barClearance =
        SdContentPaddingV2.floatingBarHeight + SdContentPaddingV2.bottomGap;
    // Sheet is a route, not a screen — it clears keyboard/home indicator itself.
    final double barBottom =
        MediaQuery.viewInsetsOf(context).bottom +
        MediaQuery.paddingOf(context).bottom +
        SdContentPaddingV2.bottomGap;

    return Stack(
      children: <Widget>[
        SdSheetContentV2(
          title: context.l10n.logMedicationTitle,
          closeTooltip: context.l10n.commonClose,
          confirmTooltip: context.l10n.commonDone,
          action: SdSheetActionV2.edit,
          onConfirm: () => Navigator.of(context).pop((name: _selectedName)),
          child: Padding(
            padding: EdgeInsets.only(bottom: barClearance),
            child: MedicationGrid(
              // Editing an attack: there's always a pick already made.
              hasSelection: true,
              selectedName: _selectedName,
              onSelected: (String? name) =>
                  setState(() => _selectedName = name),
              query: _query,
            ),
          ),
        ),
        Positioned(
          left: SdContentPaddingV2.horizontal,
          right: SdContentPaddingV2.horizontal,
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
      showSdBottomSheetV2<({String? name})>(
        context,
        isScrollControlled: true,
        builder: (_) => this,
      );
}
