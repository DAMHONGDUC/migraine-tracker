import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/v2/index.dart';

import '../../../medications/providers.dart';
import 'medication_grid.dart';
import 'medication_search_field.dart';

/// Third tap: which medication was taken (or none). Picking only
/// highlights — the app bar's Next confirms, persists the attack and
/// advances to the saved confirmation.
///
/// The answers are one two-column grid ([MedicationGrid], shared with the
/// attack detail's edit sheet). With no medications saved the grid is just
/// its two fixed cells, which reads as its own empty state.
///
/// A name-search field sits above it (once there's at least one saved
/// medication) and filters the medication tiles. The grid scrolls behind
/// the floating step bar — the log screen reserves no bottom space for it
/// and passes the inset down as [scrollBottomInset].
class MedicationStep extends ConsumerStatefulWidget {
  const MedicationStep({
    required this.hasSelection,
    required this.selectedName,
    required this.onSelected,
    required this.scrollBottomInset,
    super.key,
  });

  /// Whether *any* pick has been made yet — distinguishes "nothing picked"
  /// from [selectedName] being null because "No medication" was picked.
  final bool hasSelection;
  final String? selectedName;

  /// Called with the medication name, or null for "no medication".
  final ValueChanged<String?> onSelected;

  /// Bottom scroll padding so the grid's last row clears the floating step bar
  /// it now scrolls behind (the log screen no longer reserves this space).
  final double scrollBottomInset;

  @override
  ConsumerState<MedicationStep> createState() => _MedicationStepState();
}

class _MedicationStepState extends ConsumerState<MedicationStep> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) => setState(() => _query = value);

  void _clearQuery() {
    _searchController.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final bool hasMedications = ref
        .watch(medicationsByRecentUseProvider)
        .isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Only worth a search box once there's something to search.
        if (hasMedications)
          Padding(
            padding: EdgeInsets.fromLTRB(
              SdSpacingV2.w24,
              SdSpacingV2.h8,
              SdSpacingV2.w24,
              SdSpacingV2.h8,
            ),
            child: MedicationSearchField(
              controller: _searchController,
              hasText: _query.trim().isNotEmpty,
              onChanged: _onQueryChanged,
              onClear: _clearQuery,
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              SdSpacingV2.w24,
              SdSpacingV2.h8,
              SdSpacingV2.w24,
              widget.scrollBottomInset + SdSpacingV2.h16,
            ),
            // Calm and predictable over platform-native bounce: a short list
            // must not rubber-band mid-attack.
            physics: const ClampingScrollPhysics(),
            child: MedicationGrid(
              hasSelection: widget.hasSelection,
              selectedName: widget.selectedName,
              onSelected: widget.onSelected,
              query: _query,
            ),
          ),
        ),
      ],
    );
  }
}
