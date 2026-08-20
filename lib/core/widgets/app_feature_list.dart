import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../features/premium/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../constants/premium_limit_constant.dart';
import '../extensions/context_extensions.dart';
import '../theme/app_text_style.dart';
import 'premium_gate.dart';

/// Everything the app does, in one list, free group then premium group.
///
/// Shared by the onboarding sheet and the About screen, which is why it lives
/// here rather than in either feature: two copies of this list would be two
/// places to forget a feature when one ships.
class AppFeatureList extends ConsumerWidget {
  const AppFeatureList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    // A subscriber has these already, so the badge would be telling them to
    // buy what they bought. The group heading still says which half is which.
    final bool badges = !ref.watch(hasPremiumProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _FeatureGroupHeader(label: l10n.appFeaturesFree),
        for (final AppFeature feature in AppFeature.freeFeatures)
          _FeatureRow(feature: feature, badge: false),
        SizedBox(height: SdSpacingConstant.h8),
        _FeatureGroupHeader(label: l10n.appFeaturesPremium),
        for (final AppFeature feature in AppFeature.premiumFeatures)
          _FeatureRow(feature: feature, badge: badges),
      ],
    );
  }
}

/// One feature, and which half of the offer it belongs to.
///
/// An enum rather than a list of (icon, title, body) triples at the call
/// site: a row can then never be handed one feature's title and another's
/// body, and adding a feature is one entry in one place.
enum AppFeature {
  log(Icons.add_circle_outline),
  history(Icons.calendar_month_outlined),
  medications(Icons.medication_outlined),
  reminders(Icons.notifications_active_outlined),
  widget(Icons.widgets_outlined),
  notifications(Icons.inbox_outlined),
  sync(Icons.cloud_done_outlined),
  // Free because hard rule 8 makes it a promise: export moved behind the
  // paywall, the wipe never can.
  wipe(Icons.delete_outline),
  calm(Icons.dark_mode_outlined),
  export(Icons.ios_share_outlined, premium: true),
  alerts(Icons.notifications_none, premium: true),
  forecast(Icons.show_chart, premium: true),
  correlation(Icons.analytics_outlined, premium: true),
  activity(Icons.directions_walk, premium: true),
  sleep(Icons.bedtime_outlined, premium: true),
  report(Icons.picture_as_pdf_outlined, premium: true);

  const AppFeature(this.icon, {this.premium = false});

  final IconData icon;
  final bool premium;

  static Iterable<AppFeature> get freeFeatures =>
      values.where((AppFeature feature) => !feature.premium);

  static Iterable<AppFeature> get premiumFeatures =>
      values.where((AppFeature feature) => feature.premium);

  /// Title and body together, so the pair can only ever come from one branch.
  ///
  /// The three capped features say their limit in the row itself, and the
  /// number comes from [PremiumLimitConstant] rather than the string: the
  /// About screen is where a user goes to find out what the free plan holds,
  /// and a copy of "40" in an ARB file is a copy that outlives the change
  /// that moves the limit.
  (String, String) copy(AppLocalizations l10n) => switch (this) {
    AppFeature.log => (
      l10n.appFeatureLogTitle,
      l10n.appFeatureLogBody(PremiumLimitConstant.attacks),
    ),
    AppFeature.history => (
      l10n.appFeatureHistoryTitle,
      l10n.appFeatureHistoryBody,
    ),
    AppFeature.medications => (
      l10n.appFeatureMedicationsTitle,
      l10n.appFeatureMedicationsBody(PremiumLimitConstant.medications),
    ),
    AppFeature.reminders => (
      l10n.appFeatureRemindersTitle,
      l10n.appFeatureRemindersBody(PremiumLimitConstant.reminders),
    ),
    AppFeature.widget => (
      l10n.appFeatureWidgetTitle,
      l10n.appFeatureWidgetBody,
    ),
    AppFeature.notifications => (
      l10n.appFeatureNotificationsTitle,
      l10n.appFeatureNotificationsBody,
    ),
    AppFeature.sync => (l10n.appFeatureSyncTitle, l10n.appFeatureSyncBody),
    AppFeature.wipe => (l10n.appFeatureWipeTitle, l10n.appFeatureWipeBody),
    AppFeature.calm => (l10n.appFeatureCalmTitle, l10n.appFeatureCalmBody),
    AppFeature.export => (
      l10n.appFeatureExportTitle,
      l10n.appFeatureExportBody,
    ),
    AppFeature.alerts => (
      l10n.appFeatureAlertsTitle,
      l10n.appFeatureAlertsBody,
    ),
    AppFeature.forecast => (
      l10n.appFeatureForecastTitle,
      l10n.appFeatureForecastBody,
    ),
    AppFeature.correlation => (
      l10n.appFeatureCorrelationTitle,
      l10n.appFeatureCorrelationBody,
    ),
    AppFeature.activity => (
      l10n.appFeatureActivityTitle,
      l10n.appFeatureActivityBody,
    ),
    AppFeature.sleep => (l10n.appFeatureSleepTitle, l10n.appFeatureSleepBody),
    AppFeature.report => (
      l10n.appFeatureReportTitle,
      l10n.appFeatureReportBody,
    ),
  };
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature, required this.badge});

  final AppFeature feature;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final (String title, String body) = feature.copy(context.l10n);

    return SdBenefitRowV2(
      icon: feature.icon,
      title: title,
      body: body,
      trailing: badge ? const PremiumBadge() : null,
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
