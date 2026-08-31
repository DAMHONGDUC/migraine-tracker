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

  /// The pressure the worked example starts from — 1013 hPa, the standard
  /// atmosphere. A round, textbook number on purpose: an invented reading
  /// close to a real one would be taken for the user's own, and this one is
  /// recognisable as the figure every barometer is calibrated against.
  static const int exampleHpa = 1013;

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
      // Both fields already have a value, even a fresh install's default.
      confirmLabel: l10n.commonUpdate,
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
          SizedBox(height: SdSpacingConstant.h12),
          // The sentence above states the rule; this states one case of it, in numbers that move with the slider — drag it and the arrival pressure changes, which is the whole lesson in one gesture.
          _Example(l10n: l10n, thresholdHpa: _value.round()),
          SizedBox(height: SdSpacingConstant.h12),
          // Says the quiet part the server enforces, so dragging to 3 does not read as asking to be woken hourly.
          Text(l10n.alertsSheetLimit, style: AppTextStyle.bodySmall.secondary),
        ],
      ),
    );
  }
}

/// The rule as one worked case: the pressure now, the drop the user asked to
/// hear about, and the number the forecast has to reach.
class _Example extends StatelessWidget {
  const _Example({required this.l10n, required this.thresholdHpa});

  final AppLocalizations l10n;

  /// Already rounded — the slider only stops on whole numbers.
  final int thresholdHpa;

  @override
  Widget build(BuildContext context) {
    final int alertAt = AlertThresholdSheet.exampleHpa - thresholdHpa;

    return Container(
      padding: EdgeInsets.all(SdSpacingConstant.w12),
      decoration: BoxDecoration(
        // Elevated, not the sheet's own colour: a worked example is a thing sitting ON the sheet, and on `surfaceModal` it would disappear into it.
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(SdSpacingConstant.r12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.alertsSheetExampleTitle,
            style: AppTextStyle.labelSmall.secondary,
          ),
          SizedBox(height: SdSpacingConstant.h8),
          _Row(
            label: l10n.alertsSheetExampleNow,
            value: l10n.onboardingThresholdValue(
              AlertThresholdSheet.exampleHpa,
            ),
          ),
          SizedBox(height: SdSpacingConstant.h4),
          _Row(
            label: l10n.alertsSheetExampleThreshold,
            value: l10n.onboardingThresholdValue(thresholdHpa),
            // The one number on this block the user controls, in the colour the slider above already gave it.
            valueColor: AppColors.intensity(thresholdHpa),
          ),
          SizedBox(height: SdSpacingConstant.h8),
          const SdDividerV2(),
          SizedBox(height: SdSpacingConstant.h8),
          Text(
            l10n.alertsSheetExampleResult(
              l10n.onboardingThresholdValue(alertAt),
            ),
            style: AppTextStyle.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// One line of the example: what it is on the left, what it reads on the right.
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(label, style: AppTextStyle.bodySmall.secondary),
        ),
        Text(
          value,
          style: valueColor == null
              ? AppTextStyle.bodySmall.w600
              : AppTextStyle.bodySmall.w600.copyWith(color: valueColor),
        ),
      ],
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
