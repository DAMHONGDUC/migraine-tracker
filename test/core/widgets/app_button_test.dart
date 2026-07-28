import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';
import 'package:migraine_tracker/core/widgets/app_button.dart';

/// The login screen's pair: a filled Apple button over an outlined Google
/// one, two labels of different lengths. Under
/// [AppButtonIconPlacement.aligned] the icon+label cluster sits in the middle
/// of the button AND lands on the same x in both — whatever the variant and
/// whatever the label length.
///
/// Labels are kept short here on purpose: the test font draws every character
/// a full font-size wide, so a realistic "Continue with Google" measures ~280
/// against the ~146 it takes in SF on a device, and would overflow the slot
/// in the test while fitting in the app. The last test covers that overflow
/// deliberately.
void main() {
  const IconData appleIcon = Icons.apple;
  const IconData googleIcon = Icons.g_mobiledata;

  Future<void> pumpPair(
    WidgetTester tester, {
    required AppButtonIconPlacement placement,
    String appleLabel = 'Apple',
    String googleLabel = 'Google',
    double? appleIconSize,
  }) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(393, 852),
        builder: (BuildContext context, Widget? child) => MaterialApp(
          home: Scaffold(
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppButton(
                  variant: AppButtonVariant.primary,
                  icon: appleIcon,
                  iconPlacement: placement,
                  iconSize: appleIconSize,
                  label: appleLabel,
                  onPressed: () {},
                ),
                AppButton(
                  variant: AppButtonVariant.outlined,
                  icon: googleIcon,
                  iconPlacement: placement,
                  label: googleLabel,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('aligned puts both glyphs on the same x', (tester) async {
    await pumpPair(tester, placement: AppButtonIconPlacement.aligned);

    expect(
      tester.getTopLeft(find.byIcon(appleIcon)).dx,
      tester.getTopLeft(find.byIcon(googleIcon)).dx,
    );
  });

  testWidgets('aligned starts both labels on the same x', (tester) async {
    await pumpPair(tester, placement: AppButtonIconPlacement.aligned);

    // Same slot, same left edge — and start-aligned, so the first character
    // sits on that edge instead of floating in the middle of the slot.
    expect(
      tester.getTopLeft(find.text('Apple')).dx,
      tester.getTopLeft(find.text('Google')).dx,
    );
    expect(
      tester.getSize(find.text('Apple')).width,
      tester.getSize(find.text('Google')).width,
    );
    expect(tester.widget<Text>(find.text('Apple')).textAlign, TextAlign.start);
    expect(tester.widget<Text>(find.text('Google')).textAlign, TextAlign.start);
  });

  // Aligned is still a cluster in the middle, not an icon pinned to the edge.
  testWidgets('aligned keeps the cluster centred on the button', (
    tester,
  ) async {
    await pumpPair(tester, placement: AppButtonIconPlacement.aligned);

    final Finder button = find.byType(FilledButton);
    final Finder cluster = find.descendant(
      of: button,
      matching: find.byType(Row),
    );

    expect(
      tester.getCenter(cluster).dx,
      moreOrLessEquals(tester.getCenter(button).dx, epsilon: 0.5),
    );
    // ...and it is a cluster: the glyph sits well inside the button's edge.
    expect(
      tester.getTopLeft(find.byIcon(appleIcon)).dx -
          tester.getTopLeft(button).dx,
      greaterThan(AppButton.iconGap * 2),
    );
  });

  testWidgets('aligned gives both buttons the same height', (tester) async {
    await pumpPair(tester, placement: AppButtonIconPlacement.aligned);

    expect(
      tester.getSize(find.byType(FilledButton)).height,
      tester.getSize(find.byType(OutlinedButton)).height,
    );
  });

  // The slot is a minimum, not a cage: a label too long for it takes the room
  // it needs — widening, then wrapping — rather than being cut off.
  testWidgets('a label wider than the slot is never truncated', (tester) async {
    await pumpPair(
      tester,
      placement: AppButtonIconPlacement.aligned,
      appleLabel: 'Sign in with a very long label indeed',
    );

    final Size label = tester.getSize(
      find.text('Sign in with a very long label indeed'),
    );

    expect(label.width, greaterThan(AppButton.alignedLabelWidth));
    // Out of width it wraps to a second line rather than losing characters.
    expect(
      label.height,
      greaterThan(tester.getSize(find.text('Google')).height),
    );
  });

  // Per-button override, for a brand glyph whose mark reads light or heavy
  // at the shared box. The button next to it keeps the default.
  testWidgets('iconSize overrides the default for that button alone', (
    tester,
  ) async {
    await pumpPair(
      tester,
      placement: AppButtonIconPlacement.aligned,
      appleIconSize: AppSpacingConstant.r28,
    );

    expect(
      tester.getSize(find.byIcon(appleIcon)).width,
      AppSpacingConstant.r28,
    );
    expect(
      tester.getSize(find.byIcon(googleIcon)).width,
      AppButton.defaultIconSize,
    );
  });

  // Optical correction must not cost the alignment the pair was built for:
  // the bigger glyph grows around its centre, inside an unchanged slot.
  testWidgets('a resized glyph keeps the pair aligned', (tester) async {
    await pumpPair(
      tester,
      placement: AppButtonIconPlacement.aligned,
      appleIconSize: AppSpacingConstant.r28,
    );

    expect(
      tester.getCenter(find.byIcon(appleIcon)).dx,
      moreOrLessEquals(tester.getCenter(find.byIcon(googleIcon)).dx),
    );
    expect(
      tester.getTopLeft(find.text('Apple')).dx,
      tester.getTopLeft(find.text('Google')).dx,
    );
  });

  // The inline default is what the shrink-wrapped text buttons (the "Add
  // reminder" / "Edit" rows) sit on: it must not grow to the full width.
  testWidgets('inline still shrink-wraps to its content', (tester) async {
    await pumpPair(tester, placement: AppButtonIconPlacement.inline);

    final double buttonWidth = tester.getSize(find.byType(FilledButton)).width;
    final Finder row = find.descendant(
      of: find.byType(FilledButton),
      matching: find.byType(Row),
    );

    expect(tester.getSize(row).width, lessThan(buttonWidth));
  });
}
