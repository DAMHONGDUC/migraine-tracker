import '../env/app_env.dart';

/// The external legal links the app is required to show, each by a different
/// rule and none of them optional.
///
/// Constants because more than one surface has to carry the same URL: the
/// paywall and the App Store description for the first two, and every screen
/// drawing weather for the third. A submission was already rejected over the
/// subscription pair being absent. `docs/release/APP_STORE_LISTING.md` is the other
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
  ///
  /// Build-time value, unlike the other two: those are Apple's own pages and
  /// never move, this one is ours and can — a policy re-hosted under a new
  /// domain would otherwise need a code change and a release to follow it.
  /// `AppEnv` holds the `String.fromEnvironment`; the default there is this
  /// same URL, so a build with no `PRIVACY_POLICY_URL` set is unchanged.
  static const String privacyPolicy = AppEnv.privacyPolicyUrl;

  /// Apple's weather attribution page.
  ///
  /// Showing the Weather trademark and linking here is a condition of using
  /// WeatherKit, not a courtesy — it has to appear on every surface that draws
  /// weather data, and App Review checks.
  static const String weatherAttribution =
      'https://weatherkit.apple.com/legal-attribution.html';
}
