import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../domain/enums/exertion_level.dart';
import 'exertion_level_picker.dart';

/// Corrects a logged attack's exertion, with the same tiles the log flow's fourth step uses.
class ExertionPickerSheet extends StatefulWidget {
  const ExertionPickerSheet({required this.selected, super.key});

  final ExertionLevel? selected;

  @override
  State<ExertionPickerSheet> createState() => _ExertionPickerSheetState();
}

class _ExertionPickerSheetState extends State<ExertionPickerSheet> {
  // Attacks logged before the step existed carry null; editing one starts from the same default the flow would have given it.
  late ExertionLevel _selected = widget.selected ?? ExertionLevel.none;

  @override
  Widget build(BuildContext context) {
    return SdSheetContentV2(
      title: context.l10n.logExertionTitle,
      closeTooltip: context.l10n.commonClose,
      confirmLabel: context.l10n.commonUpdate,
      onConfirm: () => Navigator.of(context).pop(_selected),
      child: ExertionLevelPicker(
        selected: _selected,
        onSelected: (ExertionLevel level) => setState(() => _selected = level),
      ),
    );
  }
}

/// Sheets expose their opener as `.show(context)`, never a top-level `showX` (CLAUDE.md § Code style).
extension ExertionPickerSheetExt on ExertionPickerSheet {
  Future<ExertionLevel?> show(BuildContext context) =>
      showSdBottomSheetV2<ExertionLevel>(
        context,
        isScrollControlled: true,
        builder: (_) => this,
      );
}
