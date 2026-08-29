import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/theme/app_theme.dart';
import 'package:system_design/index.dart';

/// The segmented control's tap targets.
void main() {
  late List<int> taps;

  Future<void> pumpTabs(WidgetTester tester, {int selected = 0}) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    taps = <int>[];

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(393, 852),
        builder: (BuildContext context, Widget? child) => MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Center(
              child: SdSegmentedTabsV2(
                selectedIndex: selected,
                onSelected: taps.add,
                segments: const <SdSegmentV2>[
                  SdSegmentV2(label: 'Reminders', count: 3),
                  SdSegmentV2(label: 'Alerts'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('a segment is as tall as the track it sits in', (tester) async {
    await pumpTabs(tester);

    final Rect track = tester.getRect(find.byType(SdSegmentedTabsV2));
    final Rect segment = tester.getRect(find.byType(GestureDetector).last);

    expect(segment.height, track.height);
    expect(segment.width, closeTo(track.width / 2, 0.5));
  });

  testWidgets('the top and bottom edges of a segment select it', (
    tester,
  ) async {
    await pumpTabs(tester);

    final Rect track = tester.getRect(find.byType(SdSegmentedTabsV2));
    final double right = track.left + track.width * 0.75;

    // Just inside the track's own bounds, above and below the label — where a hit box the size of the text alone lets the tap fall through.
    await tester.tapAt(Offset(right, track.top + 2));
    await tester.tapAt(Offset(right, track.bottom - 2));
    await tester.pump();

    expect(taps, <int>[1, 1]);
  });
}
