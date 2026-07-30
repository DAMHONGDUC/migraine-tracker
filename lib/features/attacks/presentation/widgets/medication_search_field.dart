import 'package:flutter/material.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/app_icon.dart';

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
