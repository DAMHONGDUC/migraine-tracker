import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_icon_size.dart';

/// Name-search field that filters a [MedicationGrid].
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
      prefixIcon: AppIconConstant.search,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      suffix: hasText
          ? IconButton(
              icon: SdIconV2(icon: AppIconConstant.close, size: AppIconSize.small),
              tooltip: context.l10n.medicationsSearchClear,
              onPressed: onClear,
            )
          : null,
    );
  }
}
