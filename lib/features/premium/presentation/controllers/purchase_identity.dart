import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../providers.dart';

/// Keeps the store's idea of who is buying in step with the account.
///
/// RevenueCat identifies customers by its own app-user id. Left alone that
/// is a per-install anonymous id, and an entitlement bought on one device
/// would not exist on the next — so it is bound to the Firebase UID the
/// moment there is one, and released on sign-out so the next account on a
/// shared device does not inherit it.
///
/// **An anonymous purchase is a first-class one** (App Store 5.1.1(v): buying
/// cannot require registration). It lives under RevenueCat's own anonymous id
/// until the user signs in, and `logIn` then carries it onto the account —
/// which is exactly what the paywall's sign-in link offers to do.
class PurchaseIdentity {
  PurchaseIdentity(this._ref);

  final Ref _ref;

  /// The UID currently bound, so an unchanged auth state is not re-sent —
  /// `logIn` is a network call and the auth stream fires on every launch.
  /// Per instance, never static: one ProviderScope is one app, and a static
  /// would carry one run's binding into the next (which is exactly what it
  /// did across tests in the same file).
  String? _boundUid;

  /// [uid] null = signed out (or anonymous, which has nothing durable to
  /// attach a purchase to).
  ///
  /// Never throws: purchases failing to identify must not take down the app
  /// root's auth listener. The worst case is an entitlement that does not
  /// follow the user until the next launch, which the logs will show.
  Future<void> sync(String? uid) async {
    if (uid == _boundUid) return;

    try {
      if (uid == null) {
        await _ref.read(purchaseRepositoryProvider).forget();
      } else {
        await _ref.read(purchaseRepositoryProvider).identify(uid);
      }
      _boundUid = uid;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.purchase,
        'Binding purchases to the account failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
