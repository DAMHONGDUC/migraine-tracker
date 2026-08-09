import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/db/database_provider.dart';
import 'data/repositories/drift_notification_repository.dart';
import 'data/repositories/firestore_last_alert_repository.dart';
import 'domain/entities/app_notification.dart';
import 'domain/enums/notification_type.dart';
import 'domain/repositories/last_alert_repository.dart';
import 'domain/repositories/notification_repository.dart';
import 'presentation/controllers/notifications_controller.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => DriftNotificationRepository(ref.watch(databaseProvider)),
);

/// The alert the app may have missed while it was shut. Overridden with a
/// fake in `pumpApp` — the launch reconcile would otherwise reach Firebase
/// in every widget test.
final lastAlertRepositoryProvider = Provider<LastAlertRepository>(
  (ref) => FirestoreLastAlertRepository(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  ),
);

/// The list screen's rows, newest first.
final notificationsStreamProvider = StreamProvider<List<AppNotification>>(
  (ref) => ref.watch(notificationRepositoryProvider).watchAll(),
);

/// The number on the dashboard's bell, and the value on the Settings row.
/// Comes down one at a time — a row is read by opening its detail.
final unreadNotificationCountProvider = StreamProvider<int>(
  (ref) => ref.watch(notificationRepositoryProvider).watchUnreadCount(),
);

/// One tab's rows. The counts beside the tab labels are these lengths —
/// how many of that type there are, not how many are unread: the list is a
/// history, and its tabs say how much of each kind it holds.
final notificationsOfTypeProvider =
    Provider.family<List<AppNotification>, NotificationType>((ref, type) {
      final List<AppNotification> all =
          ref.watch(notificationsStreamProvider).value ??
          const <AppNotification>[];

      return all
          .where((AppNotification n) => n.type == type)
          .toList(growable: false);
    });

/// One notification by id, for [NotificationDetailScreen]. Null once the
/// GDPR wipe has taken it — the screen says so rather than showing a
/// stale row.
final notificationByIdProvider = Provider.family<AppNotification?, String>((
  ref,
  id,
) {
  final List<AppNotification> all =
      ref.watch(notificationsStreamProvider).value ?? const <AppNotification>[];

  for (final AppNotification notification in all) {
    if (notification.id == id) return notification;
  }
  return null;
});

/// Orchestrates the list (see [NotificationsController]).
final notificationsControllerProvider = Provider<NotificationsController>(
  NotificationsController.new,
);
