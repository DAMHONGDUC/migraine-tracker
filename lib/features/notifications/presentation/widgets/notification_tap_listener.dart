import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/router/navigation_utils.dart';
import '../../providers.dart';
import '../controllers/notifications_controller.dart';

/// Turns a tapped OS notification into the detail screen for the row behind it — whatever the app was doing at the time.
class NotificationTapListener extends HookConsumerWidget {
  const NotificationTapListener({required this.child, super.key});

  final Widget child;

  /// Resolves one tap and opens what it points at.
  Future<void> _open(WidgetRef ref, Future<String?> Function() resolve) async {
    try {
      final String? notificationId = await resolve();

      if (notificationId == null) return;

      // Before the navigator is touched, because the splash ends by replacing
      // the stack: a detail pushed over those dots was wiped a second later
      // and the user landed on the dashboard instead of the notification they
      // tapped. `whenPastSplash` is already resolved on a warm tap.
      await NavigationUtils.whenPastSplash(ref.read(appRouterProvider));

      final BuildContext? context = ref
          .read(rootNavigatorKeyProvider)
          .currentContext;

      if (context == null || !context.mounted) return;

      await NavigationUtils.toNotification(context, notificationId);
    } catch (_) {
      // Already logged where it happened.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      final NotificationsController controller = ref.read(
        notificationsControllerProvider,
      );
      final StreamSubscription<String> reminders = ref
          .read(notificationSchedulerProvider)
          .reminderTaps
          .listen(
            (String reminderId) => unawaited(
              _open(ref, () => controller.reminderTapTarget(reminderId)),
            ),
          );
      final StreamSubscription<RemoteMessage> alerts = FirebaseMessaging
          .onMessageOpenedApp
          .listen(
            (RemoteMessage message) => unawaited(
              _open(ref, () => controller.pushTapTarget(message.data)),
            ),
          );

      // The other half: whichever notification started the app, if any. Both are taken once — a second read would reopen the same screen on the next resume.
      unawaited(
        _open(ref, () async {
          final String? reminderId = await ref
              .read(notificationSchedulerProvider)
              .takeLaunchReminderId();

          return reminderId == null
              ? null
              : controller.reminderTapTarget(reminderId);
        }),
      );
      unawaited(
        _open(ref, () async {
          final RemoteMessage? message = await FirebaseMessaging.instance
              .getInitialMessage();

          return message == null
              ? null
              : controller.pushTapTarget(message.data);
        }),
      );

      return () {
        unawaited(reminders.cancel());
        unawaited(alerts.cancel());
      };
    }, const <Object?>[]);

    return child;
  }
}
