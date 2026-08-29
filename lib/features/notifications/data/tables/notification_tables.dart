import 'package:drift/drift.dart';

import '../../domain/enums/notification_type.dart';

/// Notifications the user was shown.
@DataClassName('AppNotificationRow')
class AppNotifications extends Table {
  /// Derived: `rem:<reminderId>:<epochMinute>` or `pa:<eventId>`.
  TextColumn get id => text()();

  TextColumn get type => textEnum<NotificationType>()();

  /// When it fired (UTC).
  DateTimeColumn get occurredAt => dateTime()();

  /// Null while unread. Syncs like everything else, so reading on one device clears the badge on the others.
  DateTimeColumn get readAt => dateTime().nullable()();

  /// No `references` on purpose, unlike `MedicationReminders.medicationId`.
  TextColumn get medicationId => text().nullable()();
  TextColumn get reminderId => text().nullable()();

  RealColumn get pressureDropHpa => real().nullable()();

  /// Sync state, same three columns and same reasoning as every other synced table.
  DateTimeColumn get updatedAt => dateTime().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  IntColumn get syncedRevision => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
