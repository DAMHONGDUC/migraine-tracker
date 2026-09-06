import 'package:meta/meta.dart';

/// The switches that apply to every install at once, read from the single
/// `app_config/app` document rather than from any address's row.
///
/// **Every flag defaults to ON, which is the opposite of [AppConfigGrants].**
/// A grant is something an address has to be given, so absent means nothing;
/// a kill switch is something the owner has to actively throw, so absent means
/// the app behaves as it always did. Defaulting these off would mean an
/// offline first launch, a first install ahead of the document existing, or a
/// single denied read takes premium away from someone who paid for it.
@immutable
class AppConfigFlags {
  const AppConfigFlags({this.premiumEnabled = true});

  /// Nothing switched off — a missing document, a denied read, and a read still in flight all produce this.
  static const AppConfigFlags allOn = AppConfigFlags();

  /// Whether premium exists in this build at all. False makes `hasPremiumProvider` answer false for everyone: bought, allow-listed, or forced by the Dev group alike.
  final bool premiumEnabled;

  /// Value equality, because a Firestore stream re-emits on metadata alone: without it every gate in the app rebuilds when nothing it reads has changed.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppConfigFlags && other.premiumEnabled == premiumEnabled;

  @override
  int get hashCode => premiumEnabled.hashCode;
}
