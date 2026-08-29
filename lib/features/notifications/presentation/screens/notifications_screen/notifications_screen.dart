import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/navigation_utils.dart';
import '../../../../../core/theme/app_icon_constant.dart';
import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../medications/providers.dart';
import '../../../domain/entities/app_notification.dart';
import '../../../domain/enums/notification_type.dart';
import '../../../providers.dart';

part 'notifications_screen_tile.dart';

/// Everything the app has told the user, split by what told it: medication
/// reminders on one tab, pressure alerts on the other.
///
/// Two tabs rather than one mixed list because the two answer different
/// questions — "have I been taking this" and "was there weather" — and a
/// reminder arriving every day would otherwise bury the alerts entirely.
///
/// Opening the screen reads nothing: a row is read when its detail is
/// opened, so the dot on a row means what it says.
///
/// The app bar carries the unread count in full, uncapped — unlike the bell
/// and the Settings row, which cap at [SdBadgeV2.maxCount] because a badge
/// that grows covers the icon under it. Here it is a line of text with a bar
/// to itself, so there is nothing to protect it from and no reason to round.
class NotificationsScreen extends HookConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ValueNotifier<int> selected = useState<int>(0);
    final List<AppNotification> reminders = ref.watch(
      notificationsOfTypeProvider(NotificationType.medicationReminder),
    );
    final List<AppNotification> alerts = ref.watch(
      notificationsOfTypeProvider(NotificationType.pressureAlert),
    );
    final List<AppNotification> shown = selected.value == 0
        ? reminders
        : alerts;
    final int unread = ref.watch(unreadNotificationCountProvider).value ?? 0;

    return SdScaffoldV2(
      title: Text(l10n.notificationsTitle, style: AppTextStyle.titleLarge),
      actions: unread == 0
          ? null
          : <Widget>[
              _UnreadCount(unread: unread),
              SizedBox(width: SdContentPaddingV2.horizontal),
            ],
      body: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(
              SdContentPaddingV2.horizontal,
              SdContentPaddingV2.top(context),
              SdContentPaddingV2.horizontal,
              0,
            ),
            child: SdSegmentedTabsV2(
              selectedIndex: selected.value,
              onSelected: (int index) => selected.value = index,
              segments: <SdSegmentV2>[
                SdSegmentV2(
                  label: l10n.notificationsTabReminders,
                  count: reminders.length,
                ),
                SdSegmentV2(
                  label: l10n.notificationsTabAlerts,
                  count: alerts.length,
                ),
              ],
            ),
          ),
          Expanded(
            child: shown.isEmpty
                ? SdEmptyStateV2(
                    icon: AppIconConstant.notifications,
                    message: selected.value == 0
                        ? l10n.notificationsEmptyReminders
                        : l10n.notificationsEmptyAlerts,
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      SdContentPaddingV2.horizontal,
                      SdContentPaddingV2.listItemGap,
                      SdContentPaddingV2.horizontal,
                      SdContentPaddingV2.bottom(context),
                    ),
                    itemCount: shown.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        SizedBox(height: SdContentPaddingV2.listItemGap),
                    itemBuilder: (BuildContext context, int index) =>
                        _NotificationTile(notification: shown[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

/// How many are unread, at the end of the app bar.
///
/// The error colour, like the bell's badge and the rows' dots — the three
/// mark the same thing and must not read as three different things. Plain
/// text and not a chip: the bell is the one place a count wears a filled
/// pill, and a second one here would compete with the title beside it.
class _UnreadCount extends StatelessWidget {
  const _UnreadCount({required this.unread});

  final int unread;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.notificationsA11yUnread(unread),
      child: ExcludeSemantics(
        child: Text(
          '$unread',
          style: AppTextStyle.titleMedium.copyWith(
            color: context.colorScheme.error,
          ),
        ),
      ),
    );
  }
}
