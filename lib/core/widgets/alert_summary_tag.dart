import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../features/alerts/domain/entities/alerts_settings.dart';
import '../../l10n/gen/app_localizations.dart';
import '../extensions/alerts_settings_label.dart';
import '../extensions/context_extensions.dart';
import '../theme/app_colors.dart';

/// Where the alert stands, as a tag rather than a line of grey text: "On ·
/// 7 hPa", or "Off".
///
/// **The colour is the threshold's own** — `AppColors.intensity`, the same
/// ramp the slider that sets it is tinted with, so the tag and the control
/// behind it never say different things about the same number. A user who
/// dragged to 9 sees the row go red without reading it.
///
/// Off is deliberately not on that ramp: a threshold nothing acts on has no
/// severity, and green there would read as "all good" for the state where
/// nothing is watched at all.
class AlertSummaryTag extends StatelessWidget {
  const AlertSummaryTag({required this.settings, super.key});

  /// Null while the settings are still being read, which the tag says as
  /// "Off" — nothing is being watched either way, and inventing a threshold
  /// to fill the gap would put a second copy of the default in the app.
  final AlertsSettings? settings;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AlertsSettings? value = settings;

    if (value == null || !value.enabled) {
      return SdTagV2(
        label: l10n.alertsStatusOff,
        color: context.colorScheme.onSurfaceVariant,
      );
    }

    return SdTagV2(
      label: value.summary(l10n),
      color: AppColors.intensity(value.thresholdHpa.round()),
    );
  }
}
