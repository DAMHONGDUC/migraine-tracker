import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../medications/providers.dart';
import 'medication_grid.dart';

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
              AppSpacingConstant.w24,
              AppSpacingConstant.h8,
              AppSpacingConstant.w24,
              AppSpacingConstant.h8,
            ),
            child: _SearchField(
              controller: _searchController,
              hasText: _query.trim().isNotEmpty,
              onChanged: _onQueryChanged,
              onClear: _clearQuery,
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacingConstant.w24,
              AppSpacingConstant.h8,
              AppSpacingConstant.w24,
              widget.scrollBottomInset + AppSpacingConstant.h16,
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

/// Rounded name-search field above the medication grid — calm surface tile
/// language (matching the option tiles) rather than a bare underlined field.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hasText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool hasText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacingConstant.r16),
      borderSide: BorderSide(color: color),
    );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textCapitalization: TextCapitalization.sentences,
      style: AppTextStyle.titleSmall,
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        // Same fill as the tiles it filters (MedicationGrid).
        fillColor: AppColors.surfaceElevated,
        hintText: l10n.medicationsSearchHint,
        hintStyle: AppTextStyle.titleSmall.secondary,
        prefixIcon: AppIcon(
          Icons.search,
          color: AppColors.textSecondary,
          size: AppSpacingConstant.r24,
        ),
        suffixIcon: hasText
            ? IconButton(
                icon: AppIcon(Icons.close, size: AppSpacingConstant.r18),
                color: AppColors.textSecondary,
                tooltip: l10n.medicationsSearchClear,
                onPressed: onClear,
              )
            : null,
        border: border(AppColors.textSecondary.withValues(alpha: 0.2)),
        enabledBorder: border(AppColors.textSecondary.withValues(alpha: 0.2)),
        focusedBorder: border(AppColors.primary),
      ),
    );
  }
}
