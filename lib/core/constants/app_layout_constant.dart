import 'dart:ui';

/// App-level layout facts, as opposed to the design system's spacing steps.
final class AppLayoutConstant {
  /// The screen `flutter_screenutil` scales from — iPhone 14/15/16-class logical size. Every `.w/.h/.sp/.r` in the app is a fraction of this, so the app and the splash above it must pass the SAME value or text jumps at the handover.
  static const Size designSize = Size(393, 852);
}
