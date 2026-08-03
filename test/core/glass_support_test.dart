import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:migraine_tracker/core/theme/app_colors.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_location.dart';
import 'package:system_design/index.dart';

import '../helpers/pump_app.dart';

/// The chrome follows what the engine can actually render (`SdGlassV2`), with
/// the bottom nav as the one deliberate exception.
void main() {
  /// Icons.home is the nav's selected dashboard icon and appears nowhere
  /// else, so this pins the floating pill specifically.
  final Finder navGlass = find.ancestor(
    of: find.byIcon(Icons.home),
    matching: find.byType(LiquidGlass),
  );

  final Finder appBarBlur = find.descendant(
    of: find.byType(SdAppBarV2),
    matching: find.byType(BackdropFilter),
  );

  testWidgets('a supported engine frosts the app bar', (tester) async {
    await pumpApp(tester);

    expect(appBarBlur, findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('an unsupported engine drops the app-bar glass', (tester) async {
    await pumpApp(tester, glassSupported: false);

    expect(appBarBlur, findsNothing);

    await finishTest(tester);
  });

  testWidgets('the bottom nav stays glass on either engine', (tester) async {
    await pumpApp(tester, glassSupported: false);

    expect(navGlass, findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('a bottom sheet is a flat card-coloured panel, never glass', (
    tester,
  ) async {
    // The engine that used to frost sheets — the one the app ships on.
    final app = await pumpApp(tester);
    await DriftAttackRepository(app.db).insert(
      Attack(
        id: 'a1',
        startedAt: DateTime.now().toUtc(),
        intensity: 5,
        location: HeadLocation.left,
      ),
    );

    await openHistory(tester);
    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final Finder sheet = find.byType(BottomSheet);
    expect(sheet, findsOneWidget);
    expect(
      find.descendant(of: sheet, matching: find.byType(LiquidGlass)),
      findsNothing,
    );
    // Same colour as every card, so one never reads as a shade of the other.
    final Material surface = tester.widget<Material>(
      find.descendant(of: sheet, matching: find.byType(Material)).first,
    );
    expect(surface.color, AppColors.surface);

    await finishTest(tester);
  });
}
