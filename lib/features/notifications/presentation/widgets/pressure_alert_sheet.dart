import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/app_notification.dart';

/// What one pressure alert said, and a way through to the forecast it came
/// from.
///
/// A sheet rather than a screen: there is one number and one time to read,
/// and a pushed route for that much would be a place the user has to come
/// back from.
class PressureAlertSheet extends StatelessWidget {
  const PressureAlertSheet({required this.notification, super.key});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final DateTime at = notification.occurredAt.toLocal();
    final double? drop = notification.pressureDropHpa;

    return SdSheetContentV2(
      title: l10n.notificationPressureTitle,
      closeTooltip: l10n.commonClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            DateFormat.yMMMMd(l10n.localeName).add_Hm().format(at),
            style: AppTextStyle.bodyMedium.secondary,
          ),
          SizedBox(height: SdSpacingConstant.h12),
          // A drop the payload did not carry leaves the reading out rather
          // than printing a zero the forecast never said.
          if (drop != null)
            Text(
              l10n.notificationPressureBody(
                NumberFormat.decimalPattern(l10n.localeName).format(drop.abs()),
              ),
              style: AppTextStyle.bodyLarge,
            ),
          SizedBox(height: SdSpacingConstant.h20),
          SdButtonV2(
            variant: SdButtonVariantV2.secondary,
            icon: Icons.show_chart,
            onPressed: () {
              Navigator.of(context).pop();
              context.pushNamed<void>(AppRoutes.pressure.name);
            },
            label: l10n.notificationPressureAction,
          ),
        ],
      ),
    );
  }
}

/// Sheets expose their opener as `.show(context)`, never a top-level `showX`
/// (CLAUDE.md § Code style).
extension PressureAlertSheetExt on PressureAlertSheet {
  Future<void> show(BuildContext context) => showSdBottomSheetV2<void>(
    context,
    isScrollControlled: true,
    builder: (_) => this,
  );
}
