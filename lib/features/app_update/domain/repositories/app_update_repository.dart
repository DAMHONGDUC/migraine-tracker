import '../entities/app_update_config.dart';

abstract interface class AppUpdateRepository {
  /// The newest record by `create_date`, or null when the collection is
  /// empty or the record is unusable. Throws on network/permission
  /// failures — every caller fails open on those.
  Future<AppUpdateConfig?> latest();
}
