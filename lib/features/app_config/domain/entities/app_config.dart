import 'package:meta/meta.dart';

import 'app_update_config.dart';
import 'error_view_config.dart';

/// The whole `app_config/current` document: **every** switch the owner
/// controls — the three address lists they maintain by hand, the
/// published-build record behind force update, and the notice they can put in
/// front of the whole app.
///
/// **Every list is lower-cased on the way in.** Firebase Auth stores an address
/// lower-cased and the owner types the list by hand, so `Review@BaroEase.app`
/// in the console has to match `review@baroease.app` on the session — comparing
/// raw would fail silently, granting nothing and looking like a typo nobody
/// made.
@immutable
class AppConfig {
  AppConfig({
    this.forceUpdate,
    this.errorView,
    Set<String> premiumEmails = const <String>{},
    Set<String> devModeEmails = const <String>{},
    Set<String> blockedEmails = const <String>{},
  }) : premiumEmails = normalise(premiumEmails),
       devModeEmails = normalise(devModeEmails),
       blockedEmails = normalise(blockedEmails);

  /// What a missing document, a denied read and a read still in flight all
  /// produce: **nobody listed, nobody blocked, nothing to update to**.
  ///
  /// Every field defaults to granting and denying nothing, because each one is
  /// something an address has to be put on or a record the owner has to write:
  /// an offline first launch, an install ahead of the document existing, or one
  /// denied read must leave the app exactly as it was.
  static final AppConfig empty = AppConfig();

  /// The published build per platform, or null when the document carries no
  /// usable `force_update` section — nothing to compare against, so nothing is
  /// blocked.
  ///
  /// **It rides here rather than on a read of its own.** One document, one
  /// listener: force update used to `get` the same document a second time on
  /// every launch and every resume, which is a second thing to keep pointing at
  /// the right id and a second thing to get denied on its own.
  final AppUpdateConfig? forceUpdate;

  /// The owner's notice to put in front of the whole app, or null when there
  /// is none to show — switched off, absent, malformed, or with nothing to
  /// say. Null is the normal state: this is a field the owner has to write,
  /// like every other one on this document.
  final ErrorViewConfig? errorView;

  /// Premium in the app whatever RevenueCat says, and a target of the pressure-alert cron.
  final Set<String> premiumEmails;

  /// Settings shows its Dev group on a prod build.
  final Set<String> devModeEmails;

  /// Locked out: the app shows the block screen and nothing else.
  final Set<String> blockedEmails;

  /// The one spelling both sides agree on — see the class note.
  static Set<String> normalise(Iterable<String> emails) => emails
      .map((String email) => email.trim().toLowerCase())
      .where((String email) => email.isNotEmpty)
      .toSet();

  /// Membership for one address, normalised the same way the lists were. Empty is never a member: an anonymous session carries no address and must match nothing.
  static bool _holds(Set<String> emails, String email) {
    final String id = email.trim().toLowerCase();

    return id.isNotEmpty && emails.contains(id);
  }

  bool isPremium(String email) => _holds(premiumEmails, email);

  bool hasDevMode(String email) => _holds(devModeEmails, email);

  bool isBlocked(String email) => _holds(blockedEmails, email);

  /// Value equality, because a Firestore stream re-emits on metadata alone: without it every gate in the app rebuilds when nothing it reads has changed.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppConfig &&
          other.forceUpdate == forceUpdate &&
          other.errorView == errorView &&
          _same(other.premiumEmails, premiumEmails) &&
          _same(other.devModeEmails, devModeEmails) &&
          _same(other.blockedEmails, blockedEmails);

  @override
  int get hashCode => Object.hash(
    forceUpdate,
    errorView,
    Object.hashAllUnordered(premiumEmails),
    Object.hashAllUnordered(devModeEmails),
    Object.hashAllUnordered(blockedEmails),
  );

  static bool _same(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);
}
