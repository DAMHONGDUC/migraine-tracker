/// The splash's own numbers.
final class SplashConstant {
  /// The dots' size. A raw logical pixel value rather than `.r`: `FreshInstallGate` draws them above `ScreenUtilInit`, where the scale is not registered yet — and one centred indicator gains nothing from it.
  static const double dotsSize = 40;

  /// The shortest the splash route stays up (owner's call). The session work
  /// usually settles in a fraction of a second, which reads as a flicker
  /// between the launch image and the dashboard rather than as a launch. The
  /// wait runs alongside the work, so a slow launch is never made slower.
  static const Duration minimumVisible = Duration(seconds: 2);
}
