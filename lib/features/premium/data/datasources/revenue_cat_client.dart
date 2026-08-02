import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../../core/env/app_env.dart';

/// Owns the one-time `Purchases.configure` and the entitlement name.
///
/// Both premium repositories go through it so neither configures the SDK
/// itself — `configure` is not idempotent in a useful way, and two callers
/// racing it is how an app ends up with purchases bound to the wrong user.
class RevenueCatClient {
  RevenueCatClient();

  Future<void>? _configuring;

  /// The public SDK key for this platform.
  ///
  /// Throws when the build carries none. There is deliberately NO fallback:
  /// premium comes from RevenueCat entitlements and nothing else (CLAUDE.md),
  /// so a build without a key must fail loudly rather than quietly decide
  /// every user is free — or, worse, grow a client-side flag to stand in.
  static String get apiKey {
    final String key = AppEnv.revenueCatKey;

    if (key.isEmpty) throw StateError(AppEnv.missingPurchasesConfigMessage);

    return key;
  }

  /// The entitlement that means "premium", as named in the dashboard.
  static String get entitlementId => AppEnv.revenueCatEntitlement;

  /// Configures the SDK once. Concurrent callers await the same future
  /// rather than each starting their own `configure`.
  Future<void> ensureConfigured() {
    return _configuring ??= Purchases.configure(
      PurchasesConfiguration(apiKey),
    );
  }

  /// Whether [info] carries the premium entitlement right now.
  static bool isEntitled(CustomerInfo info) =>
      info.entitlements.active.containsKey(entitlementId);
}
