import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../providers.dart';

/// Keeps the store's idea of who is buying in step with the account.
class PurchaseIdentity {
  PurchaseIdentity(this._ref);

  final Ref _ref;

  /// The UID currently bound, so an unchanged auth state is not re-sent — `logIn` is a network call and the auth stream fires on every launch.
  String? _boundUid;

  /// [uid] null = signed out (or anonymous, which has nothing durable to attach a purchase to).
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
