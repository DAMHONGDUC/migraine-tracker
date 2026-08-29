import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../l10n/gen/app_localizations.dart';
import '../theme/app_text_style.dart';

/// Picks how far pressure must fall before an alert fires, in hPa.
class AlertThresholdDialog extends StatefulWidget {
  const AlertThresholdDialog({
    required this.initial,
    required this.l10n,
    super.key,
  });

  final double initial;
  final AppLocalizations l10n;

  /// The tunable range, hard rule 7's "threshold is user-tunable" in numbers.
  static const double minHpa = 3;
  static const double maxHpa = 10;

  @override
  State<AlertThresholdDialog> createState() => _AlertThresholdDialogState();
}

class _AlertThresholdDialogState extends State<AlertThresholdDialog> {
  late double _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return SdDialogV2(
      title: widget.l10n.alertsThresholdTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            widget.l10n.onboardingThresholdValue(_value.round()),
            style: AppTextStyle.headlineMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colorScheme.primary,
            ),
          ),
          Slider(
            value: _value,
            min: AlertThresholdDialog.minHpa,
            max: AlertThresholdDialog.maxHpa,
            divisions: (AlertThresholdDialog.maxHpa -
                    AlertThresholdDialog.minHpa)
                .round(),
            onChanged: (double value) => setState(() => _value = value),
          ),
        ],
      ),
      actions: <Widget>[
        SdButtonV2(
          variant: SdButtonVariantV2.text,
          onPressed: () => Navigator.of(context).pop(),
          label: widget.l10n.commonCancel,
        ),
        SdButtonV2(
          variant: SdButtonVariantV2.primary,
          onPressed: () => Navigator.of(context).pop(_value),
          label: widget.l10n.detailsSave,
        ),
      ],
    );
  }
}

extension AlertThresholdDialogExt on AlertThresholdDialog {
  Future<double?> show(BuildContext context) =>
      showSdDialogV2<double>(context, builder: (BuildContext _) => this);
}
