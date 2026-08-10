import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/constants/premium_limit_constant.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/app_feature_list.dart';
import '../../../../l10n/gen/app_localizations.dart';

/// What the app actually does, split into what stays free and what Premium
/// adds. Opened from the last onboarding step rather than sitting on a page of
/// its own: the list is a lot to read before the user has done anything, and
/// the ones who want it can ask for it.
///
/// The rows themselves are [AppFeatureList], shared with the About screen —
/// this sheet is the sentence about the free plan, and the sheet around it.
///
/// Informational only — no commit, so the header carries just the X.
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
              PremiumLimitConstant.attacks,
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

/// Sheets expose their opener as `.show(context)`, never a top-level
/// `showX` (CLAUDE.md § Code style).
extension OnboardingFeaturesSheetExt on OnboardingFeaturesSheet {
  Future<void> show(BuildContext context) => showSdBottomSheetV2<void>(
    context,
    isScrollControlled: true,
    builder: (_) => this,
  );
}
