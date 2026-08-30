import '../entities/access_grants.dart';

/// The owner-managed allow-list, scoped to one address — the Firestore rules allow a client nothing wider, so no method here takes a query.
abstract interface class AccessRepository {
  /// Live grants for [email], so revoking an address takes effect without a reinstall. Emits [AccessGrants.none] while the document does not exist, which is the normal state for almost every address.
  Stream<AccessGrants> watch(String email);
}
