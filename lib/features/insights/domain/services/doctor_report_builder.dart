import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/date_time_utils.dart';
import '../../../attacks/domain/entities/attack.dart';
import '../../../attacks/domain/enums/head_location.dart';
import '../../../attacks/domain/enums/medication_effect.dart';
import '../../../attacks/domain/services/medication_effect_tally.dart';
import '../entities/correlation_result.dart';

/// Labels injected by the presentation layer so this service stays free of
/// Flutter/l10n imports. The PDF renders with the bundled Noto Sans faces
/// (see [DoctorReportBuilder.build]), which cover Vietnamese, so these
/// strings may be fully localized.
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
    required this.attacksDuringDrops,
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
  final String attacksDuringDrops;
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
  final Map<HeadLocation, String> locationLabels;
}

/// Builds the shareable doctor report: 90-day summary stats + attack table.
/// Pure Dart (package:pdf has no Flutter dependency).
class DoctorReportBuilder {
  const DoctorReportBuilder();

  static const _periodDays = 90;

  /// [regularFont] and [boldFont] are the bundled Noto Sans faces, passed in
  /// by the caller (the loader lives in the presentation layer so this stays
  /// pure Dart). They cover Vietnamese, so [strings] may now be localized.
  Future<Uint8List> build({
    required List<Attack> attacks,
    required CorrelationResult correlation,
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
          _summaryTable(recent, correlation, strings),
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
    DoctorReportStrings strings,
  ) {
    final rows = <List<String>>[
      [strings.totalAttacks, '${attacks.length}'],
      if (attacks.isNotEmpty)
        [
          strings.avgIntensity,
          (attacks.map((a) => a.intensity).reduce((a, b) => a + b) /
                  attacks.length)
              .toStringAsFixed(1),
        ],
      if (attacks.isNotEmpty)
        [strings.commonLocation, _modalLocation(attacks, strings)],
      // Only the attacks the user actually timed. Median, so one 72-hour
      // outlier cannot move the figure a doctor reads as typical.
      if (DateTimeUtils.median(<Duration>[
            for (final Attack a in attacks)
              if (a.duration case final Duration d) d,
          ])
          case final Duration typical)
        [strings.typicalDuration, _durationLabel(typical)],
      // One row per medication that has outcomes. This is the part a doctor
      // acts on: a drug that only ever partly works is a drug being changed.
      for (final MapEntry<String, MedicationEffectCount> entry
          in const MedicationEffectTally().byMedication(attacks).entries)
        [
          entry.key,
          '${entry.value.helped}/${entry.value.answered} '
              '(${strings.colMedicationEffect.toLowerCase()})',
        ],
      // Mature figures only: a share still settling has no business in a
      // document a doctor reads as settled.
      if (correlation case CorrelationInsight(
        isPreliminary: false,
        :final dropSharePercent,
        :final dropThresholdHpa,
      ))
        [
          strings.attacksDuringDrops,
          '${dropSharePercent.round()}% (>=$dropThresholdHpa hPa/24h)',
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

  /// Locale-free on purpose: `DoctorReportStrings` carries no plural forms,
  /// and "6h 30m" reads the same in both locales the app ships.
  String _durationLabel(Duration duration) {
    final (int hours, int minutes) = DateTimeUtils.splitHm(duration);

    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    return '${minutes}m';
  }

  String _modalLocation(List<Attack> attacks, DoctorReportStrings strings) {
    final counts = <HeadLocation, int>{};
    for (final a in attacks) {
      counts[a.location] = (counts[a.location] ?? 0) + 1;
    }
    final modal = counts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
    return strings.locationLabels[modal] ?? modal.name;
  }

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
            strings.locationLabels[a.location] ?? a.location.name,
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
