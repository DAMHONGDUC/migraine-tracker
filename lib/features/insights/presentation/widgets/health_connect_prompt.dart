import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../health/domain/enums/health_data_kind.dart';
import '../../../health/providers.dart';

/// What a card shows in place of a reading it has no permission for: what
/// connecting would give, and the button that asks for it.
///
/// **The button raises Apple's sheet right here** (owner's call). It used to
/// only say "connect it in Settings", which made the card a sign pointing at
/// another screen — the user is looking at the empty reading, so the fix
/// belongs where they are looking.
///
/// One widget for both sources, so the steps card and the sleep card cannot
/// word or wire the same prompt differently.
class HealthConnectPrompt extends ConsumerWidget {
  const HealthConnectPrompt({
    required this.kind,
    required this.message,
    super.key,
  });

  final HealthDataKind kind;

  /// Already localized: what this source would show once connected.
  final String message;

  Future<void> _connect(BuildContext context, WidgetRef ref) async {
    try {
      final bool answered = await ref
          .read(healthControllerProvider.notifier)
          .connect(kind);

      if (answered || !context.mounted) return;

      // iOS never reports a read *denial*, so "not answered" is the only
      // refusal this can see — say the sheet did not complete, not that
      // access was denied, which would be a guess.
      SdSnackBarUtilsV2.error(context, context.l10n.healthConnectFailed);
    } catch (error, stackTrace) {
      // The controller already logged and rethrew; this turns it into
      // something the user can read.
      SdLogger.error(
        LogTagConstant.health,
        'Health connect prompt failed',
        error: error,
        stackTrace: stackTrace,
      );
      if (context.mounted) {
        SdSnackBarUtilsV2.error(context, context.l10n.healthConnectFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(message, style: AppTextStyle.bodyMedium.secondary),
        SizedBox(height: SdSpacingConstant.h12),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: SdButtonV2(
            variant: SdButtonVariantV2.secondary,
            size: SdButtonSizeV2.small,
            icon: AppIconConstant.health,
            onPressed: () => _connect(context, ref),
            label: context.l10n.dashboardHealthConnect,
          ),
        ),
      ],
    );
  }
}
