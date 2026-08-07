import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../medications/domain/entities/medication.dart';
import '../../../../medications/providers.dart';
import '../../../domain/entities/app_notification.dart';
import '../../../domain/enums/notification_type.dart';
import '../../../providers.dart';

part 'notification_detail_screen_body.dart';

/// One notification, in full: what it said, when, and the one place it leads.
///
/// Every row in the list opens this, whatever its type — the type decides
/// what the screen offers, not whether the user gets a screen at all. That is
/// what makes the list uniform to use: one tap, one destination, always.
class NotificationDetailScreen extends ConsumerWidget {
  const NotificationDetailScreen({required this.notificationId, super.key});

  final String notificationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AppNotification? notification = ref.watch(
      notificationByIdProvider(notificationId),
    );

    // Wiped from under us, or a stale link: nothing to show.
    if (notification == null) {
      return SdScaffoldV2(
        title: Text(l10n.notificationsTitle, style: AppTextStyle.titleLarge),
        body: SdEmptyStateV2(
          icon: Icons.notifications_none,
          message: l10n.notificationDetailMissing,
        ),
      );
    }

    return SdScaffoldV2(
      title: Text(l10n.notificationsTitle, style: AppTextStyle.titleLarge),
      body: _Body(notification: notification),
    );
  }
}
