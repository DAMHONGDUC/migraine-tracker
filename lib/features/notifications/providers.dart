import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/db/database_provider.dart';
import 'data/repositories/drift_notification_repository.dart';
import 'domain/entities/app_notification.dart';
import 'domain/repositories/notification_repository.dart';

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
