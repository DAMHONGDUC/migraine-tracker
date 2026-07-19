import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/medications/data/repositories/drift_medication_repository.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication.dart';
import 'package:migraine_tracker/features/settings/domain/services/export_sink.dart';

import '../../helpers/pump_app.dart';

class RecordingExportSink implements ExportSink {
  final List<({String content, String filename, String mimeType})> shared = [];

  @override
  Future<void> share({
    required String content,
    required String filename,
    required String mimeType,
  }) async {
    shared.add((content: content, filename: filename, mimeType: mimeType));
  }
}

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.settings_outlined));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('delete everything wipes attacks, weather, and medications', (
    tester,
  ) async {
    final app = await pumpApp(tester);

    await logAttack(tester); // seeds one attack through the real flow
    await DriftMedicationRepository(
      app.db,
    ).upsert(const Medication(id: 'm1', name: 'Ibuprofen'));

    await openSettings(tester);
    await tester.tap(find.text('Delete all data'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Delete everything?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('All data deleted.'), findsOneWidget);
    expect(await app.db.select(app.db.attacks).get(), isEmpty);
    expect(await app.db.select(app.db.weatherSnapshots).get(), isEmpty);
    expect(await app.db.select(app.db.medications).get(), isEmpty);

    await finishTest(tester);
  });

  testWidgets('cancelling the confirm dialog deletes nothing', (tester) async {
    final app = await pumpApp(tester);
    await logAttack(tester);

    await openSettings(tester);
    await tester.tap(find.text('Delete all data'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(await app.db.select(app.db.attacks).get(), hasLength(1));

    await finishTest(tester);
  });

  testWidgets('JSON export shares a file containing the logged attack', (
    tester,
  ) async {
    final sink = RecordingExportSink();
    await pumpApp(tester, exportSink: sink);

    await logAttack(tester, intensity: '8', location: 'Left side');

    await openSettings(tester);
    await tester.tap(find.text('Export data'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('JSON (full backup)'));
    // The export path chains several awaits (two stream reads + the share
    // call); give the fake event loop enough turns to drain them all.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(sink.shared, hasLength(1));
    expect(sink.shared.single.mimeType, 'application/json');
    expect(sink.shared.single.filename, startsWith('baroease_export_'));
    expect(sink.shared.single.content, contains('"intensity": 8'));
    expect(sink.shared.single.content, contains('"location": "left"'));

    await finishTest(tester);
  });

  testWidgets('CSV export shares a text/csv file', (tester) async {
    final sink = RecordingExportSink();
    await pumpApp(tester, exportSink: sink);

    await logAttack(tester);

    await openSettings(tester);
    await tester.tap(find.text('Export data'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('CSV (attacks table)'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(sink.shared.single.mimeType, 'text/csv');
    expect(sink.shared.single.content, contains('id,started_at_utc'));

    await finishTest(tester);
  });
}
