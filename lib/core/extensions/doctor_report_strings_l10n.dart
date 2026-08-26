import 'package:intl/intl.dart';

import '../../features/attacks/domain/enums/head_region.dart';
import '../../features/attacks/domain/enums/medication_effect.dart';
import '../../features/insights/domain/services/doctor_report_builder.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/gen/app_localizations_en.dart';
import '../constants/export_constant.dart';
import 'head_region_label.dart';
import 'medication_effect_label.dart';

/// Collects the doctor report's localized strings in one place. The builder
/// is pure Dart and takes its copy as data; this is the only translation of
/// l10n into that shape, so the export screen doesn't carry 30 lines of it.
///
/// A locale the report's fonts cannot draw falls back to English here rather
/// than at the call site, so every caller gets a readable PDF by default —
/// see [ExportConstant.reportFontlessLocales].
extension DoctorReportStringsL10n on AppLocalizations {
  DoctorReportStrings doctorReportStrings(DateTime now) =>
      ExportConstant.reportFontlessLocales.contains(localeName)
      ? AppLocalizationsEn()._reportStrings(now)
      : _reportStrings(now);

  DoctorReportStrings _reportStrings(DateTime now) => DoctorReportStrings(
    title: reportTitle,
    generated: reportGenerated(DateFormat('yyyy-MM-dd').format(now)),
    period: reportPeriod,
    summaryTitle: reportSummaryTitle,
    totalAttacks: reportTotalAttacks,
    avgIntensity: reportAvgIntensity,
    commonLocation: reportCommonLocation,
    typicalDuration: reportTypicalDuration,
    monthlyDays: reportMonthlyDays,
    attacksDuringDrops: reportAttacksDuringDrops,
    baseline: reportBaseline,
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
    locationLabels: <HeadRegion, String>{
      for (final HeadRegion region in HeadRegion.values)
        region: region.label(this),
    },
  );
}
