import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:uuid/uuid.dart';

import '../../helpers/pump_app.dart';

/// Adds [count] medications straight to the database, named so their
/// alphabetical order is predictable.
Future<void> _seedMedications(AppDatabase db, int count) async {
  const uuid = Uuid();
  for (var i = 0; i < count; i++) {
    await db
        .into(db.medications)
        .insert(
          MedicationsCompanion.insert(
            id: uuid.v4(),
            name: 'Medication ${i.toString().padLeft(2, '0')}',
          ),
        );
  }
}

/// Walks intensity → location → medication and stops on the medication step.
Future<void> _toMedicationStep(WidgetTester tester) async {
  await tester.tap(find.text('7'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(find.text('Right side'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(find.text('Next'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  // The medication grid's whole reason for existing is that a list long
  // enough to scroll costs time mid-attack. Measured on the 393×852 design
  // size the grid holds 16 medications plus its fixed first row, so this
  // guards against a change that quietly shrinks that.
  testWidgets('grid holds a realistic medication list without scrolling', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await _seedMedications(app.db, 12);
    await _toMedicationStep(tester);

    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).last)
        .position;

    expect(
      position.maxScrollExtent,
      0,
      reason: '12 medications must fit without scrolling',
    );

    await finishTest(tester);
  });

  testWidgets('the fixed first row leads the grid', (tester) async {
    final app = await pumpApp(tester);
    await _seedMedications(app.db, 12);
    await _toMedicationStep(tester);

    // "No medication" then "Add a medication" occupy row 1, above every
    // saved medication.
    final noneY = tester.getTopLeft(find.text('No medication')).dy;
    final addY = tester.getTopLeft(find.text('Add a medication')).dy;
    final firstMedY = tester.getTopLeft(find.text('Medication 00')).dy;

    expect(noneY, addY, reason: 'both sit in the same first row');
    expect(noneY, lessThan(firstMedY));

    await finishTest(tester);
  });
}
