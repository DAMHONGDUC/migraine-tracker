import 'package:flutter/material.dart';
import 'package:system_design/v2/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';

/// Rounded name-search field that filters a [MedicationGrid]: calm surface
/// tile language (matching the option tiles it filters) rather than a bare
/// underlined field.
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
    final l10n = context.l10n;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(SdSpacingV2.r16),
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
        prefixIcon: SdIconV2(
          icon: Icons.search,
          color: AppColors.textSecondary,
          size: SdSpacingV2.r24,
        ),
        suffixIcon: hasText
            ? IconButton(
                icon: SdIconV2(icon: Icons.close, size: SdSpacingV2.r18),
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
