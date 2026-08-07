import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/medications/data/repositories/drift_medication_repository.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication.dart';

import '../../helpers/export_fakes.dart';
import '../../helpers/pump_app.dart';

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
    // Signed out, so "local" is the honest label — nothing was ever synced.
    await tapVisible(tester, find.text('Delete all local data'));

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
    await tapVisible(tester, find.text('Delete all local data'));
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(await app.db.select(app.db.attacks).get(), hasLength(1));

    await finishTest(tester);
  });

  testWidgets('with an account the row stops saying local', (tester) async {
    await pumpApp(tester, signedIn: true);
    await openSettings(tester);

    // There is an account copy to delete now, so the promise widens with it.
    expect(find.text('Delete all data'), findsOneWidget);
    expect(find.text('Delete all local data'), findsNothing);

    await finishTest(tester);
  });

  testWidgets('the export screen starts empty', (tester) async {
    await pumpApp(tester);

    await openExportScreen(tester);

    expect(find.text('No exports yet'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('JSON export writes the file and records it in the history', (
    tester,
  ) async {
    final app = await pumpApp(tester);

    await logAttack(tester, intensity: '8', location: 'Left side');
    await openExportScreen(tester);
    await tapVisible(tester, find.text('Export'));
    await tester.tap(find.text('JSON'));
    await settleExport(tester);

    expect(app.exportFiles.singleContent, contains('"intensity": 8'));
    expect(app.exportFiles.singleContent, contains('"location": "left"'));
    expect(app.exportFiles.files.keys.single, contains('baroease_export_'));

    // The history row replaced the empty state.
    expect(await app.db.select(app.db.exportRecords).get(), hasLength(1));
    expect(find.text('No exports yet'), findsNothing);

    await finishTest(tester);
  });

  testWidgets('CSV export writes a csv file', (tester) async {
    final app = await pumpApp(tester);

    await logAttack(tester);
    await openExportScreen(tester);
    await tapVisible(tester, find.text('Export'));
    await tester.tap(find.text('CSV'));
    await settleExport(tester);

    expect(app.exportFiles.singleContent, contains('id,started_at_utc'));
    expect(app.exportFiles.files.keys.single, endsWith('.csv'));

    await finishTest(tester);
  });

  testWidgets('sharing a history row hands the stored file to the share sheet', (
    tester,
  ) async {
    final sharer = RecordingExportSharer();
    final app = await pumpApp(tester, exportSharer: sharer);

    await logAttack(tester);
    await openExportScreen(tester);
    await tapVisible(tester, find.text('Export'));
    await tester.tap(find.text('JSON'));
    await settleExport(tester);

    // Tap the history row, then Share in its actions sheet.
    await tapVisible(tester, find.text('JSON'));
    await tester.tap(find.text('Share'));
    await settleExport(tester);

    expect(sharer.shared, hasLength(1));
    expect(sharer.shared.single.mimeType, 'application/json');
    expect(sharer.shared.single.path, app.exportFiles.files.keys.single);

    await finishTest(tester);
  });

  testWidgets('save to device copies the stored export through the picker', (
    tester,
  ) async {
    final saver = RecordingFileSaver();
    final app = await pumpApp(tester, fileSaver: saver);

    await logAttack(tester);
    await openExportScreen(tester);
    await tapVisible(tester, find.text('Export'));
    await tester.tap(find.text('CSV'));
    await settleExport(tester);

    await tapVisible(tester, find.text('CSV'));
    await tester.tap(find.text('Save to device'));
    await settleExport(tester);

    expect(saver.saved, hasLength(1));
    expect(saver.saved.single.sourcePath, app.exportFiles.files.keys.single);
    expect(saver.saved.single.filename, endsWith('.csv'));
    expect(find.text('Saved to your device.'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('dismissing the save picker says nothing', (tester) async {
    final saver = RecordingFileSaver(result: false);
    await pumpApp(tester, fileSaver: saver);

    await logAttack(tester);
    await openExportScreen(tester);
    await tapVisible(tester, find.text('Export'));
    await tester.tap(find.text('CSV'));
    await settleExport(tester);

    await tapVisible(tester, find.text('CSV'));
    await tester.tap(find.text('Save to device'));
    await settleExport(tester);

    // Backing out is not a failure — no confirmation, no error.
    expect(find.text('Saved to your device.'), findsNothing);

    await finishTest(tester);
  });

  testWidgets('deleting an export removes the row and its file', (
    tester,
  ) async {
    final app = await pumpApp(tester);

    await logAttack(tester);
    await openExportScreen(tester);
    await tapVisible(tester, find.text('Export'));
    await tester.tap(find.text('JSON'));
    await settleExport(tester);

    await tapVisible(tester, find.text('JSON'));
    await tester.tap(find.text('Delete'));
    await settleExport(tester);

    expect(find.text('Delete this export?'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await settleExport(tester);

    expect(await app.db.select(app.db.exportRecords).get(), isEmpty);
    expect(app.exportFiles.files, isEmpty);
    expect(find.text('No exports yet'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('a free user gets the paywall pitch instead of the PDF report', (
    tester,
  ) async {
    await pumpApp(tester);

    await openExportScreen(tester);
    await tapVisible(tester, find.text('Export'));

    // The row is there, but locked — never a path that produces a report.
    expect(find.text('Doctor report (PDF)'), findsOneWidget);
    expect(find.text('Premium'), findsOneWidget);

    await finishTest(tester);
  });
}
