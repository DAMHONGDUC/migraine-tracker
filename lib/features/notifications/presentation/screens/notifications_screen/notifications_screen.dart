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

    return SdScaffoldV2(
      title: Text(l10n.notificationsTitle, style: AppTextStyle.titleLarge),
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
                    icon: Icons.notifications_none,
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
