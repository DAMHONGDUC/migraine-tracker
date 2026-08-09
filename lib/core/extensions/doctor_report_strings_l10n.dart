import 'package:intl/intl.dart';

import '../../features/attacks/domain/enums/head_location.dart';
import '../../features/attacks/domain/enums/medication_effect.dart';
import '../../features/insights/domain/services/doctor_report_builder.dart';
import '../../l10n/gen/app_localizations.dart';
import 'head_location_label.dart';
import 'medication_effect_label.dart';

/// Collects the doctor report's localized strings in one place. The builder
/// is pure Dart and takes its copy as data; this is the only translation of
/// l10n into that shape, so the export screen doesn't carry 30 lines of it.
extension DoctorReportStringsL10n on AppLocalizations {
  DoctorReportStrings doctorReportStrings(DateTime now) => DoctorReportStrings(
    title: reportTitle,
    generated: reportGenerated(DateFormat('yyyy-MM-dd').format(now)),
    period: reportPeriod,
    summaryTitle: reportSummaryTitle,
    totalAttacks: reportTotalAttacks,
    avgIntensity: reportAvgIntensity,
    commonLocation: reportCommonLocation,
    typicalDuration: reportTypicalDuration,
    attacksDuringDrops: reportAttacksDuringDrops,
    tableTitle: reportTableTitle,
    colDate: reportColDate,
    colIntensity: reportColIntensity,
    colDuration: reportColDuration,
    colMedicationEffect: reportColMedicationEffect,
    medicationEffectLabels: <MedicationEffect, String>{
      for (final MedicationEffect effect in MedicationEffect.values)
        effect: effect.label(this),
    },
    colLocation: reportColLocation,
    colMedication: reportColMedication,
    colPressureDelta: reportColPressureDelta,
    disclaimer: onboardingDisclaimer,
    locationLabels: <HeadLocation, String>{
      for (final HeadLocation location in HeadLocation.values)
        location: location.label(this),
    },
  );
}
