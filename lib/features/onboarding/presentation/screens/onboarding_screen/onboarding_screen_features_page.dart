part of 'onboarding_screen.dart';

/// The one page that says what the app actually does, split into what stays
/// free and what Premium adds. Shown before the two permission-ish pages, so
/// the user knows what they are agreeing to help with.
///
/// This page scrolls; the other three are short enough to centre. Nine rows
/// do not fit a small phone, and a feature list that silently cuts off is
/// worse than no list.
class _FeaturesPage extends StatelessWidget {
  const _FeaturesPage({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: SdContentPaddingV2.horizontal,
        vertical: SdSpacingConstant.h24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.onboardingFeaturesTitle,
            style: AppTextStyle.headlineMedium.w600,
          ),
          SizedBox(height: SdSpacingConstant.h12),
          Text(
            l10n.onboardingFeaturesBody,
            style: AppTextStyle.bodyLarge.secondary,
          ),
          SizedBox(height: SdSpacingConstant.h24),

          _FeatureGroupHeader(label: l10n.onboardingFeaturesFree),
          SdBenefitRowV2(
            icon: Icons.add_circle_outline,
            title: l10n.onboardingFeatureLogTitle,
            body: l10n.onboardingFeatureLogBody,
          ),
          SdBenefitRowV2(
            icon: Icons.calendar_month_outlined,
            title: l10n.onboardingFeatureHistoryTitle,
            body: l10n.onboardingFeatureHistoryBody,
          ),
          SdBenefitRowV2(
            icon: Icons.notifications_active_outlined,
            title: l10n.onboardingFeatureRemindersTitle,
            body: l10n.onboardingFeatureRemindersBody,
          ),
          SdBenefitRowV2(
            icon: Icons.ios_share_outlined,
            title: l10n.onboardingFeatureExportTitle,
            body: l10n.onboardingFeatureExportBody,
          ),

          SizedBox(height: SdSpacingConstant.h8),
          _FeatureGroupHeader(label: l10n.onboardingFeaturesPremium),
          const _PremiumFeature(
            icon: Icons.notifications_none,
            titleKey: _PremiumFeatureKey.alerts,
          ),
          const _PremiumFeature(
            icon: Icons.show_chart,
            titleKey: _PremiumFeatureKey.forecast,
          ),
          const _PremiumFeature(
            icon: Icons.analytics_outlined,
            titleKey: _PremiumFeatureKey.correlation,
          ),
          const _PremiumFeature(
            icon: Icons.bedtime_outlined,
            titleKey: _PremiumFeatureKey.sleep,
          ),
          const _PremiumFeature(
            icon: Icons.picture_as_pdf_outlined,
            titleKey: _PremiumFeatureKey.report,
          ),
        ],
      ),
    );
  }
}

/// Quiet label over a group of features.
class _FeatureGroupHeader extends StatelessWidget {
  const _FeatureGroupHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: SdSpacingConstant.h12),
      child: Text(
        label,
        style: AppTextStyle.labelLarge.copyWith(
          color: context.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Which premium feature a row is for — an enum rather than two string
/// parameters, so a row can never be given one feature's title and another's
/// body.
enum _PremiumFeatureKey { alerts, forecast, correlation, sleep, report }

/// A premium feature row: the same row as a free one, wearing the badge that
/// says it is not included yet.
class _PremiumFeature extends StatelessWidget {
  const _PremiumFeature({required this.icon, required this.titleKey});

  final IconData icon;
  final _PremiumFeatureKey titleKey;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final (String title, String body) = switch (titleKey) {
      _PremiumFeatureKey.alerts => (
        l10n.onboardingFeatureAlertsTitle,
        l10n.onboardingFeatureAlertsBody,
      ),
      _PremiumFeatureKey.forecast => (
        l10n.onboardingFeatureForecastTitle,
        l10n.onboardingFeatureForecastBody,
      ),
      _PremiumFeatureKey.correlation => (
        l10n.onboardingFeatureCorrelationTitle,
        l10n.onboardingFeatureCorrelationBody,
      ),
      _PremiumFeatureKey.sleep => (
        l10n.onboardingFeatureSleepTitle,
        l10n.onboardingFeatureSleepBody,
      ),
      _PremiumFeatureKey.report => (
        l10n.onboardingFeatureReportTitle,
        l10n.onboardingFeatureReportBody,
      ),
    };

    return SdBenefitRowV2(
      icon: icon,
      title: title,
      body: body,
      trailing: const PremiumBadge(),
    );
  }
}
