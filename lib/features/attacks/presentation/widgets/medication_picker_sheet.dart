import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../medications/providers.dart';
import 'medication_grid.dart';
import 'medication_search_field.dart';

/// Corrects a logged attack's medication, with the same tile grid the log
/// flow's third tap uses — including "No medication" and "Add a medication".
///
/// A tap only moves the highlight; the tick applies it and the X leaves the
/// attack as it was. Adding a medication also highlights it, so the new name
/// is the pick waiting to be confirmed.
///
/// **The search is the first thing in the list, not a bar floating over it**
/// (owner's rule) — the same order as `MedicationStep`, which this sheet is
/// otherwise a copy of. It used to sit pinned at the bottom in the shell's
/// nav-pill slot with the tiles scrolling behind it, which put it over the
/// answers it was meant to narrow and left the grid padding a hole for it.
/// `SdSheetContentV2` scrolls its child under a pinned header, so being first
/// in that child is all it takes.
///
/// Only worth a search box once there is something to search, so it appears
/// with the first saved medication — again as in the step.
///
/// Pops the pick wrapped in a record, because the pick itself can be null:
/// `(name: null)` is "no medication", a null result is a dismissal.
class MedicationPickerSheet extends ConsumerStatefulWidget {
  const MedicationPickerSheet({required this.selectedName, super.key});

  final String? selectedName;

  @override
  ConsumerState<MedicationPickerSheet> createState() =>
      _MedicationPickerSheetState();
}

class _MedicationPickerSheetState extends ConsumerState<MedicationPickerSheet> {
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
    final bool hasMedications = ref
        .watch(medicationsByRecentUseProvider)
        .isNotEmpty;

    return SdSheetContentV2(
      title: context.l10n.logMedicationTitle,
      closeTooltip: context.l10n.commonClose,
      confirmTooltip: context.l10n.commonDone,
      action: SdSheetActionV2.edit,
      onConfirm: () => Navigator.of(context).pop((name: _selectedName)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (hasMedications) ...<Widget>[
            MedicationSearchField(
              controller: _searchController,
              hasText: _query.trim().isNotEmpty,
              onChanged: (String value) => setState(() => _query = value),
              onClear: _clearQuery,
            ),
            SdVerticalSpacingV2(height: SdSpacingConstant.h12),
          ],
          MedicationGrid(
            // Editing an attack: there's always a pick already made.
            hasSelection: true,
            selectedName: _selectedName,
            onSelected: (String? name) => setState(() => _selectedName = name),
            query: _query,
          ),
        ],
      ),
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
