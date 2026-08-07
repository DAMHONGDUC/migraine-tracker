import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../features/notifications/providers.dart';
import '../../extensions/context_extensions.dart';
import '../../router/app_router.dart';
import '../settings_tile.dart';

/// Settings → Notifications, the second way into the list.
///
/// The dashboard's bell is the fast one; this is the one people find by
/// looking, which is the whole reason for having both.
///
/// Its value is how many are unread — the same number the bell carries, and
/// the only thing about the list worth stating before you open it. Nothing at
/// all when there are none: an empty row saying "0" is noise.
class NotificationsSettingsTile extends ConsumerWidget {
  const NotificationsSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int unread = ref.watch(unreadNotificationCountProvider).value ?? 0;

    return SettingsTile(
      icon: Icons.notifications_none,
      title: context.l10n.notificationsTitle,
      value: unread == 0 ? null : '$unread',
      onTap: () => context.pushNamed<void>(AppRoutes.notifications.name),
    );
  }
}
