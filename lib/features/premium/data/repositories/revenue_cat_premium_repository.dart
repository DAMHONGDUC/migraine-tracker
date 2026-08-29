import 'dart:async';

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../domain/repositories/premium_repository.dart';
import '../datasources/revenue_cat_client.dart';

/// Entitlement state, straight from RevenueCat.
class RevenueCatPremiumRepository implements PremiumRepository {
  RevenueCatPremiumRepository(this._client) {
    Purchases.addCustomerInfoUpdateListener(_onCustomerInfo);
    unawaited(_prime());
  }

  final RevenueCatClient _client;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  /// Last value the SDK reported. False until the first answer arrives — gates must never open on an unknown entitlement.
  bool _isPremium = false;

  @override
  bool get isPremium => _isPremium;

  @override
  Stream<bool> watchIsPremium() async* {
    yield _isPremium;
    yield* _controller.stream;
  }

  /// First read after configure.
  Future<void> _prime() async {
    try {
      await _client.ensureConfigured();
      _onCustomerInfo(await Purchases.getCustomerInfo());
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.premium,
        'RevenueCat entitlement read failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _onCustomerInfo(CustomerInfo info) {
    final bool entitled = RevenueCatClient.isEntitled(info);

    if (entitled == _isPremium) return;

    _isPremium = entitled;
    if (!_controller.isClosed) _controller.add(entitled);
  }

  void dispose() {
    Purchases.removeCustomerInfoUpdateListener(_onCustomerInfo);
    _controller.close();
  }
}
