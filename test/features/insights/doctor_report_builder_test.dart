import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/aura_type.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/medication_effect.dart';
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
  typicalDuration: 'Typical duration',
  monthlyDays: 'Migraine days per month',
  aura: 'Attacks with aura',
  auraLabels: <AuraType, String>{
    AuraType.visual: 'Visual',
    AuraType.sensory: 'Sensory',
    AuraType.speech: 'Speech',
    AuraType.motor: 'Motor',
  },
  medicationDays: 'Acute medication days per month',
  medicationOveruse: 'Medication overuse (ICHD-3)',
  attacksDuringDrops: 'During rapid pressure drops',
  baseline: 'Attack rate, drop days vs other days',
  tableTitle: 'Attack log',
  colDate: 'Date',
  colIntensity: 'Intensity',
  colDuration: 'Duration',
  colMedicationEffect: 'Helped',
  medicationEffectLabels: {for (final e in MedicationEffect.values) e: e.name},
  colLocation: 'Location',
  colMedication: 'Medication',
  colPressureDelta: 'D24h (hPa)',
  disclaimer: 'Not a substitute for professional medical advice.',
  locationLabels: {for (final r in HeadRegion.values) r: r.name},
);

void main() {
  final now = DateTime.utc(2026, 7, 13);

  Attack attack(int daysAgo, {double? delta}) => Attack(
    id: 'a$daysAgo',
    startedAt: now.subtract(Duration(days: daysAgo)),
    intensity: 6,
    regions: const <HeadRegion>[HeadRegion.templeR],
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
          requiredAttacks: 15,
          attacksDuringPressureDrop: 9,
          dropThresholdHpa: 5,
          minAttacksForShare: 5,
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
        attacksAnalyzed: 0,
        requiredAttacks: 15,
      ),
      strings: strings(),
      now: now,
      regularFont: pw.Font.helvetica(),
      boldFont: pw.Font.helveticaBold(),
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  // The three clinical rows added after the first version. They are smoke
  // tests on purpose: the output is a PDF, so what can be asserted here is
  // that a shape which used to have no row now builds without throwing.
  group('the clinical rows', () {
    Attack medicated(int daysAgo, {List<AuraType>? aura}) => Attack(
      id: 'm$daysAgo',
      startedAt: now.subtract(Duration(days: daysAgo)),
      intensity: 7,
      regions: const <HeadRegion>[HeadRegion.templeL],
      medicationName: 'Sumatriptan',
      medicationEffect: MedicationEffect.partly,
      aura: aura,
    );

    Future<int> report(List<Attack> attacks) async {
      final bytes = await const DoctorReportBuilder().build(
        attacks: attacks,
        correlation: const CorrelationInsufficientData(
          attacksAnalyzed: 0,
          requiredAttacks: 15,
        ),
        strings: strings(),
        now: now,
        regularFont: pw.Font.helvetica(),
        boldFont: pw.Font.helveticaBold(),
      );

      return bytes.length;
    }

    test('an aura answered on some attacks builds', () async {
      expect(
        await report(<Attack>[
          medicated(1, aura: <AuraType>[AuraType.visual, AuraType.motor]),
          medicated(3, aura: const <AuraType>[]),
          medicated(5),
        ]),
        greaterThan(1000),
      );
    });

    // Nobody answered it, so the row is absent rather than "0/0".
    test('an aura nobody answered still builds', () async {
      expect(
        await report(<Attack>[medicated(1), medicated(3)]),
        greaterThan(1000),
      );
    });

    test('a month over the intake threshold builds', () async {
      expect(
        await report(<Attack>[
          for (int day = 1; day <= 14; day++) medicated(day),
        ]),
        greaterThan(1000),
      );
    });

    test('an empty history builds without any of the three rows', () async {
      expect(await report(<Attack>[]), greaterThan(1000));
    });
  });
}

