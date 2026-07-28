import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_sheet_content.dart';
import 'medication_grid.dart';

/// Corrects a logged attack's medication, with the same tile grid the log
/// flow's third tap uses — including "No medication" and "Add a medication".
///
/// A tap only moves the highlight; the tick applies it and the X leaves the
/// attack as it was. Adding a medication also highlights it, so the new name
/// is the pick waiting to be confirmed.
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
  late String? _selectedName = widget.selectedName;

  @override
  Widget build(BuildContext context) {
    return AppSheetContent(
      title: context.l10n.logMedicationTitle,
      onConfirm: () => Navigator.of(context).pop((name: _selectedName)),
      child: MedicationGrid(
        // Editing an attack there is always a pick already: it either names a
        // medication or it says none was taken.
        hasSelection: true,
        selectedName: _selectedName,
        onSelected: (String? name) => setState(() => _selectedName = name),
      ),
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
