import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../features/alerts/domain/entities/alerts_settings.dart';
import '../../l10n/gen/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_icon_constant.dart';
import '../theme/app_icon_size.dart';
import '../theme/app_text_style.dart';

/// Everything the pressure alert is: whether it fires at all, and how far
/// pressure has to fall before it does.
///
/// The two used to be a switch on one screen and a slider dialog behind
/// another row, which left the threshold readable only by opening it. They
/// travel together because neither answers anything alone — a threshold with
/// the alert off is a number nothing reads, and the switch without the number
/// is a promise with no terms.
class AlertThresholdSheet extends StatefulWidget {
  const AlertThresholdSheet({
    required this.initial,
    required this.l10n,
    super.key,
  });

  final AlertsSettings initial;
  final AppLocalizations l10n;

  /// The tunable range, hard rule 7's "threshold is user-tunable" in numbers.
  static const double minHpa = 3;
  static const double maxHpa = 10;

  /// Whole hPa only: the forecast is not precise enough for halves, and a
  /// slider that stops on 6.5 invites a confidence the data cannot pay.
  static int get divisions => (maxHpa - minHpa).round();

  @override
  State<AlertThresholdSheet> createState() => _AlertThresholdSheetState();
}

class _AlertThresholdSheetState extends State<AlertThresholdSheet> {
  late bool _enabled = widget.initial.enabled;
  late double _value = widget.initial.thresholdHpa;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = widget.l10n;
    final String reading = l10n.onboardingThresholdValue(_value.round());

    return SdSheetContentV2(
      title: l10n.alertsScreenTitle,
      closeTooltip: l10n.commonClose,
      confirmTooltip: l10n.commonDone,
      // Both fields already have a value, even a fresh install's default.
      action: SdSheetActionV2.edit,
      onConfirm: () => Navigator.of(context).pop(
        AlertsSettings(enabled: _enabled, thresholdHpa: _value),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: SdIconV2(
              icon: AppIconConstant.reminderActive,
              size: AppIconSize.medium,
              color: context.colorScheme.onSurfaceVariant,
            ),
            title: Text(l10n.alertsToggleTitle, style: AppTextStyle.bodyLarge),
            value: _enabled,
            // Local until the tick: the sheet's own header is what commits, and a switch that registered the device on the way past would make the X a lie.
            onChanged: (bool value) => setState(() => _enabled = value),
          ),
          const SdDividerV2(),
          SizedBox(height: SdSpacingConstant.h12),
          Text(l10n.alertsThresholdTitle, style: AppTextStyle.bodyLarge),
          SizedBox(height: SdSpacingConstant.h8),
          SdValueSliderV2(
            label: reading,
            value: _value,
            min: AlertThresholdSheet.minHpa,
            max: AlertThresholdSheet.maxHpa,
            divisions: AlertThresholdSheet.divisions,
            // A bigger drop is worth warning more, so it reads redder as it climbs — the same ramp the onboarding page sets it on.
            accent: AppColors.intensity(_value.round()),
            onChanged: (double value) => setState(() => _value = value),
          ),
          Text(l10n.alertsSheetRange, style: AppTextStyle.bodySmall.secondary),
          SizedBox(height: SdSpacingConstant.h16),
          const SdDividerV2(),
          SizedBox(height: SdSpacingConstant.h16),
          Text(l10n.alertsSheetHowTitle, style: AppTextStyle.bodyLarge),
          SizedBox(height: SdSpacingConstant.h8),
          // The number means nothing without what it is measured against: a threshold is a delta over 24h, not the pressure itself.
          Text(l10n.alertsSheetFormula, style: AppTextStyle.bodySmall.secondary),
          SizedBox(height: SdSpacingConstant.h8),
          // Says the quiet part the server enforces, so dragging to 3 does not read as asking to be woken hourly.
          Text(l10n.alertsSheetLimit, style: AppTextStyle.bodySmall.secondary),
        ],
      ),
    );
  }
}

/// Sheets expose their opener as `.show(context)`, never a top-level `showX` (CLAUDE.md § Code style).
extension AlertThresholdSheetExt on AlertThresholdSheet {
  Future<AlertsSettings?> show(BuildContext context) =>
      showSdBottomSheetV2<AlertsSettings>(
        context,
        isScrollControlled: true,
        builder: (_) => this,
      );
}
