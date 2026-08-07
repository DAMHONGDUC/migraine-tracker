import 'package:drift/drift.dart';

import '../../domain/enums/notification_type.dart';

/// Notifications the user was shown. Added in schema v8.
///
/// `AppNotifications`, not `Notifications`: the Dart class Drift generates
/// from the name would collide with Flutter's own `Notification`.
///
/// Rows are written by two paths that both derive [id] rather than minting
/// one — the reminder materialiser and the push handlers — so re-running
/// either can only overwrite a row with itself. That is what lets every
/// device rebuild the same list without coordinating.
@DataClassName('AppNotificationRow')
class AppNotifications extends Table {
  /// Derived: `rem:<reminderId>:<epochMinute>` or `pa:<eventId>`.
  TextColumn get id => text()();

  TextColumn get type => textEnum<NotificationType>()();

  /// When it fired (UTC).
  DateTimeColumn get occurredAt => dateTime()();

  /// Null while unread. Syncs like everything else, so reading on one device
  /// clears the badge on the others.
  DateTimeColumn get readAt => dateTime().nullable()();

  /// No `references` on purpose, unlike `MedicationReminders.medicationId`:
  /// deleting a medication cascades its reminders away, and the history of
  /// having been reminded must survive that.
  TextColumn get medicationId => text().nullable()();
  TextColumn get reminderId => text().nullable()();

  RealColumn get pressureDropHpa => real().nullable()();

  /// Sync state, same three columns and same reasoning as every other synced
  /// table: a revision decides what is dirty, [updatedAt] only settles which
  /// device's version wins.
  DateTimeColumn get updatedAt => dateTime().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  IntColumn get syncedRevision => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
