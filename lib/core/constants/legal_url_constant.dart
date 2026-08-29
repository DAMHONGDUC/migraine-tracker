import '../env/app_env.dart';

/// The external legal links the app is required to show, each by a different rule and none of them optional.
final class LegalUrlConstant {
  const LegalUrlConstant._();

  /// Apple's standard EULA.
  static const String termsOfUse =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

  /// The app's own page, not the directory index that lists every app — the index is not this app's policy and reads as the wrong link.
  static const String privacyPolicy = AppEnv.privacyPolicyUrl;

  /// Apple's weather attribution page.
  static const String weatherAttribution =
      'https://weatherkit.apple.com/legal-attribution.html';
}
