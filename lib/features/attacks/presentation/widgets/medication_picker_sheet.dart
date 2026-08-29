import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../medications/providers.dart';
import 'medication_grid.dart';
import 'medication_search_field.dart';

/// Corrects a logged attack's medication, with the same tile grid the log flow's third tap uses — including "No medication" and "Add a medication".
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

/// Sheets expose their opener as `.show(context)`, never a top-level `showX` (CLAUDE.md § Code style).
extension MedicationPickerSheetExt on MedicationPickerSheet {
  Future<({String? name})?> show(BuildContext context) =>
      showSdBottomSheetV2<({String? name})>(
        context,
        isScrollControlled: true,
        builder: (_) => this,
      );
}
