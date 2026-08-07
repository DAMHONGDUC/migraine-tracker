import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication_reminder.dart';
import 'package:migraine_tracker/features/notifications/domain/entities/app_notification.dart';
import 'package:migraine_tracker/features/notifications/domain/enums/notification_kind.dart';
import 'package:migraine_tracker/features/notifications/domain/services/reminder_occurrence_materialiser.dart';

MedicationReminder reminder({
  String id = 'r1',
  String medicationId = 'm1',
  int minuteOfDay = 9 * 60,
  bool enabled = true,
  DateTime? createdAt,
}) => MedicationReminder(
  id: id,
  medicationId: medicationId,
  minuteOfDay: minuteOfDay,
  enabled: enabled,
  createdAt: createdAt,
);

void main() {
  const ReminderOccurrenceMaterialiser materialiser =
      ReminderOccurrenceMaterialiser();

  test('one occurrence per day, none later than now', () {
    final DateTime now = DateTime(2026, 8, 7, 12);

    final List<AppNotification> result = materialiser.occurrences(
      <MedicationReminder>[
        reminder(createdAt: DateTime(2026, 8, 4, 8).toUtc()),
      ],
      now: now,
    );

    // 4th, 5th, 6th, 7th — the 7th's 09:00 is behind the 12:00 "now".
    expect(result, hasLength(4));
    expect(result.map((AppNotification n) => n.occurredAt.toLocal().day), <int>[
      4,
      5,
      6,
      7,
    ]);
    expect(
      result.every((AppNotification n) => !n.occurredAt.isAfter(now.toUtc())),
      isTrue,
    );
  });

  test("today's reminder is left out until its time has passed", () {
    final DateTime now = DateTime(2026, 8, 7, 8, 59);

    final List<AppNotification> result = materialiser.occurrences(
      <MedicationReminder>[
        reminder(createdAt: DateTime(2026, 8, 6, 8).toUtc()),
      ],
      now: now,
    );

    expect(result.map((AppNotification n) => n.occurredAt.toLocal().day), <int>[
      6,
    ]);
  });

  test('two devices derive the same ids from the same reminders', () {
    final DateTime now = DateTime(2026, 8, 7, 12);
    final List<MedicationReminder> reminders = <MedicationReminder>[
      reminder(createdAt: DateTime(2026, 8, 1).toUtc()),
      reminder(
        id: 'r2',
        minuteOfDay: 21 * 60,
        createdAt: DateTime(2026, 8, 3).toUtc(),
      ),
    ];

    // The same pure call is what each device runs — no cursor, no state.
    final List<String> deviceA = materialiser
        .occurrences(reminders, now: now)
        .map((AppNotification n) => n.id)
        .toList();
    final List<String> deviceB = materialiser
        .occurrences(reminders.reversed.toList(), now: now)
        .map((AppNotification n) => n.id)
        .toList();

    expect(deviceA, deviceB, reason: 'input order must not change the result');
    expect(
      deviceA.toSet(),
      hasLength(deviceA.length),
      reason: 'ids are unique',
    );
    expect(deviceA.first, startsWith('rem:'));
  });

  test('a reminder created yesterday has no history from last month', () {
    final DateTime now = DateTime(2026, 8, 7, 12);

    final List<AppNotification> result = materialiser.occurrences(
      <MedicationReminder>[
        reminder(createdAt: DateTime(2026, 8, 6, 15).toUtc()),
      ],
      now: now,
    );

    // Created after yesterday's 09:00, so only today's has come round.
    expect(result.map((AppNotification n) => n.occurredAt.toLocal().day), <int>[
      7,
    ]);
  });

  test('a null createdAt falls back to the window, not to forever', () {
    final DateTime now = DateTime(2026, 8, 7, 12);

    final List<AppNotification> result = materialiser.occurrences(
      <MedicationReminder>[reminder()],
      now: now,
      window: const Duration(days: 3),
    );

    expect(result, hasLength(3));
    expect(
      result.first.occurredAt.toLocal().isAfter(
        now.subtract(const Duration(days: 4)),
      ),
      isTrue,
    );
  });

  test('a disabled reminder produces nothing', () {
    final List<AppNotification> result = materialiser.occurrences(
      <MedicationReminder>[
        reminder(enabled: false, createdAt: DateTime(2026, 8, 1).toUtc()),
      ],
      now: DateTime(2026, 8, 7, 12),
    );

    expect(result, isEmpty);
  });

  test('every occurrence carries its medication and reminder', () {
    final List<AppNotification> result = materialiser.occurrences(
      <MedicationReminder>[
        reminder(
          medicationId: 'sumatriptan',
          createdAt: DateTime(2026, 8, 6).toUtc(),
        ),
      ],
      now: DateTime(2026, 8, 7, 12),
    );

    expect(result.first.kind, NotificationKind.medicationReminder);
    expect(result.first.medicationId, 'sumatriptan');
    expect(result.first.reminderId, 'r1');
    expect(result.first.pressureDropHpa, isNull);
    expect(result.first.readAt, isNull);
  });

  test('a run over the same window twice derives identical ids', () {
    final DateTime now = DateTime(2026, 8, 7, 12);
    final List<MedicationReminder> reminders = <MedicationReminder>[
      reminder(createdAt: DateTime(2026, 7, 20).toUtc()),
    ];

    // What makes `addMissing` safe to call on every launch.
    expect(
      materialiser.occurrences(reminders, now: now).map((n) => n.id).toList(),
      materialiser.occurrences(reminders, now: now).map((n) => n.id).toList(),
    );
  });

  test('the window bounds a long-lived reminder', () {
    final List<AppNotification> result = materialiser.occurrences(
      <MedicationReminder>[reminder(createdAt: DateTime(2020).toUtc())],
      now: DateTime(2026, 8, 7, 12),
      window: const Duration(days: 30),
    );

    // The window opens on 8 July at 12:00, so that day's 09:00 is already
    // outside it: 30 occurrences, not 31.
    expect(result, hasLength(30));
    expect(result.first.occurredAt.toLocal(), DateTime(2026, 7, 9, 9));
    expect(result.last.occurredAt.toLocal(), DateTime(2026, 8, 7, 9));
  });
}
