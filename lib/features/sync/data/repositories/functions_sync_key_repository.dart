import 'package:cloud_functions/cloud_functions.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../domain/repositories/sync_key_repository.dart';

/// Fetches the account's key from the `getSyncKey` callable.
class FunctionsSyncKeyRepository implements SyncKeyRepository {
  FunctionsSyncKeyRepository(this._functions);

  static const String callable = 'getSyncKey';

  final FirebaseFunctions _functions;

  String? _cachedKey;
  String? _cachedUid;

  @override
  Future<String> keyFor(String uid) async {
    final String? cached = _cachedKey;

    if (cached != null && _cachedUid == uid) {
      SdLogger.debug(
        LogTagConstant.syncKey,
        '$callable served from memory',
        <String, Object?>{'uid': uid},
      );

      return cached;
    }

    SdLogger.action(LogTagConstant.syncKey, 'Call $callable', <String, Object?>{
      'uid': uid,
    });
    try {
      final HttpsCallableResult<dynamic> result = await _functions
          .httpsCallable(callable)
          .call<dynamic>();
      final Object? key = (result.data as Map<Object?, Object?>?)?['key'];

      if (key is! String || key.isEmpty) {
        // The key itself is never logged — it decrypts the user's records. Its absence and its length are what a reader needs.
        SdLogger.error(
          LogTagConstant.syncKey,
          '$callable returned no key',
          data: <String, Object?>{'uid': uid, 'keys': _shape(result.data)},
        );
        throw StateError('getSyncKey returned no key');
      }

      SdLogger.info(LogTagConstant.syncKey, '$callable ok', <String, Object?>{
        'uid': uid,
        'keyLength': key.length,
      });
      _cachedKey = key;
      _cachedUid = uid;

      return key;
    } on FirebaseFunctionsException catch (error, stackTrace) {
      // code/details carry what a plain toString() drops.
      SdLogger.error(
        LogTagConstant.syncKey,
        '$callable failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'uid': uid,
          'code': error.code,
          'message': error.message,
          'details': error.details,
        },
      );
      rethrow;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.syncKey,
        '$callable failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'uid': uid},
      );
      rethrow;
    }
  }

  /// The response's field names, never its values — enough to see what came back without putting an account key in a log.
  List<Object?> _shape(Object? data) =>
      data is Map<Object?, Object?> ? data.keys.toList() : const <Object?>[];

  @override
  void forget() {
    _cachedKey = null;
    _cachedUid = null;
  }
}
