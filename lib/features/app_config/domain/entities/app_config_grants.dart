import 'package:meta/meta.dart';

/// What the `app_config` allow-list grants one address. Every flag defaults to false: an address the list does not name is granted nothing, and so is a session that has no address at all.
@immutable
class AppConfigGrants {
  const AppConfigGrants({
    this.premium = false,
    this.devSettings = false,
    this.blocked = false,
  });

  /// Nothing granted — an anonymous session, an address off the list, or the document not read yet. Named so a caller never spells the empty case as `AppConfigGrants()` and leaves a reader wondering which flags it meant.
  static const AppConfigGrants none = AppConfigGrants();

  /// Premium in the app whatever RevenueCat says, and a target for the pressure-alert cron.
  final bool premium;

  /// Settings shows its Dev group.
  final bool devSettings;

  /// The address is locked out. Defaults false like the rest, which is the only safe direction here: a read that fails must not lock somebody out of an app whose data is on their own device.
  final bool blocked;

  /// Value equality, because a Firestore stream re-emits on metadata alone: without it every gate in the app rebuilds when nothing it reads has changed.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppConfigGrants &&
          other.premium == premium &&
          other.devSettings == devSettings &&
          other.blocked == blocked;

  @override
  int get hashCode => Object.hash(premium, devSettings, blocked);
}
