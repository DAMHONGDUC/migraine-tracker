import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';

/// Prompts for a medication's name — adding a new one, or renaming an
/// existing one when [initial] is passed (prefills the field and swaps the
/// title/action to "Rename"/"Save"). Present it with
/// `MedicationNameDialog(...).show(context)` — see [MedicationNameDialogExt] —
/// which returns the trimmed name, or null if cancelled or left blank.
///
/// Shared by the log flow's medication step and the medications tab so both
/// "add" surfaces (and the tab's "rename") look and behave identically.
///
/// A [StatefulWidget] so the [TextEditingController] is owned by [State]
/// and disposed by the framework once this widget actually leaves the tree
/// — NOT by the caller right after the picked value comes back. [AppDialog]
/// closes with a 220ms fade+scale (`showAppDialog`), so the field is still
/// mounted and painting for that whole reverse transition even though the
/// awaited `Future` already resolved; disposing the controller as soon as
/// the await returns (the log flow's original inline version of this
/// dialog did exactly that) tears it down out from under the still-visible
/// [TextField] and crashes with "used after being disposed".
class MedicationNameDialog extends StatefulWidget {
  const MedicationNameDialog({this.initial, super.key});

  final String? initial;

  @override
  State<MedicationNameDialog> createState() => _MedicationNameDialogState();
}

/// Presents the dialog and returns the trimmed name, or null when cancelled
/// (see CLAUDE.md § Code style, "Bottom sheets and dialogs").
extension MedicationNameDialogExt on MedicationNameDialog {
  Future<String?> show(BuildContext context) =>
      showAppDialog<String>(context, builder: (_) => this);
}

class _MedicationNameDialogState extends State<MedicationNameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

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
    final isRename = widget.initial != null;
    return AppDialog(
      title: isRename ? l10n.medicationsRename : l10n.logAddMedication,
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: l10n.logMedicationNameHint),
        onSubmitted: _submit,
      ),
      actions: [
        AppButton.text(
          onPressed: () => Navigator.of(context).pop(),
          label: l10n.commonCancel,
        ),
        AppButton.primary(
          onPressed: () => _submit(_controller.text),
          label: isRename ? l10n.detailsSave : l10n.commonAdd,
        ),
      ],
    );
  }
}
