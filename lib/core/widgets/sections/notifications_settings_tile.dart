import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../features/notifications/providers.dart';
import '../../extensions/context_extensions.dart';
import '../../router/app_router.dart';
import '../../theme/app_icon_constant.dart';
import '../settings_tile.dart';

/// Settings → Notifications, the second way into the list.
class NotificationsSettingsTile extends ConsumerWidget {
  const NotificationsSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int unread = ref.watch(unreadNotificationCountProvider).value ?? 0;

    return SettingsTile(
      icon: AppIconConstant.notifications,
      title: context.l10n.notificationsTitle,
      value: unread == 0 ? null : SdBadgeV2.formatCount(unread),
      onTap: () => context.pushNamed<void>(AppRoutes.notifications.name),
    );
  }
}
