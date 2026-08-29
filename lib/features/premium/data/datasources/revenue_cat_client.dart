import 'dart:io';

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/env/app_env.dart';

/// Owns the one-time `Purchases.configure` and the entitlement name.
class RevenueCatClient {
  RevenueCatClient();

  Future<void>? _configuring;

  /// Apple's own SDK-key prefix. RevenueCat treats a key carrying any OTHER platform's prefix as a programming error and calls `fatalError`.
  static const String _applePrefix = 'appl_';

  static const String _androidPrefix = 'goog_';

  /// The public SDK key for this platform.
  static String get apiKey {
    final String key = AppEnv.revenueCatKey;

    if (!isUsableKey(key, forApple: Platform.isIOS || Platform.isMacOS)) {
      throw StateError(AppEnv.missingPurchasesConfigMessage);
    }
    return key;
  }

  /// Whether [key] is safe to hand to `Purchases.configure`.
  static bool isUsableKey(String key, {required bool forApple}) {
    final String wanted = forApple ? _applePrefix : _androidPrefix;
    final String other = forApple ? _androidPrefix : _applePrefix;

    if (key.isEmpty) return false;
    if (key.startsWith(wanted)) return true;
    if (key.startsWith(other)) return false;
    // Anything else prefixed — `test_`, `strp_`, a half-filled template — is the shape the SDK dies on.
    return !key.contains('_');
  }

  /// The entitlement that means "premium", as named in the dashboard.
  static String get entitlementId => AppEnv.revenueCatEntitlement;

  /// Configures the SDK once. Concurrent callers await the same future rather than each starting their own `configure`.
  Future<void> ensureConfigured() {
    return _configuring ??= _configure();
  }

  Future<void> _configure() async {
    // The key itself is never logged; its prefix is what diagnoses a misconfigured build, and a `test_` one is the crash this guards.
    final Map<String, Object?> what = <String, Object?>{
      'keyPrefix': apiKey.length < 5 ? '' : apiKey.substring(0, 5),
      'entitlement': entitlementId,
    };

    SdLogger.action(LogTagConstant.revenueCat, 'Configure RevenueCat', what);
    try {
      await Purchases.configure(PurchasesConfiguration(apiKey));
      SdLogger.info(LogTagConstant.revenueCat, 'RevenueCat configured', what);
    } catch (error, stackTrace) {
      // A StateError from `apiKey` lands here, which is the handled "no key in this build" path the paywall reports as notConfigured.
      SdLogger.error(
        LogTagConstant.revenueCat,
        'Configure RevenueCat failed',
        error: error,
        stackTrace: stackTrace,
        data: what,
      );
      rethrow;
    }
  }

  /// Whether [info] carries the premium entitlement right now.
  static bool isEntitled(CustomerInfo info) =>
      info.entitlements.active.containsKey(entitlementId);
}
