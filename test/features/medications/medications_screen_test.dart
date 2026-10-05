import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/core/theme/app_icon_constant.dart';
import 'package:migraine_tracker/features/medications/data/repositories/drift_medication_repository.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication.dart';
import 'package:system_design/index.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('the add button holds the bottom edge past a scrollful of '
      'reminders', (tester) async {
    final app = await pumpApp(tester);
    await DriftMedicationRepository(
      app.db,
    ).upsert(const Medication(id: 'm1', name: 'Sumatriptan'));
    for (int i = 0; i < 15; i++) {
      await app.db
          .into(app.db.medicationReminders)
          .insert(
            MedicationRemindersCompanion.insert(
              id: 'r$i',
              medicationId: 'm1',
              minuteOfDay: i * 60,
            ),
          );
    }

    await openMedications(tester);
    await openMedication(tester, 'Sumatriptan');

    final Finder button = find.text('Add reminder');
    final Finder firstRow = find.text('00:00');
    final double buttonBefore = tester.getTopLeft(button).dy;
    final double rowBefore = tester.getTopLeft(firstRow).dy;

    // Drag a reminder row, so the gesture lands inside the list's scroll view.
    await tester.drag(
      find.byIcon(AppIconConstant.reminder).first,
      const Offset(0, -300),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Proves the drag scrolled something — otherwise the button holding still would say nothing at all.
    expect(
      tester.getTopLeft(firstRow).dy,
      lessThan(rowBefore),
      reason: 'the list scrolled',
    );
    expect(
      tester.getTopLeft(button).dy,
      buttonBefore,
      reason: 'the action is pinned, not scrolled with the list',
    );

    await finishTest(tester);
  });

  testWidgets('reminders are separated by a rule, never edged by one', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await DriftMedicationRepository(
      app.db,
    ).upsert(const Medication(id: 'm1', name: 'Sumatriptan'));
    for (int i = 0; i < 3; i++) {
      await app.db
          .into(app.db.medicationReminders)
          .insert(
            MedicationRemindersCompanion.insert(
              id: 'r$i',
              medicationId: 'm1',
              minuteOfDay: i * 60,
            ),
          );
    }

    await openMedications(tester);
    await openMedication(tester, 'Sumatriptan');

    // Three rows, two rules — the card's own top and bottom edges stay clean.
    expect(find.byType(SdDividerV2), findsNWidgets(2));

    await finishTest(tester);
  });

  testWidgets('the name field shows a pencil, then a tick that saves', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await DriftMedicationRepository(
      app.db,
    ).upsert(const Medication(id: 'm1', name: 'Sumatriptan'));

    await openMedications(tester);
    await openMedication(tester, 'Sumatriptan');

    // At rest the pencil says the name can be changed.
    expect(find.byIcon(AppIconConstant.edit), findsOneWidget);
    expect(find.byIcon(Symbols.check_rounded), findsNothing);

    // Tapping it focuses the field, and the glyph becomes the save action.
    await tester.tap(find.byIcon(AppIconConstant.edit));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byIcon(Symbols.check_rounded), findsOneWidget);
    expect(find.byIcon(AppIconConstant.edit), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'Rizatriptan');
    await tester.tap(find.byIcon(Symbols.check_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Saved, and the field is back to its resting state.
    final rows = await app.db.select(app.db.medications).get();
    expect(rows.single.name, 'Rizatriptan');
    expect(rows.single.id, 'm1', reason: 'renames in place');
    expect(find.byIcon(AppIconConstant.edit), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('shows the empty state when no medications are saved', (
    tester,
  ) async {
    await pumpApp(tester);
    await openMedications(tester);

    expect(find.text('No medications yet.'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('the all-filters sheet holds the three axes, divided', (
    tester,
  ) async {
    await pumpApp(tester);
    await openMedications(tester);
    await addMedication(tester, 'Sumatriptan');

    await tester.tap(find.text('Filters'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final Finder inSheet = find.byType(SdSheetContentV2);
    expect(
      find.descendant(of: inSheet, matching: find.byType(SdDividerV2)),
      findsNWidgets(2),
    );

    await tester.tap(
      find.descendant(of: inSheet, matching: find.text('Has reminder')),
    );
    await tester.pump();
    // Picked, not applied: the card is still listed.
    expect(find.text('Sumatriptan'), findsOneWidget);

    await tester.tap(find.widgetWithText(SdButtonV2, 'Apply'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Sumatriptan'), findsNothing);
    expect(find.text('Filters (1)'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('adding a medication shows it as a card', (tester) async {
    await pumpApp(tester);
    await openMedications(tester);

    await addMedication(tester, 'Sumatriptan');

    expect(find.text('Sumatriptan'), findsOneWidget);
    expect(find.text('No medications yet.'), findsNothing);

    await finishTest(tester);
  });

  testWidgets('renaming a medication updates its card and keeps its id', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await DriftMedicationRepository(
      app.db,
    ).upsert(const Medication(id: 'm1', name: 'Sumatriptan'));

    await openMedications(tester);
    await openMedication(tester, 'Sumatriptan');

    // The name is edited in place on its own field, not via a dialog — it commits when the field loses focus (here, "done" on the keyboard).
    await tester.enterText(findLabelledField('Name'), 'Rizatriptan');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Rizatriptan'), findsWidgets);
    expect(find.text('Sumatriptan'), findsNothing);

    final rows = await app.db.select(app.db.medications).get();
    expect(rows.single.id, 'm1');

    await finishTest(tester);
  });

  testWidgets('deleting a medication pops back to an empty list', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await DriftMedicationRepository(
      app.db,
    ).upsert(const Medication(id: 'm1', name: 'Sumatriptan'));

    await openMedications(tester);
    await openMedication(tester, 'Sumatriptan');
    await tester.tap(find.byIcon(AppIconConstant.delete));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Confirmation dialog.
    expect(find.text('Delete medication?'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Sumatriptan'), findsNothing);
    expect(find.text('No medications yet.'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('a reminder can be added, toggled and removed on the detail', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await DriftMedicationRepository(
      app.db,
    ).upsert(const Medication(id: 'm1', name: 'Sumatriptan'));

    await openMedications(tester);
    await openMedication(tester, 'Sumatriptan');
    await openAddReminder(tester);

    // - custom wheel picker sheet (AppTimePickerSheet).
    expect(find.byType(ListWheelScrollView), findsNWidgets(2));
    // Add mode labels the bottom button "Save"; the header's tick is gone.
    await tester.tap(find.widgetWithText(SdButtonV2, 'Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(AppIconConstant.reminder), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
    // A confirmation snackbar spells out when it will fire.
    expect(find.textContaining('Reminder set for'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

    await tester.tap(reminderDelete());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byIcon(AppIconConstant.reminder), findsNothing);

    await finishTest(tester);
  });

  testWidgets('tapping a reminder edits its time and reschedules', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await DriftMedicationRepository(
      app.db,
    ).upsert(const Medication(id: 'm1', name: 'Sumatriptan'));
    await app.db
        .into(app.db.medicationReminders)
        .insert(
          MedicationRemindersCompanion.insert(
            id: 'r1',
            medicationId: 'm1',
            minuteOfDay: 9 * 60,
          ),
        );

    await openMedications(tester);
    await openMedication(tester, 'Sumatriptan');
    expect(find.text('09:00'), findsOneWidget);

    // Tap the reminder row to open the picker pre-filled at 09:00.
    await tester.tap(find.text('09:00'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // The sheet titles itself for editing (not "Add reminder").
    expect(find.text('Edit reminder'), findsOneWidget);

    // Drag the hour wheel up 3 rows → 12:00 (same mechanic as the add test).
    await tester.drag(
      find.byType(ListWheelScrollView).first,
      const Offset(0, -44 * 3),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // Edit mode labels the bottom button "Update", not "Save".
    await tester.tap(find.widgetWithText(SdButtonV2, 'Update'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('12:00'), findsOneWidget);
    expect(find.text('09:00'), findsNothing);
    final rows = await app.db.select(app.db.medicationReminders).get();
    expect(rows.single.minuteOfDay, 12 * 60);
    expect(rows.single.id, 'r1', reason: 'edits in place, not a new reminder');

    await finishTest(tester);
  });

  testWidgets('scrolling the hour wheel changes the time that gets saved', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await DriftMedicationRepository(
      app.db,
    ).upsert(const Medication(id: 'm1', name: 'Sumatriptan'));

    await openMedications(tester);
    await openMedication(tester, 'Sumatriptan');
    await openAddReminder(tester);

    // - over-drag the hour wheel (first ListWheelScrollView) UP past the end so it clamps at 23.
    await tester.drag(
      find.byType(ListWheelScrollView).first,
      const Offset(0, -44 * 30),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.widgetWithText(SdButtonV2, 'Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // The saved hour is whatever the wheel was dragged to (23), proving the wheel drives the stored time.
    final rows = await app.db.select(app.db.medicationReminders).get();
    expect(rows.single.minuteOfDay ~/ 60, 23);

    await finishTest(tester);
  });

  testWidgets('the list row counts reminders, the detail lists them all', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await DriftMedicationRepository(
      app.db,
    ).upsert(const Medication(id: 'm1', name: 'Sumatriptan'));
    for (var i = 0; i < 5; i++) {
      await app.db
          .into(app.db.medicationReminders)
          .insert(
            MedicationRemindersCompanion.insert(
              id: 'r$i',
              medicationId: 'm1',
              // Distinct, ordered minutes: 01:00, 02:00, ... 05:00.
              minuteOfDay: (i + 1) * 60,
            ),
          );
    }

    await openMedications(tester);

    // The row says how many; no time is on the list at all.
    expect(find.textContaining('5 reminders'), findsOneWidget);
    expect(find.byIcon(AppIconConstant.reminder), findsNothing);
    expect(find.text('01:00'), findsNothing);

    await openMedication(tester, 'Sumatriptan');

    // All five, none collapsed away.
    expect(find.byIcon(AppIconConstant.reminder), findsNWidgets(5));
    expect(find.text('05:00'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('a medication with no reminders says so on its detail', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await DriftMedicationRepository(
      app.db,
    ).upsert(const Medication(id: 'm1', name: 'Sumatriptan'));

    await openMedications(tester);
    expect(find.textContaining('No reminders'), findsOneWidget);

    await openMedication(tester, 'Sumatriptan');

    expect(find.text('Reminders'), findsOneWidget);
    expect(find.textContaining('No reminders yet.'), findsOneWidget);
    expect(find.text('Add reminder'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('searching by name narrows the list and clears on close', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    final repo = DriftMedicationRepository(app.db);
    await repo.upsert(const Medication(id: 'm1', name: 'Sumatriptan'));
    await repo.upsert(const Medication(id: 'm2', name: 'Ibuprofen'));

    await openMedications(tester);
    expect(find.text('Sumatriptan'), findsOneWidget);
    expect(find.text('Ibuprofen'), findsOneWidget);

    // Open the search field and type a partial, case-insensitive name.
    await tester.tap(find.byIcon(AppIconConstant.search));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField), 'ibu');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Ibuprofen'), findsOneWidget);
    expect(find.text('Sumatriptan'), findsNothing);

    // Closing search restores the full list.
    await tester.tap(find.byIcon(Symbols.arrow_back_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Sumatriptan'), findsOneWidget);
    expect(find.text('Ibuprofen'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('the reminder filter narrows the list', (tester) async {
    final app = await pumpApp(tester);
    final repo = DriftMedicationRepository(app.db);
    await repo.upsert(const Medication(id: 'm1', name: 'Sumatriptan'));
    await repo.upsert(const Medication(id: 'm2', name: 'Ibuprofen'));
    await app.db
        .into(app.db.medicationReminders)
        .insert(
          MedicationRemindersCompanion.insert(
            id: 'r1',
            medicationId: 'm1',
            minuteOfDay: 480,
          ),
        );

    await openMedications(tester);
    expect(find.text('Sumatriptan'), findsOneWidget);
    expect(find.text('Ibuprofen'), findsOneWidget);

    // Open the reminder filter chip (its sheet title) and pick "Has reminder". The strip scrolls sideways, so the chip is scrolled to first.
    await tester.ensureVisible(find.text('Reminder'));
    await tester.pump();
    await tester.tap(find.text('Reminder'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Has reminder'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Sumatriptan'), findsOneWidget);
    expect(find.text('Ibuprofen'), findsNothing);

    await finishTest(tester);
  });
}
