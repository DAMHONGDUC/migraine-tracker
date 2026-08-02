import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/theme/app_colors.dart';
import 'package:migraine_tracker/core/theme/app_theme.dart';
import 'package:system_design/v2/index.dart';

/// The control the intensity dialog and the onboarding threshold page share.
/// What matters here is the one thing both rely on: the accent reaches BOTH
/// the readout and the active track, so the number and the bar always agree.
void main() {
  Future<void> pumpSlider(WidgetTester tester, {Color? accent}) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(393, 852),
        builder: (BuildContext context, Widget? child) => MaterialApp(
          // The widget resolves its fallback accent from the theme, so the
          // test has to render under the app's, not Material's default.
          theme: AppTheme.dark,
          home: Scaffold(
            body: SdValueSliderV2(
              label: '7',
              value: 7,
              min: 1,
              max: 10,
              divisions: 9,
              accent: accent,
              onChanged: (double _) {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('the accent colours the readout and the track', (tester) async {
    final Color accent = AppColors.intensity(7);

    await pumpSlider(tester, accent: accent);

    expect(tester.widget<Text>(find.text('7')).style?.color, accent);
    expect(tester.widget<Slider>(find.byType(Slider)).activeColor, accent);
  });

  testWidgets('without an accent it falls back to primary', (tester) async {
    await pumpSlider(tester);

    expect(tester.widget<Text>(find.text('7')).style?.color, AppColors.primary);
    expect(
      tester.widget<Slider>(find.byType(Slider)).activeColor,
      AppColors.primary,
    );
  });
}
