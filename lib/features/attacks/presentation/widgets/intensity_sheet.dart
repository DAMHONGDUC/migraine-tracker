import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_sheet_content.dart';
import '../../../../core/widgets/app_value_slider.dart';

/// Corrects a logged attack's intensity. Unlike the location and medication
/// pickers, a drag is not a decision — the value only lands when Save is
/// tapped, so a stray drag on the way to dismissing costs nothing.
///
/// Pops the new intensity, or null when dismissed.
class IntensitySheet extends StatefulWidget {
  const IntensitySheet({required this.initial, super.key});

  final int initial;

  @override
  State<IntensitySheet> createState() => _IntensitySheetState();
}

class _IntensitySheetState extends State<IntensitySheet> {
  late double _value = widget.initial.toDouble();

  @override
  Widget build(BuildContext context) {
    final int rounded = _value.round();

    return AppSheetContent(
      title: context.l10n.logIntensityTitle,
      footer: AppButton(
        variant: AppButtonVariant.primary,
        onPressed: () => Navigator.of(context).pop(rounded),
        label: context.l10n.detailsSave,
      ),
      child: AppValueSlider(
        label: '$rounded',
        value: _value,
        min: 1,
        max: 10,
        divisions: 9,
        accent: AppColors.intensity(rounded),
        onChanged: (double v) => setState(() => _value = v),
      ),
    );
  }
}

/// Sheets expose their opener as `.show(context)`, never a top-level
/// `showX` (CLAUDE.md § Code style).
extension IntensitySheetExt on IntensitySheet {
  Future<int?> show(BuildContext context) => showAppBottomSheet<int>(
    context,
    isScrollControlled: true,
    builder: (_) => this,
  );
}
