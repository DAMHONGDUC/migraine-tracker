import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_text_style.dart';

/// Spinner then percentage, for the trailing slot of a Settings row whose
/// work is running right now.
///
/// **Both, never just the spinner**: the spinner says the job is alive, the
/// number says how far — a row that only spins cannot tell slow work from
/// stuck work. Sync set that rule (hard rule 12) and the GDPR wipe follows
/// it, which is why this lives here rather than inside either row.
class SettingsRowProgress extends StatelessWidget {
  const SettingsRowProgress({required this.percent, super.key});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: SdSpacingConstant.r20,
          height: SdSpacingConstant.r20,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: SdSpacingConstant.w8),
        Text(
          context.l10n.commonProgressPercent(percent),
          style: AppTextStyle.bodyMedium.secondary,
        ),
      ],
    );
  }
}
