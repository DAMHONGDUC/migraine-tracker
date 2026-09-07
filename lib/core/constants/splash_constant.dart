/// The splash's own numbers.
final class SplashConstant {
  /// The dots' size. A raw logical pixel value rather than `.r`: `FreshInstallGate` draws them above `ScreenUtilInit`, where the scale is not registered yet — and one centred indicator gains nothing from it.
  static const double dotsSize = 40;
}
