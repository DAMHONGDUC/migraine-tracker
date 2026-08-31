import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../l10n/gen/app_localizations.dart';

/// Asks for the account's display name, prefilled with [initial].
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
      // No label: the dialog is titled "Edit name" already.
      content: SdTextFieldV2(
        controller: _controller,
        autofocus: true,
        hint: l10n.accountNameHint,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
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
          label: l10n.commonSave,
        ),
      ],
    );
  }
}
