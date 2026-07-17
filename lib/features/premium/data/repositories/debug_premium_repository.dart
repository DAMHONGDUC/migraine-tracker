import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/premium_repository.dart';

/// TEMPORARY: local flag so premium paths are buildable and testable before
/// RevenueCat exists. A client-writable flag is NOT acceptable in
/// production (CLAUDE.md: premium comes from RevenueCat entitlements) — this
/// class is replaced wholesale by a RevenueCatPremiumRepository, and
/// [setPremium] disappears with it.
class DebugPremiumRepository implements PremiumRepository {
  DebugPremiumRepository(this._prefs);

  final SharedPreferences _prefs;
  final _controller = StreamController<bool>.broadcast();

  static const prefsKey = 'debug_premium';

  @override
  bool get isPremium => _prefs.getBool(prefsKey) ?? false;

  @override
  Stream<bool> watchIsPremium() async* {
    yield isPremium;
    yield* _controller.stream;
  }

  /// Debug-only entitlement override.
  Future<void> setPremium(bool value) async {
    await _prefs.setBool(prefsKey, value);
    _controller.add(value);
  }

  void dispose() => _controller.close();
}
