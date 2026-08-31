import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';

/// Corrects a logged attack's intensity.
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

    return SdSheetContentV2(
      title: context.l10n.logIntensityTitle,
      closeTooltip: context.l10n.commonClose,
      confirmLabel: context.l10n.commonUpdate,
      onConfirm: () => Navigator.of(context).pop(rounded),
      child: SdValueSliderV2(
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

/// Sheets expose their opener as `.show(context)`, never a top-level `showX` (CLAUDE.md § Code style).
extension IntensitySheetExt on IntensitySheet {
  Future<int?> show(BuildContext context) => showSdBottomSheetV2<int>(
    context,
    isScrollControlled: true,
    builder: (_) => this,
  );
}
