import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/repositories/sync_key_repository.dart';

/// Fetches the account's key from the `getSyncKey` callable.
///
/// Held in memory for the session and never written to disk: sync needs the
/// network anyway, so one call per launch is cheap and leaves no second
/// secret at rest on the device.
class FunctionsSyncKeyRepository implements SyncKeyRepository {
  FunctionsSyncKeyRepository(this._functions);

  static const String callable = 'getSyncKey';

  final FirebaseFunctions _functions;

  String? _cachedKey;
  String? _cachedUid;

  @override
  Future<String> keyFor(String uid) async {
    final String? cached = _cachedKey;
    if (cached != null && _cachedUid == uid) return cached;

    final HttpsCallableResult<dynamic> result = await _functions
        .httpsCallable(callable)
        .call<dynamic>();
    final Object? key = (result.data as Map<Object?, Object?>?)?['key'];

    if (key is! String || key.isEmpty) {
      throw StateError('getSyncKey returned no key');
    }
    _cachedKey = key;
    _cachedUid = uid;
    return key;
  }

  @override
  void forget() {
    _cachedKey = null;
    _cachedUid = null;
  }
}
