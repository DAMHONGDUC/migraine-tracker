/// The billing shapes the app sells (PLAN.md §3). Anything the store offers
/// that isn't one of these is not shown — a paywall that renders whatever
/// arrives can quietly start selling a package nobody designed a row for.
///
/// Lifetime was sold until 2026-08-29 and is deliberately gone: a
/// non-consumable cannot be re-monetized, and the two subscriptions are the
/// whole offer now. The store may still own the old product for whoever
/// bought one — their entitlement keeps working, it simply has no row here.
enum PremiumPeriod { monthly, yearly }
