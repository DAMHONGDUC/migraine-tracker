import 'package:flutter_test/flutter_test.dart';

/// Enough real frames for a transition or a rebuild to land — and never `pumpAndSettle`.
///
/// **Nothing in this app ever settles.** `pumpAndSettle` waits for the frame pipeline to go quiet, and the splash dots
/// and every `SdSkeletonV2` shimmer repeat forever, so it does not fail — it times out at ten minutes, which reads as a
/// slow machine rather than as a broken test. A fixed number of pumps answers the same question in milliseconds.
///
/// Its own file, with no other import, so a widget test that needs nothing else from `pump_app.dart` does not pull the
/// whole app harness in to get it.
Future<void> settleFrames(WidgetTester tester, {int frames = 8}) async {
  for (int i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
