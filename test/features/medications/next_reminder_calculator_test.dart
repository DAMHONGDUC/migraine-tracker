import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication_reminder.dart';
import 'package:migraine_tracker/features/medications/domain/repositories/medication_reminder_repository.dart';
import 'package:migraine_tracker/features/medications/domain/services/next_reminder_calculator.dart';

MedicationReminderView _view(
  String name, {
  required int minuteOfDay,
  bool enabled = true,
}) => MedicationReminderView(
  reminder: MedicationReminder(
    id: '$name-$minuteOfDay',
    medicationId: name,
    minuteOfDay: minuteOfDay,
    enabled: enabled,
  ),
  medicationName: name,
);

void main() {
  const calculator = NextReminderCalculator();
  // 08:00 local — reminders above/below sit on either side of "now".
  final now = DateTime(2026, 7, 24, 8);

  test('no reminders yields null', () {
    expect(calculator.compute(const [], now: now), isNull);
  });

  test('picks the soonest still-upcoming reminder today', () {
    final next = calculator.compute([
      _view('Late', minuteOfDay: 22 * 60), // 22:00 today
      _view('Soon', minuteOfDay: 9 * 60), // 09:00 today
    ], now: now);

    expect(next, isNotNull);
    expect(next!.medicationName, 'Soon');
    expect(next.timeUntil, const Duration(hours: 1));
  });

  test('a time already passed today rolls to tomorrow', () {
    // Only reminder is 07:00 — already gone at 08:00, so next is tomorrow.
    final next = calculator.compute([
      _view('Morning', minuteOfDay: 7 * 60),
    ], now: now);

    expect(next!.medicationName, 'Morning');
    expect(next.timeUntil, const Duration(hours: 23));
  });

  test('disabled reminders are ignored', () {
    final next = calculator.compute([
      _view('Off', minuteOfDay: 9 * 60, enabled: false),
      _view('On', minuteOfDay: 18 * 60),
    ], now: now);

    expect(next!.medicationName, 'On');
  });

  test('all disabled yields null', () {
    final next = calculator.compute([
      _view('Off', minuteOfDay: 9 * 60, enabled: false),
    ], now: now);

    expect(next, isNull);
  });
}
