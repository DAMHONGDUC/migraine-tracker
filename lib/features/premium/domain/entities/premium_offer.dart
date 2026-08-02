import 'package:meta/meta.dart';

import '../enums/premium_period.dart';

/// One buyable package, as the paywall needs to render it.
///
/// [priceLabel] is the store's own formatted string ("$5.99", "39,99 €") and
/// is never assembled in Dart: the currency, its position and the decimal
/// separator all belong to the storefront the customer is buying from, and a
/// price the app formats itself is a price that will be wrong somewhere.
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

  /// Length of the introductory free trial, when the package has one. Null
  /// means no trial, which is not the same as a zero-day one.
  final int? trialDays;

  bool get hasTrial => (trialDays ?? 0) > 0;
}
