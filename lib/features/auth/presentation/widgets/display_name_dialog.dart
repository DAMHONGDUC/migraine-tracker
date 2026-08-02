import 'package:flutter/material.dart';
import 'package:system_design/v2/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../l10n/gen/app_localizations.dart';

/// Asks for the account's display name, prefilled with [initial]. Returns
/// the trimmed name, or null when cancelled or left blank. Present it with
/// `DisplayNameDialog(...).show(context)` — see [DisplayNameDialogExt].
///
/// A [StatefulWidget] so the [TextEditingController] outlives the awaited
/// result: [SdDialogV2] fades out over 220ms and the field is still painting
/// for all of it (see [MedicationNameDialog] for the crash this avoids).
class DisplayNameDialog extends StatefulWidget {
  const DisplayNameDialog({this.initial, super.key});

  final String? initial;

  @override
  State<DisplayNameDialog> createState() => _DisplayNameDialogState();
}

extension DisplayNameDialogExt on DisplayNameDialog {
  Future<String?> show(BuildContext context) =>
      showSdDialogV2<String>(context, builder: (_) => this);
}

class _DisplayNameDialogState extends State<DisplayNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String value) {
    final String trimmed = value.trim();

    Navigator.of(context).pop(trimmed.isEmpty ? null : trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return SdDialogV2(
      title: l10n.accountEditName,
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(hintText: l10n.accountNameHint),
        onSubmitted: _submit,
      ),
      actions: <Widget>[
        SdButtonV2(
          variant: SdButtonVariantV2.text,
          onPressed: () => Navigator.of(context).pop(),
          label: l10n.commonCancel,
        ),
        SdButtonV2(
          variant: SdButtonVariantV2.primary,
          onPressed: () => _submit(_controller.text),
          label: l10n.detailsSave,
        ),
      ],
    );
  }
}
