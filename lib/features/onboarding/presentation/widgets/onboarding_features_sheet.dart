import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/constants/premium_limit_constant.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/app_feature_list.dart';
import '../../../../l10n/gen/app_localizations.dart';

/// What the app actually does, split into what stays free and what Premium adds.
class OnboardingFeaturesSheet extends StatelessWidget {
  const OnboardingFeaturesSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return SdSheetContentV2(
      title: l10n.appFeaturesTitle,
      closeTooltip: l10n.commonClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.appFeaturesBody(
              PremiumLimitConstant.freeHistoryWindow.inDays,
              PremiumLimitConstant.medications,
              PremiumLimitConstant.reminders,
            ),
            style: AppTextStyle.bodyLarge.secondary,
          ),
          SizedBox(height: SdSpacingConstant.h24),
          const AppFeatureList(),
        ],
      ),
    );
  }
}

/// Sheets expose their opener as `.show(context)`, never a top-level `showX` (CLAUDE.md § Code style).
extension OnboardingFeaturesSheetExt on OnboardingFeaturesSheet {
  Future<void> show(BuildContext context) => showSdBottomSheetV2<void>(
    context,
    isScrollControlled: true,
    builder: (_) => this,
  );
}
