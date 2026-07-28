import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_sheet_content.dart';
import 'medication_grid.dart';

/// Corrects a logged attack's medication, with the same tile grid the log
/// flow's third tap uses — including "No medication" and "Add a
/// medication". Picking IS the answer, so there is no Save.
///
/// Pops the pick wrapped in a record, because the pick itself can be null:
/// `(name: null)` is "no medication", a null result is a dismissal.
class MedicationPickerSheet extends StatelessWidget {
  const MedicationPickerSheet({required this.selectedName, super.key});

  final String? selectedName;

  @override
  Widget build(BuildContext context) {
    return AppSheetContent(
      title: context.l10n.logMedicationTitle,
      child: MedicationGrid(
        // Editing an attack there is always a pick already: it either names
        // a medication or it says none was taken.
        hasSelection: true,
        selectedName: selectedName,
        onSelected: (String? name) => Navigator.of(context).pop((name: name)),
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
