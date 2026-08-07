import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/medication_reminder.dart';

/// Says why the second reminder did not open the time picker, before the
/// paywall does the selling.
///
/// The button that raised this is still "Add reminder" — jumping straight to
/// a purchase screen from it reads as a bug, so the limit gets named first
/// and the user chooses whether to hear the pitch. Pops true for "Unlock".
class ReminderLimitDialog extends StatelessWidget {
  const ReminderLimitDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return SdDialogV2(
      title: l10n.reminderLimitTitle(MedicationReminder.freeLimit),
      content: Text(
        l10n.reminderLimitBody(MedicationReminder.freeLimit),
        style: AppTextStyle.bodyMedium,
      ),
      actions: <Widget>[
        SdButtonV2(
          variant: SdButtonVariantV2.text,
          onPressed: () => Navigator.of(context).pop(false),
          label: l10n.commonCancel,
        ),
        SdButtonV2(
          variant: SdButtonVariantV2.primary,
          onPressed: () => Navigator.of(context).pop(true),
          label: l10n.premiumUnlock,
        ),
      ],
    );
  }
}

extension ReminderLimitDialogExt on ReminderLimitDialog {
  Future<bool?> show(BuildContext context) =>
      showSdDialogV2<bool>(context, builder: (BuildContext _) => this);
}
