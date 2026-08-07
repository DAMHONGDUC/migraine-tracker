import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../medications/providers.dart';
import '../../../domain/entities/app_notification.dart';
import '../../../domain/enums/notification_kind.dart';
import '../../../providers.dart';
import '../../widgets/pressure_alert_sheet.dart';

part 'notifications_screen_tile.dart';

/// Everything the app has told the user, newest first: medication reminders
/// that came round, and pressure alerts that arrived.
///
/// Opening it marks the lot read — one act, and the rows only differ by when
/// they arrived, so there is no per-row read state to fiddle with.
class NotificationsScreen extends HookConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final List<AppNotification> notifications =
        ref.watch(notificationsStreamProvider).value ??
        const <AppNotification>[];

    // Once per mount, not on every rebuild: the stream ticks as rows arrive.
    useEffect(() {
      ref.read(notificationsControllerProvider).markAllRead();
      return null;
    }, const <Object?>[]);

    return SdScaffoldV2(
      title: Text(l10n.notificationsTitle, style: AppTextStyle.titleLarge),
      body: notifications.isEmpty
          ? SdScrollFillV2(
              topInset: SdContentPaddingV2.appBarInset(context),
              child: SdEmptyStateV2(
                icon: Icons.notifications_none,
                message: l10n.notificationsEmpty,
              ),
            )
          : ListView.separated(
              padding: SdContentPaddingV2.screen(context),
              itemCount: notifications.length,
              separatorBuilder: (BuildContext context, int index) =>
                  SizedBox(height: SdContentPaddingV2.listItemGap),
              itemBuilder: (BuildContext context, int index) =>
                  _NotificationTile(notification: notifications[index]),
            ),
    );
  }
}
