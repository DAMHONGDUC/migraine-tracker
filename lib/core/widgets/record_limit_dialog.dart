import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_text_style.dart';

/// Says which free limit was just reached, before the paywall does any
/// selling. Pops true for "Unlock".
///
/// Every record limit goes through this — attacks, medications, reminders —
/// because the button that raised it never says "buy": it says "Add
/// medication", "Add reminder", or it is the log button. A purchase screen
/// appearing straight out of one of those reads as a bug rather than an
/// offer, so the limit is named first and the user chooses whether to hear
/// the pitch.
///
/// Shown through [NavigationUtils.toPaywallFromLimit], which owns the order.
/// A gate whose surface already announces itself as premium (a locked card, a
/// badged row) still goes straight to the paywall.
class RecordLimitDialog extends StatelessWidget {
  const RecordLimitDialog({
    required this.title,
    required this.body,
    super.key,
  });

  /// Already-localized: which limit, and what the free plan includes.
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return SdDialogV2(
      title: title,
      content: Text(body, style: AppTextStyle.bodyMedium),
      actions: <Widget>[
        SdButtonV2(
          variant: SdButtonVariantV2.text,
          onPressed: () => Navigator.of(context).pop(false),
          label: context.l10n.commonCancel,
        ),
        SdButtonV2(
          variant: SdButtonVariantV2.primary,
          onPressed: () => Navigator.of(context).pop(true),
          label: context.l10n.premiumUnlock,
        ),
      ],
    );
  }
}

extension RecordLimitDialogExt on RecordLimitDialog {
  Future<bool?> show(BuildContext context) =>
      showSdDialogV2<bool>(context, builder: (BuildContext _) => this);
}
