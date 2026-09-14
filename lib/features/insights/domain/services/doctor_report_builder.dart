import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/date_time_utils.dart';
import '../../../attacks/domain/entities/attack.dart';
import '../../../attacks/domain/enums/aura_type.dart';
import '../../../attacks/domain/enums/head_region.dart';
import '../../../attacks/domain/enums/medication_effect.dart';
import '../entities/correlation_result.dart';
import '../entities/medication_effectiveness_result.dart';
import '../entities/medication_overuse_result.dart';
import '../entities/midas_score.dart';
import '../entities/migraine_days_summary.dart';
import 'medication_effectiveness_engine.dart';
import 'medication_overuse_engine.dart';
import 'migraine_days_engine.dart';

/// Labels injected by the presentation layer so this service stays free of Flutter/l10n imports.
class DoctorReportStrings {
  const DoctorReportStrings({
    required this.title,
    required this.generated,
    required this.period,
    required this.summaryTitle,
    required this.totalAttacks,
    required this.avgIntensity,
    required this.commonLocation,
    required this.typicalDuration,
    required this.monthlyDays,
    required this.midas,
    required this.midasGrades,
    required this.aura,
    required this.auraLabels,
    required this.medicationDays,
    required this.medicationOveruse,
    required this.attacksDuringDrops,
    required this.baseline,
    required this.tableTitle,
    required this.colDate,
    required this.colIntensity,
    required this.colDuration,
    required this.colMedicationEffect,
    required this.medicationEffectLabels,
    required this.colLocation,
    required this.colMedication,
    required this.colPressureDelta,
    required this.disclaimer,
    required this.locationLabels,
  });

  final String title;
  final String generated;
  final String period;
  final String summaryTitle;
  final String totalAttacks;
  final String avgIntensity;
  final String commonLocation;
  final String typicalDuration;

  /// Label for the MIDAS row, and the four grade names it prints.
  final String midas;
  final Map<MidasGrade, String> midasGrades;

  /// Label for the migraine-days-per-month row — the figure a headache clinic opens with and every preventive is judged on.
  final String monthlyDays;

  /// Label for the aura row.
  final String aura;

  final Map<AuraType, String> auraLabels;

  /// Label for the acute-medication-days row — the denominator behind medication-overuse headache.
  final String medicationDays;

  /// Label for the overuse row, which appears only when a month is at or over the threshold. Absent is the good news and needs no line.
  final String medicationOveruse;
  final String attacksDuringDrops;
  final String baseline;
  final String tableTitle;
  final String colDate;
  final String colIntensity;
  final String colDuration;
  final String colMedicationEffect;
  final Map<MedicationEffect, String> medicationEffectLabels;
  final String colLocation;
  final String colMedication;
  final String colPressureDelta;
  final String disclaimer;
  final Map<HeadRegion, String> locationLabels;
}

/// Builds the shareable doctor report: 90-day summary stats + attack table. Pure Dart (package:pdf has no Flutter dependency).
class DoctorReportBuilder {
  const DoctorReportBuilder();

  static const _periodDays = 90;

  /// The same window stated in months, for the per-month row.
  static const _periodMonths = 3;

  /// [regularFont] and [boldFont] are the bundled Noto Sans faces, passed in by the caller (the loader lives in the presentation layer so this stays pure.
  Future<Uint8List> build({
    required List<Attack> attacks,
    required CorrelationResult correlation,
    required MidasEntry? midas,
    required DoctorReportStrings strings,
    required DateTime now,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) async {
    final since = now.subtract(const Duration(days: _periodDays));
    final recent = attacks.where((a) => a.startedAt.isAfter(since)).toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 12),
          child: pw.Text(
            strings.disclaimer,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          pw.Text(
            strings.title,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${strings.generated} | ${strings.period}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            strings.summaryTitle,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          _summaryTable(recent, correlation, midas, strings, now),
          pw.SizedBox(height: 16),
          pw.Text(
            strings.tableTitle,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          _attackTable(recent, strings),
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _summaryTable(
    List<Attack> attacks,
    CorrelationResult correlation,
    MidasEntry? midas,
    DoctorReportStrings strings,
    DateTime now,
  ) {
    final rows = <List<String>>[
      [strings.totalAttacks, '${attacks.length}'],
      // The one figure here the user supplied rather than the app derived, and the one a headache clinic opens with after the day count.
      if (midas case final MidasEntry entry)
        [
          strings.midas,
          '${entry.score} (${strings.midasGrades[entry.grade]})',
        ],
      if (attacks.isNotEmpty)
        [
          strings.avgIntensity,
          (attacks.map((a) => a.intensity).reduce((a, b) => a + b) /
                  attacks.length)
              .toStringAsFixed(1),
        ],
      if (attacks.isNotEmpty)
        [strings.commonLocation, _modalLocation(attacks, strings)],
      // Only the attacks the user actually timed. Median, so one 72-hour outlier cannot move the figure a doctor reads as typical.
      if (DateTimeUtils.median(<Duration>[
            for (final Attack a in attacks)
              if (a.duration case final Duration d) d,
          ])
          case final Duration typical)
        [strings.typicalDuration, _durationLabel(typical)],
      // Days, not attacks: three attacks in one day is one day lost, and a drug that halves the attacks without touching the days has not worked.
      if (attacks.isNotEmpty)
        [
          strings.monthlyDays,
          _monthlyDaysLabel(
            const MigraineDaysEngine(
              months: _periodMonths,
            ).analyze(attacks, now: now),
          ),
        ],
      // One row per medication that has outcomes.
      if (const MedicationEffectivenessEngine().analyze(attacks)
          case MedicationEffectivenessInsight(:final medications))
        for (final MedicationEffectiveness row in medications)
          if (row.answeredCount > 0)
            [
              row.name,
              '${row.helpedCount}/${row.answeredCount} '
                  '(${strings.colMedicationEffect.toLowerCase()})',
            ],
      // With aura or without is a diagnostic split, not a detail, so it rides in the summary rather than as an eighth column on a table that already fills.
      if (_auraLabel(attacks, strings) case final String label)
        [strings.aura, label],
      // The denominator behind medication-overuse headache. Days of intake, which is what ICHD-3 counts — never doses.
      if (attacks.isNotEmpty)
        [
          strings.medicationDays,
          _monthlyIntakeLabel(
            const MedicationOveruseEngine(
              months: _periodMonths,
            ).analyze(attacks, now: now),
          ),
        ],
      // Only when a month is actually at or over it: absent is the good news and does not need a line in a document a doctor skims.
      if (_overuseLabel(
        const MedicationOveruseEngine(
          months: _periodMonths,
        ).analyze(attacks, now: now),
      )
          case final String label)
        [strings.medicationOveruse, label],
      // Mature figures only: a share still settling has no business in a document a doctor reads as settled.
      if (correlation case CorrelationInsight(
        isPreliminary: false,
        :final dropSharePercent,
        :final dropThresholdHpa,
      ))
        [
          strings.attacksDuringDrops,
          '${dropSharePercent.round()}% (>=$dropThresholdHpa hPa/24h)',
        ],
      // The comparison, where there is one. Without it the row above states a share with no denominator, which a doctor would rightly discount.
      if (correlation case CorrelationInsight(
        isPreliminary: false,
        baseline: final PressureBaseline b?,
      ))
        [
          strings.baseline,
          '${b.dropDayAttackPercent.round()}% vs '
              '${b.calmDayAttackPercent.round()}% '
              '(${b.dropDays}/${b.calmDays} days)',
        ],
    ];
    return pw.Table(
      columnWidths: const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(3)},
      children: [
        for (final row in rows)
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Text(
                  row[0],
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
              pw.Text(row[1], style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
      ],
    );
  }

  /// Locale-free on purpose: `DoctorReportStrings` carries no plural forms, and "6h 30m" reads the same in both locales the app ships.
  String _monthlyDaysLabel(MigraineDaysSummary summary) => summary.months
      .map(
        (MonthlyMigraineDays m) =>
            '${m.month.year}-${m.month.month.toString().padLeft(2, '0')}: '
            '${m.days}',
      )
      .join(' | ');

  /// "12/34 (Visual 10, Sensory 3)" — attacks that came with an aura out of those where the question was answered, then the kinds.
  String? _auraLabel(List<Attack> attacks, DoctorReportStrings strings) {
    final Map<AuraType, int> counts = <AuraType, int>{};
    int answered = 0;
    int withAura = 0;

    for (final Attack attack in attacks) {
      final List<AuraType>? aura = attack.aura;

      if (aura == null) continue;

      answered++;
      if (aura.isNotEmpty) withAura++;
      for (final AuraType type in aura) {
        counts[type] = (counts[type] ?? 0) + 1;
      }
    }

    if (answered == 0) return null;

    final String kinds = <String>[
      for (final AuraType type in AuraType.values)
        if (counts[type] case final int count)
          '${strings.auraLabels[type] ?? type.name} $count',
    ].join(', ');

    return kinds.isEmpty
        ? '$withAura/$answered'
        : '$withAura/$answered ($kinds)';
  }

  /// "2026-06: 11 | 2026-07: 12 | 2026-08: 8", the same numeric-month shape the migraine-days row uses.
  String _monthlyIntakeLabel(MedicationOveruseResult result) => result.months
      .map(
        (MonthlyIntakeDays m) =>
            '${m.month.year}-${m.month.month.toString().padLeft(2, '0')}: '
            '${m.days}',
      )
      .join(' | ');

  /// "2/3 months >= 10 days", or null while no month reaches the threshold.
  String? _overuseLabel(MedicationOveruseResult result) {
    final int over = result.months
        .where((MonthlyIntakeDays m) => m.days >= result.thresholdDays)
        .length;

    if (over == 0) return null;

    return '$over/${result.months.length} months '
        '>= ${result.thresholdDays} days';
  }

  String _durationLabel(Duration duration) {
    final (int hours, int minutes) = DateTimeUtils.splitHm(duration);

    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    return '${minutes}m';
  }

  /// The single area named by most attacks.
  String _modalLocation(List<Attack> attacks, DoctorReportStrings strings) {
    final Map<HeadRegion, int> counts = <HeadRegion, int>{};

    for (final Attack a in attacks) {
      for (final HeadRegion region in a.regions) {
        counts[region] = (counts[region] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return '-';
    final HeadRegion modal = counts.entries
        .reduce((MapEntry<HeadRegion, int> a, MapEntry<HeadRegion, int> b) =>
            a.value >= b.value ? a : b)
        .key;

    return strings.locationLabels[modal] ?? modal.name;
  }

  /// Every area of one attack, in one cell.
  /// A dash where no area was recorded, like every other unanswered cell in this table.
  String _regionsLabel(List<HeadRegion> regions, DoctorReportStrings strings) =>
      regions.isEmpty
      ? '-'
      : regions
            .map((HeadRegion r) => strings.locationLabels[r] ?? r.name)
            .join(', ');

  pw.Widget _attackTable(List<Attack> attacks, DoctorReportStrings strings) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      headers: [
        strings.colDate,
        strings.colIntensity,
        strings.colDuration,
        strings.colLocation,
        strings.colMedication,
        strings.colMedicationEffect,
        strings.colPressureDelta,
      ],
      data: [
        for (final a in attacks)
          [
            dateFormat.format(a.startedAt.toLocal()),
            '${a.intensity}',
            a.duration == null ? '-' : _durationLabel(a.duration!),
            _regionsLabel(a.regions, strings),
            a.medicationName ?? '-',
            a.medicationEffect == null
                ? '-'
                : strings.medicationEffectLabels[a.medicationEffect] ??
                      a.medicationEffect!.name,
            a.weather?.pressureDelta24hHpa.toStringAsFixed(1) ?? '-',
          ],
      ],
    );
  }
}
