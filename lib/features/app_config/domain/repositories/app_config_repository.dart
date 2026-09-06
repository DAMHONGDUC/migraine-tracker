import '../entities/app_config_flags.dart';
import '../entities/app_config_grants.dart';

/// The owner-managed `app_config` collection: one row per address, plus the one document of switches that apply to everybody.
abstract interface class AppConfigRepository {
  /// Live grants for [email], so revoking an address takes effect without a reinstall. Emits [AppConfigGrants.none] while the document does not exist, which is the normal state for almost every address.
  ///
  /// Scoped to one address because the rules allow a client nothing wider — which is why this takes an address rather than a query.
  Stream<AppConfigGrants> watchGrants(String email);

  /// The switches every install reads, signed in or not. Emits [AppConfigFlags.allOn] while the document does not exist, so a project that never created it behaves exactly as the app did before the switches existed.
  Stream<AppConfigFlags> watchFlags();
}
