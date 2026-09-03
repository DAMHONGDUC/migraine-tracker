import '../entities/attack.dart';

/// The Lock Screen and Dynamic Island card for an attack that is happening now.
///
/// An interface because the plugin only answers on iOS 16.1+: everywhere else
/// this is a no-op, and the caller must not have to know which.
abstract interface class AttackLiveActivity {
  /// Whether the device will show one at all. False off iOS, below 16.1, and wherever the user has switched Live Activities off.
  Future<bool> get isAvailable;

  /// Starts or refreshes the card for [attack]. The words are passed in already localized — the extension has no `AppLocalizations` to read.
  Future<void> start(
    Attack attack, {
    required String title,
    required String body,
  });

  /// Takes the card down. Safe to call when there is none.
  Future<void> end();
}
