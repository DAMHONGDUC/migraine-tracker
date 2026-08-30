/// The launch screen's own numbers.
final class SplashConstant {
  /// The app icon, shown at the size below. The same file `flutter_launcher_icons` generates from — see `docs/setup/APP_ICON.md`.
  static const String iconAsset = 'assets/images/final_app_icon.png';

  /// The icon's drawn size. The three `LaunchImage.imageset` PNGs are this size at 1×/2×/3×, so the handover from the native launch screen changes nothing on screen.
  static const double iconSize = 112;

  static const double iconToDotsGap = 32;

  static const double dotsSize = 40;
}
