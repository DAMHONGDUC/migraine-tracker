import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/theme/app_icon_constant.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';

import '../../helpers/pump_app.dart';

/// The preview reads the file that was actually written, so what it shows and
/// what a share hands over can never disagree.
Future<void> createExport(WidgetTester tester, String kind) async {
  await tapVisible(tester, find.text('Export'));
  await tester.pump(const Duration(milliseconds: 400));
  await tapVisible(tester, find.text(kind));
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> openActions(WidgetTester tester) async {
  await tapVisible(tester, find.byIcon(AppIconConstant.more));
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> openPreview(WidgetTester tester) async {
  await openActions(tester);
  await tapVisible(tester, find.text('Preview'));
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  testWidgets('a CSV export is not offered a preview at all', (tester) async {
    final PumpedApp app = await pumpApp(tester, premium: true);
    await DriftAttackRepository(app.db).insert(
      Attack(
        id: 'a1',
        startedAt: DateTime.utc(2026, 8, 1, 9),
        intensity: 7,
        regions: const <HeadRegion>[HeadRegion.templeL],
        medicationName: 'Sumatriptan',
      ),
    );
    await tester.pump();

    await openExportScreen(tester);
    await createExport(tester, 'CSV');
    await openActions(tester);

    // 14 columns of comma-separated text say nothing on a phone — share or
    // save it and open it in something that reads spreadsheets.
    expect(find.text('Preview'), findsNothing);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Save to device'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('a JSON export still previews its own text', (tester) async {
    final PumpedApp app = await pumpApp(tester, premium: true);
    await DriftAttackRepository(app.db).insert(
      Attack(
        id: 'a1',
        startedAt: DateTime.utc(2026, 8, 1, 9),
        intensity: 7,
        regions: const <HeadRegion>[HeadRegion.templeL],
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
