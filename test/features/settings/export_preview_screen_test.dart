import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_location.dart';

import '../../helpers/pump_app.dart';

/// The preview reads the file that was actually written, so what it shows and
/// what a share hands over can never disagree.
Future<void> createExport(WidgetTester tester, String kind) async {
  await tapVisible(tester, find.text('Export'));
  await tester.pump(const Duration(milliseconds: 400));
  await tapVisible(tester, find.text(kind));
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> openPreview(WidgetTester tester) async {
  await tapVisible(tester, find.byIcon(Icons.more_horiz));
  await tester.pump(const Duration(milliseconds: 400));
  await tapVisible(tester, find.text('Preview'));
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  testWidgets('a CSV export previews its own rows', (tester) async {
    final PumpedApp app = await pumpApp(tester);
    await DriftAttackRepository(app.db).insert(
      Attack(
        id: 'a1',
        startedAt: DateTime.utc(2026, 8, 1, 9),
        intensity: 7,
        location: HeadLocation.left,
        medicationName: 'Sumatriptan',
      ),
    );
    await tester.pump();

    await openExportScreen(tester);
    await createExport(tester, 'CSV');
    await openPreview(tester);

    // A table, not a wall of wrapped text: the header names its columns and
    // the record sits under them.
    expect(find.text('intensity'), findsOneWidget);
    expect(find.text('medication'), findsOneWidget);
    expect(find.text('Sumatriptan'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('a JSON export previews too', (tester) async {
    final PumpedApp app = await pumpApp(tester);
    await DriftAttackRepository(app.db).insert(
      Attack(
        id: 'a1',
        startedAt: DateTime.utc(2026, 8, 1, 9),
        intensity: 7,
        location: HeadLocation.left,
      ),
    );
    await tester.pump();

    await openExportScreen(tester);
    await createExport(tester, 'JSON');
    await openPreview(tester);

    expect(find.textContaining('"intensity"'), findsOneWidget);

    await finishTest(tester);
  });
}
