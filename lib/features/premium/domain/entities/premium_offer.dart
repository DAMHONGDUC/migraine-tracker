import 'package:meta/meta.dart';

import '../enums/premium_period.dart';

/// One buyable package, as the paywall needs to render it.
@immutable
class PremiumOffer {
  const PremiumOffer({
    required this.id,
    required this.period,
    required this.priceLabel,
    this.trialDays,
  });

  /// RevenueCat package identifier — what gets passed back to purchase it.
  final String id;

  final PremiumPeriod period;
  final String priceLabel;

  /// Length of the introductory free trial, when the package has one. Null means no trial, which is not the same as a zero-day one.
  final int? trialDays;

  bool get hasTrial => (trialDays ?? 0) > 0;
}
