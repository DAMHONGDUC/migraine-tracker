import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_location.dart';
import 'package:migraine_tracker/features/insights/domain/entities/correlation_result.dart';
import 'package:migraine_tracker/features/insights/domain/services/doctor_report_builder.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_snapshot.dart';
import 'package:pdf/widgets.dart' as pw;

DoctorReportStrings strings() => DoctorReportStrings(
  title: 'BaroEase - Migraine report',
  generated: 'Generated 2026-07-13',
  period: 'Covering the last 90 days',
  summaryTitle: 'Summary',
  totalAttacks: 'Attacks',
  avgIntensity: 'Average intensity',
  commonLocation: 'Most frequent location',
  attacksDuringDrops: 'During rapid pressure drops',
  tableTitle: 'Attack log',
  colDate: 'Date',
  colIntensity: 'Intensity',
  colLocation: 'Location',
  colMedication: 'Medication',
  colPressureDelta: 'D24h (hPa)',
  disclaimer: 'Not a substitute for professional medical advice.',
  locationLabels: {for (final l in HeadLocation.values) l: l.name},
);

void main() {
  final now = DateTime.utc(2026, 7, 13);

  Attack attack(int daysAgo, {double? delta}) => Attack(
    id: 'a$daysAgo',
    startedAt: now.subtract(Duration(days: daysAgo)),
    intensity: 6,
    location: HeadLocation.right,
    medicationName: 'Sumatriptan',
    weather: delta == null
        ? null
        : WeatherSnapshot(
            capturedAt: now.subtract(Duration(days: daysAgo)),
            pressureHpa: 1008,
            pressureDelta24hHpa: delta,
          ),
  );

  test(
    'builds a non-empty PDF with data, insight, and offline attacks',
    () async {
      final bytes = await const DoctorReportBuilder().build(
        attacks: [
          attack(1, delta: -7),
          attack(10, delta: 2),
          attack(50), // offline, no weather
          attack(120, delta: -9), // outside the 90-day window
        ],
        correlation: const CorrelationInsight(
          attacksAnalyzed: 15,
          attacksDuringPressureDrop: 9,
          dropThresholdHpa: 5,
        ),
        strings: strings(),
        now: now,
        regularFont: pw.Font.helvetica(),
        boldFont: pw.Font.helveticaBold(),
      );
      // %PDF magic header + non-trivial content.
      expect(bytes.length, greaterThan(1000));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    },
  );

  test('handles an empty history without throwing', () async {
    final bytes = await const DoctorReportBuilder().build(
      attacks: [],
      correlation: const CorrelationInsufficientData(
        attacksWithWeather: 0,
        requiredAttacks: 15,
      ),
      strings: strings(),
      now: now,
      regularFont: pw.Font.helvetica(),
      boldFont: pw.Font.helveticaBold(),
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
