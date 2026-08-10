/// The external legal links the app is required to show, each by a different
/// rule and none of them optional.
///
/// Constants because more than one surface has to carry the same URL: the
/// paywall and the App Store description for the first two, and every screen
/// drawing weather for the third. A submission was already rejected over the
/// subscription pair being absent. `docs/APP_STORE_LISTING.md` is the other
/// half of that one.
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

  /// Apple's weather attribution page.
  ///
  /// Showing the Weather trademark and linking here is a condition of using
  /// WeatherKit, not a courtesy — it has to appear on every surface that draws
  /// weather data, and App Review checks.
  static const String weatherAttribution =
      'https://weatherkit.apple.com/legal-attribution.html';
}
