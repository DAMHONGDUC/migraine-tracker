/// The launch screen's own numbers.
final class SplashConstant {
  /// The app icon, shown at the size below. The same file `flutter_launcher_icons` generates from — see `docs/setup/APP_ICON.md`.
  static const String iconAsset = 'assets/images/final_app_icon.png';

  /// How long the splash stays up at minimum. Nothing waits on it — `AppBootstrap.init` has already finished by the time a frame is drawn — so this is a deliberate pause, kept short: long enough that the icon reads, not long enough to be in the way of someone opening the app mid-attack (hard rule 4).
  static const Duration minimumVisible = Duration(milliseconds: 1200);

  /// The icon's drawn size, before `.r`.
  static const double iconSize = 112;

  /// Apple's own icon corner ratio (~22.37% of the side), so the square PNG reads as the icon the user tapped rather than as a picture of it.
  static const double iconCornerRatio = 0.2237;

  /// The dots' size, before `.r`.
  static const double dotsSize = 40;
}
