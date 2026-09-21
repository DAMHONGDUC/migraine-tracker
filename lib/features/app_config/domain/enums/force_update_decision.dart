/// Why an install was, or was not, held at the update sheet.
///
/// **A force update that does not fire looks exactly like one nobody switched
/// on**, and the owner edits `app_config/current` by hand: a flag at the wrong
/// level, a section without a store link, a published build that is not
/// actually newer than the installed one — every one of them ends as a silent
/// "carry on". So the check answers with a reason and logs it, and the console
/// says which of the five it was.
enum ForceUpdateDecision {
  /// `force_update` carries no usable section for this platform. Either the
  /// map is absent, or the section was dropped for having no `store_link` or
  /// no `build_number` — without either there is nothing to block on.
  noPublishedBuild,

  /// The section is there and `enable_force_update` is not `true` **on it**.
  /// The flag lives inside `ios` / `android`, not beside them.
  notEnabled,

  /// The section has a `build_number` but its `store_link` is empty — there is
  /// nowhere to send the user, and a sheet with a dead button is worse than
  /// none.
  noStoreLink,

  /// The installed version name is NEWER than the published one, which settles
  /// it outright: a build ahead of the store is never held.
  installedIsNewer,

  /// Neither side has a build number to compare, and the names did not settle
  /// it. Blocking on a comparison that cannot be made is how everybody gets
  /// locked out at once.
  buildNumberUnknown,

  /// The installed build is the published one, or newer. The usual answer, and
  /// the usual reason a test of the switch shows nothing.
  upToDate,

  /// Held: the install is older than the published build and the owner asked
  /// for it to be blocked.
  blocked;

  bool get isBlocking => this == blocked;
}
