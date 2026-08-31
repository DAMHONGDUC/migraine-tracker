import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../features/alerts/domain/entities/alert_threshold_range.dart';
import '../../features/alerts/domain/entities/alerts_settings.dart';
import '../../features/alerts/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../extensions/context_extensions.dart';
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

  /// Clamped: a threshold stored under a different range would be handed to
  /// the slider outside its bounds, which throws rather than degrading.
  late double _value = AlertThresholdRange.clamp(widget.initial.thresholdHpa);

  late final TextEditingController _field = TextEditingController(
    text: '${_value.round()}',
  );

  /// The line under the box, or null while the number is one the range takes.
  /// The slider keeps the last good value, so there is always something to go
  /// back to.
  String? _error;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  /// Typed. The slider follows valid input and ignores the rest.
  void _onTyped(String text) {
    final double? parsed = AlertThresholdRange.parse(text);

    setState(() {
      _error = parsed == null
          ? widget.l10n.alertsThresholdInvalid(
              AlertThresholdRange.min.round(),
              AlertThresholdRange.max.round(),
            )
          : null;
      if (parsed != null) _value = parsed;
    });
  }

  /// Dragged. The box follows, cursor at the end so a keyboard left open does
  /// not park it mid-number.
  void _onDragged(double value) {
    setState(() {
      _value = value;
      _error = null;
      _field.value = TextEditingValue(
        text: '${value.round()}',
        selection: TextSelection.collapsed(offset: '${value.round()}'.length),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = widget.l10n;
    final String reading = l10n.onboardingThresholdValue(_value.round());

    return SdSheetContentV2(
      title: l10n.alertsScreenTitle,
      closeTooltip: l10n.commonClose,
      // Everything here already has a value, even a fresh install's default.
      confirmLabel: l10n.commonUpdate,
      // Null while the box is refused: SdSheetContentV2 disables the button rather than hiding it, so nothing moves and the line under the box is what explains it.
      onConfirm: _error != null
          ? null
          : () => Navigator.of(context).pop(
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
            // Local until the button at the bottom: a switch that registered the device on the way past would make the X a lie.
            onChanged: (bool value) => setState(() => _enabled = value),
          ),
          const SdDividerV2(),
          SizedBox(height: SdSpacingConstant.h12),
          Text(l10n.alertsThresholdTitle, style: AppTextStyle.bodyLarge),
          SizedBox(height: SdSpacingConstant.h8),
          SdValueSliderV2(
            label: reading,
            value: _value,
            min: AlertThresholdRange.min,
            max: AlertThresholdRange.max,
            divisions: AlertThresholdRange.divisions,
            // A bigger drop is worth warning more, so it reads redder as it climbs — the same ramp the onboarding page sets it on.
            accent: AppColors.intensity(_value.round()),
            onChanged: _onDragged,
            // Typed as well as dragged: 18 stops is a lot to hit with a thumb, and a field is the only way in for someone who cannot drag at all.
            readout: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox(
                      width: SdSpacingConstant.w160,
                      child: _NumberField(
                        controller: _field,
                        onChanged: _onTyped,
                      ),
                    ),
                    SizedBox(width: SdSpacingConstant.w8),
                    // Outside the box, not a suffix inside it: the unit never changes, and inside it takes width from the digits that do.
                    Text(
                      l10n.commonHpaUnit,
                      style: AppTextStyle.bodyMedium.secondary,
                    ),
                  ],
                ),
                if (_error != null) ...<Widget>[
                  SizedBox(height: SdSpacingConstant.h8),
                  Text(
                    _error!,
                    style: AppTextStyle.bodySmall.copyWith(
                      color: context.colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
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

/// The threshold box: a whole number, nothing else typeable.
///
/// No label above it — "Alert threshold" is the heading two lines up, and a
/// second copy of it under the same heading is a line of nothing.
class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SdTextFieldV2(
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      // Digits only, so a decimal point cannot be typed at all — the range refuses halves and an error is a worse way to say so than a key that does nothing.
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
      ],
      // No errorText here: the message sits under the box AND its unit, which are one control between them.
      onChanged: onChanged,
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

/// Opening the sheet and applying what it comes back with, in one place.
///
/// Four doors reach it now — the Settings row, the dashboard shortcut, the
/// alerts section and the pressure card's own row — and the two steps have to
/// stay together: a sheet opened without the apply silently discards the
/// answer, which looks exactly like a save that worked.
///
/// A static holder rather than a top-level function, because `showX()` at
/// file scope is what the sheet rules forbid; this is not a presenter anyway
/// — [AlertThresholdSheetExt.show] is.
final class AlertThresholdEditor {
  const AlertThresholdEditor._();

  static Future<void> open(BuildContext context, WidgetRef ref) async {
    // Whatever the controller last settled on. Null is a read still in flight — there is nothing to seed the sheet with, and a default would be a number the user never chose.
    final AlertsSettings? current = ref.read(alertsControllerProvider).value;

    if (current == null) return;

    final AlertsSettings? picked = await AlertThresholdSheet(
      initial: current,
      l10n: context.l10n,
    ).show(context);

    if (picked == null) return;

    await ref.read(alertsControllerProvider.notifier).apply(picked);
  }
}
