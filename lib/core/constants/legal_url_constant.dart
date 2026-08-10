/// The two links App Store guideline 3.1.2 requires beside an auto-renewable
/// subscription — in the binary, not only in the listing's metadata.
///
/// Constants because the paywall and the App Store description have to carry
/// the *same* URLs, and a submission was already rejected over the pair being
/// absent. `docs/APP_STORE_LISTING.md` is the other half.
final class LegalUrlConstant {
  const LegalUrlConstant._();

  /// Apple's standard EULA. BaroEase ships no custom licence, so this is the
  /// Terms of Use its subscriptions are sold under — the same link the App
  /// Description carries.
  static const String termsOfUse =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

  /// The app's own page, not the directory index that lists every app — the
  /// index is not this app's policy and reads as the wrong link.
  static const String privacyPolicy =
      'https://damhongduc.github.io/apps_privacy_policy/baro-ease/privacy_policy/';
}
