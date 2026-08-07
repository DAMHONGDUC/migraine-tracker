import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/db/database_provider.dart';
import 'data/repositories/drift_notification_repository.dart';
import 'domain/entities/app_notification.dart';
import 'domain/repositories/notification_repository.dart';
import 'presentation/controllers/notifications_controller.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => DriftNotificationRepository(ref.watch(databaseProvider)),
);

/// The list screen's rows, newest first.
final notificationsStreamProvider = StreamProvider<List<AppNotification>>(
  (ref) => ref.watch(notificationRepositoryProvider).watchAll(),
);

/// Drives the dashboard's unread dot. A count rather than a bool so the dot
/// can carry a number later without changing what feeds it.
final unreadNotificationCountProvider = StreamProvider<int>(
  (ref) => ref.watch(notificationRepositoryProvider).watchUnreadCount(),
);

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
