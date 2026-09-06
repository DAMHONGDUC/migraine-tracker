import 'package:meta/meta.dart';

/// The whole `app_config/app` document: the switches that apply to everybody,
/// and the three address lists the owner maintains by hand.
///
/// **Every list is lower-cased on the way in.** Firebase Auth stores an address
/// lower-cased and the owner types the list by hand, so `Review@BaroEase.app`
/// in the console has to match `review@baroease.app` on the session — comparing
/// raw would fail silently, granting nothing and looking like a typo nobody
/// made.
@immutable
class AppConfig {
  AppConfig({
    this.premiumEnabled = true,
    Set<String> premiumEmails = const <String>{},
    Set<String> devModeEmails = const <String>{},
    Set<String> blockedEmails = const <String>{},
  }) : premiumEmails = normalise(premiumEmails),
       devModeEmails = normalise(devModeEmails),
       blockedEmails = normalise(blockedEmails);

  /// What a missing document, a denied read and a read still in flight all
  /// produce: **premium on, nobody listed**.
  ///
  /// The two halves default in opposite directions on purpose. A list is
  /// something an address has to be put on, so absent means nothing; a kill
  /// switch is something the owner has to actively throw, so absent means the
  /// app behaves as it always did. Defaulting [premiumEnabled] to false would
  /// mean an offline first launch or one denied read takes premium away from
  /// somebody who paid for it.
  static final AppConfig empty = AppConfig();

  /// Whether premium exists in this build at all. False makes `hasPremiumProvider` answer false for everyone: bought, listed, or forced by the Dev group alike.
  final bool premiumEnabled;

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
          other.premiumEnabled == premiumEnabled &&
          _same(other.premiumEmails, premiumEmails) &&
          _same(other.devModeEmails, devModeEmails) &&
          _same(other.blockedEmails, blockedEmails);

  @override
  int get hashCode => Object.hash(
    premiumEnabled,
    Object.hashAllUnordered(premiumEmails),
    Object.hashAllUnordered(devModeEmails),
    Object.hashAllUnordered(blockedEmails),
  );

  static bool _same(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);
}
