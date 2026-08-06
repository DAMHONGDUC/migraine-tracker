import 'dart:io';

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

  /// Apple's own SDK-key prefix. RevenueCat treats a key carrying any OTHER
  /// platform's prefix as a programming error and calls `fatalError`.
  static const String _applePrefix = 'appl_';

  static const String _androidPrefix = 'goog_';

  /// The public SDK key for this platform.
  ///
  /// Throws when the build carries none. There is deliberately NO fallback:
  /// premium comes from RevenueCat entitlements and nothing else (CLAUDE.md),
  /// so a build without a key must fail loudly rather than quietly decide
  /// every user is free — or, worse, grow a client-side flag to stand in.
  static String get apiKey {
    final String key = AppEnv.revenueCatKey;

    if (!isUsableKey(key, forApple: Platform.isIOS || Platform.isMacOS)) {
      throw StateError(AppEnv.missingPurchasesConfigMessage);
    }
    return key;
  }

  /// Whether [key] is safe to hand to `Purchases.configure`.
  ///
  /// This exists because of what happens when it is not: RevenueCat's native
  /// SDK answers a wrong-platform key with `fatalError`, which kills the
  /// process. No Dart `catch` can survive that — the guards around
  /// `ensureConfigured` only ever caught Dart throws — and Swift keeps
  /// `fatalError` in release builds, so it lands on TestFlight and nowhere
  /// else. A placeholder like `test_...` was enough to do it.
  ///
  /// Rejects a key that carries some other platform's prefix, which is
  /// exactly the case the SDK refuses to survive. A key with no prefix at all
  /// is let through: those are RevenueCat's legacy keys, and it merely warns.
  static bool isUsableKey(String key, {required bool forApple}) {
    final String wanted = forApple ? _applePrefix : _androidPrefix;
    final String other = forApple ? _androidPrefix : _applePrefix;

    if (key.isEmpty) return false;
    if (key.startsWith(wanted)) return true;
    if (key.startsWith(other)) return false;
    // Anything else prefixed — `test_`, `strp_`, a half-filled template — is
    // the shape the SDK dies on.
    return !key.contains('_');
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
