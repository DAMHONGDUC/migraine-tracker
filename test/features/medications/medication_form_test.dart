import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:system_design/index.dart';

import '../../helpers/pump_app.dart';

/// The two ways in, and what the scan is allowed to do once it is there.
void main() {
  /// Opens the add sheet from the medications tab and picks [option].
  Future<void> chooseAdd(WidgetTester tester, String option) async {
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text(option));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Taps scan on the form and picks the camera in the source sheet.
  Future<void> scanWithCamera(WidgetTester tester) async {
    await tester.tap(find.text('Scan the label'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Take a photo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('the add button offers both ways in', (tester) async {
    await pumpApp(tester);
    await openMedications(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Quick add'), findsOneWidget);
    expect(find.text('Add with details'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('quick add still saves a medication from the dialog', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester);
    await openMedications(tester);

    await chooseAdd(tester, 'Quick add');
    await tester.enterText(
      find.widgetWithText(TextField, 'Medication name'),
      'Ibuprofen',
    );
    await tester.tap(find.text('Add'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final rows = await app.db.select(app.db.medications).get();
    expect(rows.single.name, 'Ibuprofen');
    expect(rows.single.dosage, isNull);

    await finishTest(tester);
  });

  testWidgets('the details form needs a name and keeps the optional fields', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester);
    await openMedications(tester);
    await chooseAdd(tester, 'Add with details');

    // Nothing typed yet, so there is nothing to save.
    expect(
      tester
          .widget<SdButtonV2>(find.widgetWithText(SdButtonV2, 'Save'))
          .onPressed,
      isNull,
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Name'),
      'Sumatriptan',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Strength'), '50 mg');
    await tester.enterText(
      find.widgetWithText(TextField, 'Dosage'),
      '1 tablet, twice a day',
    );
    await tester.pump();

    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final rows = await app.db.select(app.db.medications).get();
    expect(rows.single.name, 'Sumatriptan');
    expect(rows.single.strength, '50 mg');
    expect(rows.single.dosage, '1 tablet, twice a day');
    // Left blank stays null, never an empty string.
    expect(rows.single.description, isNull);

    // And it is back on the list (the form is still sliding out, so the name
    // is on screen more than once mid-transition).
    expect(find.text('Sumatriptan'), findsWidgets);

    await finishTest(tester);
  });

  testWidgets('scanning a label fills the form but saves nothing', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester);
    app.photos.path = '/tmp/label.jpg';
    app.textRecognizer.lines = const <String>[
      'Panadol Extra 500mg',
      'Active ingredients: Paracetamol, caffeine',
      'Dosage: 2 tablets every 6 hours',
    ];

    await openMedications(tester);
    await chooseAdd(tester, 'Add with details');
    await scanWithCamera(tester);

    expect(app.photos.lastOrigin?.name, 'camera');
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'Name'))
          .controller
          ?.text,
      'Panadol Extra 500mg',
    );
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'Strength'))
          .controller
          ?.text,
      '500mg',
    );
    // A scan proposes; nothing reaches the database until the user saves.
    expect(await app.db.select(app.db.medications).get(), isEmpty);

    await finishTest(tester);
  });

  testWidgets('backing out of the picker changes nothing', (tester) async {
    // The fake's path stays null — that is a cancelled picker.
    await pumpApp(tester);
    await openMedications(tester);
    await chooseAdd(tester, 'Add with details');
    await scanWithCamera(tester);

    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'Name'))
          .controller
          ?.text,
      isEmpty,
    );
    expect(find.text('No text found on that photo.'), findsNothing);

    await finishTest(tester);
  });

  testWidgets('an unreadable photo says so and keeps the form', (tester) async {
    final PumpedApp app = await pumpApp(tester);
    app.photos.path = '/tmp/label.jpg';
    app.textRecognizer.throws = true;

    await openMedications(tester);
    await chooseAdd(tester, 'Add with details');
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Aspirin');
    await scanWithCamera(tester);

    expect(find.text("Couldn't read that photo."), findsOneWidget);
    // What the user typed survives a failed scan.
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'Name'))
          .controller
          ?.text,
      'Aspirin',
    );

    await finishTest(tester);
  });

  testWidgets('a scan never overwrites what the user already typed', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester);
    app.photos.path = '/tmp/label.jpg';
    app.textRecognizer.lines = const <String>['Panadol Extra 500mg'];

    await openMedications(tester);
    await chooseAdd(tester, 'Add with details');
    await tester.enterText(
      find.widgetWithText(TextField, 'Name'),
      'My own name',
    );
    await scanWithCamera(tester);

    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'Name'))
          .controller
          ?.text,
      'My own name',
    );
    // The fields it did not have to fight over still get filled.
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'Strength'))
          .controller
          ?.text,
      '500mg',
    );

    await finishTest(tester);
  });
}
