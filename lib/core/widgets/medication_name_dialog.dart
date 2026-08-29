import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../extensions/context_extensions.dart';

/// Prompts for a brand-new medication's name.
class MedicationNameDialog extends StatefulWidget {
  const MedicationNameDialog({super.key});

  @override
  State<MedicationNameDialog> createState() => _MedicationNameDialogState();
}

/// Presents the dialog and returns the trimmed name, or null when cancelled (see CLAUDE.md § Code style, "Bottom sheets and dialogs").
extension MedicationNameDialogExt on MedicationNameDialog {
  Future<String?> show(BuildContext context) =>
      showSdDialogV2<String>(context, builder: (_) => this);
}

class _MedicationNameDialogState extends State<MedicationNameDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String value) {
    final trimmed = value.trim();
    Navigator.of(context).pop(trimmed.isEmpty ? null : trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SdDialogV2(
      title: l10n.logAddMedication,
      // No label: the dialog's own title already says what is being named.
      content: SdTextFieldV2(
        controller: _controller,
        autofocus: true,
        hint: l10n.logMedicationNameHint,
        textInputAction: TextInputAction.done,
        onSubmitted: _submit,
      ),
      actions: [
        SdButtonV2(
          variant: SdButtonVariantV2.text,
          onPressed: () => Navigator.of(context).pop(),
          label: l10n.commonCancel,
        ),
        SdButtonV2(
          variant: SdButtonVariantV2.primary,
          onPressed: () => _submit(_controller.text),
          label: l10n.commonAdd,
        ),
      ],
    );
  }
}
