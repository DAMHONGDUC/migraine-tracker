import 'package:meta/meta.dart';

/// What the `app_access` allow-list grants one address. Every flag defaults to false: an address the list does not name is granted nothing, and so is a session that has no address at all.
@immutable
class AccessGrants {
  const AccessGrants({this.premium = false, this.devSettings = false});

  /// Nothing granted — an anonymous session, an address off the list, or the document not read yet. Named so a caller never spells the empty case as `AccessGrants()` and leaves a reader wondering which flags it meant.
  static const AccessGrants none = AccessGrants();

  /// Premium in the app whatever RevenueCat says, and a target for the pressure-alert cron.
  final bool premium;

  /// Settings shows its Dev group.
  final bool devSettings;

  /// Value equality, because a Firestore stream re-emits on metadata alone: without it every gate in the app rebuilds when nothing it reads has changed.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccessGrants &&
          other.premium == premium &&
          other.devSettings == devSettings;

  @override
  int get hashCode => Object.hash(premium, devSettings);
}
