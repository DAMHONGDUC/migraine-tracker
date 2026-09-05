import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../features/premium/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../constants/premium_limit_constant.dart';
import '../extensions/context_extensions.dart';
import '../theme/app_icon_constant.dart';
import '../theme/app_text_style.dart';
import 'premium_gate.dart';

/// Everything the app does, in one list, free group then premium group.
class AppFeatureList extends ConsumerWidget {
  const AppFeatureList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    // A subscriber has these already, so the badge would be telling them to buy what they bought. The group heading still says which half is which.
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
enum AppFeature {
  log(AppIconConstant.attackLog),
  history(AppIconConstant.history),
  medications(AppIconConstant.medication),
  reminders(AppIconConstant.reminderActive),
  widget(AppIconConstant.homeWidget),
  notifications(AppIconConstant.inbox),
  sync(AppIconConstant.synced),
  calm(AppIconConstant.darkMode),
  export(AppIconConstant.export, premium: true),
  alerts(AppIconConstant.notifications, premium: true),
  forecast(AppIconConstant.lineChart, premium: true),
  correlation(AppIconConstant.analysis, premium: true),
  activity(AppIconConstant.steps, premium: true),
  sleep(AppIconConstant.sleep, premium: true),
  report(AppIconConstant.exportPdf, premium: true);

  const AppFeature(this.icon, {this.premium = false});

  final IconData icon;
  final bool premium;

  static Iterable<AppFeature> get freeFeatures =>
      values.where((AppFeature feature) => !feature.premium);

  static Iterable<AppFeature> get premiumFeatures =>
      values.where((AppFeature feature) => feature.premium);

  /// Title and body together, so the pair can only ever come from one branch.
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
