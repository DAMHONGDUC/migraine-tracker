import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/features/medications/data/repositories/drift_medication_repository.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication.dart';
import 'package:system_design/index.dart';

import '../../helpers/pump_app.dart';

Future<void> addMedication(WidgetTester tester, String name) async {
  // App bar "+" icon — a FAB would sit under the floating nav's hit region
  // on a shell tab, so the add action lives here instead (see MedicationsScreen).
  await tester.tap(find.byIcon(Icons.add));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.enterText(
    find.widgetWithText(TextField, 'Medication name'),
    name,
  );
  await tester.tap(find.text('Add'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Opens a medication's detail screen from its row in the list.
Future<void> openMedication(WidgetTester tester, String name) async {
  await tester.tap(find.text(name));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// The delete button ON a reminder row — the detail screen's app bar carries
/// the same icon for deleting the medication itself, so a bare byIcon
/// matches two.
Finder reminderDelete() => find.descendant(
  of: find.byType(SdCardV2),
  matching: find.byIcon(Icons.delete_outline),
);

/// Opens the reminder picker. Reminders live on the detail screen, so the
/// caller has to be there already.
Future<void> openAddReminder(WidgetTester tester) async {
  await tester.tap(find.text('Add reminder'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('shows the empty state when no medications are saved', (
    tester,
  ) async {
    await pumpApp(tester);
    await openMedications(tester);

    expect(find.text('No medications yet.'), findsOneWidget);

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

    // The name is edited in place on its own field, not via a dialog — it
    // commits when the field loses focus (here, "done" on the keyboard).
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
    await tester.tap(find.byIcon(Icons.delete_outline));
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

    // - custom wheel picker sheet (AppTimePickerSheet) — two wheels (hour + minute) confirm it's open
    // - the checkmark saves the default (current) time without touching the wheels
    expect(find.byType(ListWheelScrollView), findsNWidgets(2));
    await tester.tap(find.byIcon(Icons.check));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(Icons.alarm), findsOneWidget);
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
    expect(find.byIcon(Icons.alarm), findsNothing);

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
    // Edit mode shows the confirm action as a pencil (Icons.edit), not a check.
    await tester.tap(find.byIcon(Icons.edit));
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

    // - over-drag the hour wheel (first ListWheelScrollView) UP past the end so it clamps at 23
    // - independent of the current-time default the picker opens on
    // - dragging up brings higher-index rows to the centered selection; row height is SdSpacingConstant.h44 (44px at the pinned 393×852 design size)
    await tester.drag(
      find.byType(ListWheelScrollView).first,
      const Offset(0, -44 * 30),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(Icons.check));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // The saved hour is whatever the wheel was dragged to (23), proving the
    // wheel drives the stored time.
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
    expect(find.byIcon(Icons.alarm), findsNothing);
    expect(find.text('01:00'), findsNothing);

    await openMedication(tester, 'Sumatriptan');

    // All five, none collapsed away.
    expect(find.byIcon(Icons.alarm), findsNWidgets(5));
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
    await tester.tap(find.byIcon(Icons.search));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField), 'ibu');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Ibuprofen'), findsOneWidget);
    expect(find.text('Sumatriptan'), findsNothing);

    // Closing search restores the full list.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Sumatriptan'), findsOneWidget);
    expect(find.text('Ibuprofen'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('debug test-notification button reaches the scheduler', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await openMedications(tester);

    expect(app.scheduler.testScheduled, isFalse);
    await tester.tap(find.byIcon(Icons.notification_add_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(app.scheduler.testScheduled, isTrue);
    expect(find.textContaining('Test notification in 10s'), findsOneWidget);

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

    // Open the reminder filter chip (its sheet title) and pick "Has reminder".
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
