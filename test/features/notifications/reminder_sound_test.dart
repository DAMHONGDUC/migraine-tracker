import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/medications/data/repositories/drift_medication_reminder_repository.dart';
import 'package:migraine_tracker/features/medications/data/repositories/drift_medication_repository.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication_reminder.dart';
import 'package:migraine_tracker/features/medications/presentation/controllers/reminder_sound_controller.dart';

import '../../helpers/pump_app.dart';

/// The switch on the notification list decides whether a reminder makes a
/// sound. The sound is baked into a scheduled notification, so flipping it
/// has to re-lay every reminder — a setting nothing acts on is worse than
/// none, because the user believes it worked.
Future<void> seedReminder(PumpedApp app) async {
  await DriftMedicationRepository(
    app.db,
  ).upsert(const Medication(id: 'm1', name: 'Sumatriptan'));
  await DriftMedicationReminderRepository(app.db).upsert(
    const MedicationReminder(id: 'r1', medicationId: 'm1', minuteOfDay: 480),
  );
}

void main() {
  testWidgets('sound is on until the user says otherwise', (tester) async {
    await pumpApp(tester);
    await openNotifications(tester);

    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue);

    await finishTest(tester);
  });

  testWidgets('turning it off reschedules every reminder silently', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester);
    await seedReminder(app);
    await tester.pump();
    await openNotifications(tester);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Rescheduled, and with the new answer — anything already queued would
    // otherwise keep making a sound until it fired.
    expect(app.scheduler.scheduledWithSound, isFalse);
    expect(app.prefs.getBool(ReminderSoundController.key), isFalse);

    await finishTest(tester);
  });

  testWidgets('the choice survives a restart', (tester) async {
    final PumpedApp app = await pumpApp(
      tester,
      initialPrefs: <String, Object>{ReminderSoundController.key: false},
    );
    await seedReminder(app);
    await tester.pump();
    await openNotifications(tester);

    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse);

    await finishTest(tester);
  });
}
