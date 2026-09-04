import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/theme/app_theme.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/attacks/presentation/widgets/attack_share_card.dart';
import 'package:migraine_tracker/l10n/gen/app_localizations.dart';

import '../../helpers/settle_frames.dart';

/// The card leaves the phone as a picture, so what it draws is what gets handed to a messaging app. These are the fields it must never carry.
void main() {
  Attack attack({String? notes}) => Attack(
    id: 'a1',
    startedAt: DateTime.utc(2026, 7, 1, 14, 20),
    intensity: 8,
    regions: const <HeadRegion>[HeadRegion.templeL],
    medicationName: 'Sumatriptan',
    symptoms: const <String>['nausea-secret'],
    triggers: const <String>['trigger-secret'],
    notes: notes,
    endedAt: DateTime.utc(2026, 7, 1, 18, 20),
  );

  Future<void> pumpCard(WidgetTester tester, Attack value) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(393, 852),
        builder: (BuildContext context, Widget? child) => MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: AttackShareCard(attack: value)),
        ),
      ),
    );
    await settleFrames(tester);
  }

  // The whole privacy design of the feature rests on this, and it rested on nothing but code review until now.
  testWidgets('never draws the notes', (WidgetTester tester) async {
    await pumpCard(tester, attack(notes: 'my-private-note'));

    expect(find.textContaining('my-private-note'), findsNothing);
  });

  testWidgets('never draws symptoms or triggers either', (
    WidgetTester tester,
  ) async {
    await pumpCard(tester, attack());

    expect(find.textContaining('nausea-secret'), findsNothing);
    expect(find.textContaining('trigger-secret'), findsNothing);
  });

  testWidgets('draws the four facts it is for', (WidgetTester tester) async {
    await pumpCard(tester, attack());

    expect(find.text('8/10'), findsOneWidget);
    expect(find.text('Migraine attack'), findsOneWidget);
    expect(find.text('Started'), findsOneWidget);
    expect(find.text('Duration'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);
  });

  testWidgets('an attack still running draws no duration row', (
    WidgetTester tester,
  ) async {
    await pumpCard(
      tester,
      Attack(
        id: 'a2',
        startedAt: DateTime.utc(2026, 7, 1, 14, 20),
        intensity: 5,
        regions: const <HeadRegion>[HeadRegion.templeR],
      ),
    );

    expect(find.text('Duration'), findsNothing);
  });
}
