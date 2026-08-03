import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';

/// Name-search field that filters a [MedicationGrid].
///
/// The app's one field ([SdTextFieldV2]) with a magnifier in front and no
/// label — the glyph says what it is, and a "Search" line above it would
/// only push the grid further down.
///
/// Shared by both places the grid appears — above it in the log flow's third
/// tap ([MedicationStep]), and floating at the bottom of the attack detail's
/// medication sheet ([MedicationPickerSheet]).
class MedicationSearchField extends StatelessWidget {
  const MedicationSearchField({
    required this.controller,
    required this.hasText,
    required this.onChanged,
    required this.onClear,
    super.key,
  });

  final TextEditingController controller;

  /// Whether to offer the clear button — the caller already tracks the query.
  final bool hasText;

  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SdTextFieldV2(
      controller: controller,
      hint: context.l10n.medicationsSearchHint,
      prefixIcon: Icons.search,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      suffix: hasText
          ? IconButton(
              icon: SdIconV2(icon: Icons.close, size: SdSpacingConstant.r18),
              tooltip: context.l10n.medicationsSearchClear,
              onPressed: onClear,
            )
          : null,
    );
  }
}
