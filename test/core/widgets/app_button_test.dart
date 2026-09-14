import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:system_design/index.dart';

/// The login screen's pair: a filled Apple button over an outlined Google one, two labels of different lengths.
void main() {
  const IconData appleIcon = Icons.apple;
  const IconData googleIcon = Icons.g_mobiledata;

  Future<void> pumpPair(
    WidgetTester tester, {
    required SdButtonIconPlacementV2 placement,
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
                SdButtonV2(
                  variant: SdButtonVariantV2.primary,
                  icon: appleIcon,
                  iconPlacement: placement,
                  iconSize: appleIconSize,
                  label: appleLabel,
                  onPressed: () {},
                ),
                SdButtonV2(
                  variant: SdButtonVariantV2.outlined,
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
    await pumpPair(tester, placement: SdButtonIconPlacementV2.aligned);

    expect(
      tester.getTopLeft(find.byIcon(appleIcon)).dx,
      tester.getTopLeft(find.byIcon(googleIcon)).dx,
    );
  });

  testWidgets('aligned starts both labels on the same x', (tester) async {
    await pumpPair(tester, placement: SdButtonIconPlacementV2.aligned);

    // Same slot, same left edge — and start-aligned, so the first character sits on that edge instead of floating in the middle of the slot.
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
    await pumpPair(tester, placement: SdButtonIconPlacementV2.aligned);

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
      greaterThan(SdButtonV2.iconGap * 2),
    );
  });

  testWidgets('aligned gives both buttons the same height', (tester) async {
    await pumpPair(tester, placement: SdButtonIconPlacementV2.aligned);

    expect(
      tester.getSize(find.byType(FilledButton)).height,
      tester.getSize(find.byType(OutlinedButton)).height,
    );
  });

  // The slot is a minimum, not a cage: a label too long for it takes the room it needs — widening, then wrapping — rather than being cut off.
  testWidgets('a label wider than the slot is never truncated', (tester) async {
    await pumpPair(
      tester,
      placement: SdButtonIconPlacementV2.aligned,
      appleLabel: 'Sign in with a very long label indeed',
    );

    final Size label = tester.getSize(
      find.text('Sign in with a very long label indeed'),
    );

    expect(label.width, greaterThan(SdButtonV2.alignedLabelWidth));
    // Out of width it wraps to a second line rather than losing characters.
    expect(
      label.height,
      greaterThan(tester.getSize(find.text('Google')).height),
    );
  });

  // Per-button override, for a brand glyph whose mark reads light or heavy at the shared box. The button next to it keeps the default.
  testWidgets('iconSize overrides the default for that button alone', (
    tester,
  ) async {
    await pumpPair(
      tester,
      placement: SdButtonIconPlacementV2.aligned,
      appleIconSize: SdSpacingConstant.r28,
    );

    expect(tester.getSize(find.byIcon(appleIcon)).width, SdSpacingConstant.r28);
    expect(
      tester.getSize(find.byIcon(googleIcon)).width,
      SdButtonV2.defaultIconSize,
    );
  });

  // Optical correction must not cost the alignment the pair was built for: the bigger glyph grows around its centre, inside an unchanged slot.
  testWidgets('a resized glyph keeps the pair aligned', (tester) async {
    await pumpPair(
      tester,
      placement: SdButtonIconPlacementV2.aligned,
      appleIconSize: SdSpacingConstant.r28,
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

  // The inline default is what the shrink-wrapped text buttons (the "Add reminder" / "Edit" rows) sit on: it must not grow to the full width.
  testWidgets('inline still shrink-wraps to its content', (tester) async {
    await pumpPair(tester, placement: SdButtonIconPlacementV2.inline);

    final double buttonWidth = tester.getSize(find.byType(FilledButton)).width;
    final Finder row = find.descendant(
      of: find.byType(FilledButton),
      matching: find.byType(Row),
    );

    expect(tester.getSize(row).width, lessThan(buttonWidth));
  });

  group('size', () {
    const IconData icon = Icons.star;

    Future<void> pumpSized(WidgetTester tester, SdButtonSizeV2 size) async {
      tester.view.physicalSize = const Size(393 * 3, 852 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(393, 852),
          builder: (BuildContext context, Widget? child) => MaterialApp(
            home: Scaffold(
              body: SdButtonV2(
                variant: SdButtonVariantV2.primary,
                icon: icon,
                size: size,
                label: 'Go',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('medium is the unscaled baseline', (tester) async {
      await pumpSized(tester, SdButtonSizeV2.medium);

      expect(
        tester.getSize(find.byIcon(icon)).width,
        SdButtonV2.defaultIconSize,
      );
    });

    testWidgets('small scales the icon down, large scales it up', (
      tester,
    ) async {
      await pumpSized(tester, SdButtonSizeV2.small);
      final double small = tester.getSize(find.byIcon(icon)).width;

      await pumpSized(tester, SdButtonSizeV2.large);
      final double large = tester.getSize(find.byIcon(icon)).width;

      expect(small, moreOrLessEquals(SdButtonV2.defaultIconSize * 0.75));
      expect(large, moreOrLessEquals(SdButtonV2.defaultIconSize * 1.25));
    });

    // Material's own 48-tall tap target can floor the rendered size at small — read the padding the style carries, not the final render box.
    double verticalPadding(WidgetTester tester) {
      final ButtonStyle style = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .style!;

      return style.padding!.resolve(<WidgetState>{})!.vertical;
    }

    testWidgets('small pads less than medium, medium less than large', (
      tester,
    ) async {
      await pumpSized(tester, SdButtonSizeV2.small);
      final double small = verticalPadding(tester);

      await pumpSized(tester, SdButtonSizeV2.medium);
      final double medium = verticalPadding(tester);

      await pumpSized(tester, SdButtonSizeV2.large);
      final double large = verticalPadding(tester);

      expect(small, lessThan(medium));
      expect(medium, lessThan(large));
    });

    // Chrome-sized app-bar actions are always small, whatever `size` a call site passes alongside `compact` — the two must never disagree.
    testWidgets('compact always scales as small, overriding size', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393 * 3, 852 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(393, 852),
          builder: (BuildContext context, Widget? child) => MaterialApp(
            home: Scaffold(
              body: SdButtonV2(
                variant: SdButtonVariantV2.primary,
                icon: icon,
                compact: true,
                size: SdButtonSizeV2.large,
                label: 'Go',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byIcon(icon)).width,
        moreOrLessEquals(SdButtonV2.defaultIconSize * 0.75),
      );
    });
  });
}
