import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/widgets/app_scaffold.dart';
import 'package:migraine_tracker/core/widgets/glass/liquid_glass_theme.dart';

/// The default test view has no notch, so a wrong top inset costs exactly 0
/// pixels here and every other widget test passes while the real app hides
/// content behind the bar. This one gives the view a status bar on purpose.
void main() {
  testWidgets('bodyTopInset is the same above and inside the Scaffold body', (
    tester,
  ) async {
    AppGlass.debugSupported = true;
    addTearDown(() => AppGlass.debugSupported = null);
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    // A notched device: 47pt of status bar (141 physical / DPR 3).
    tester.view.padding = const FakeViewPadding(top: 141);
    tester.view.viewPadding = const FakeViewPadding(top: 141);
    addTearDown(tester.view.reset);

    late final double above;
    late final double below;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext outer) {
            above = AppScaffold.bodyTopInset(outer);
            return AppScaffold(
              title: const Text('Title'),
              body: Builder(
                builder: (BuildContext inner) {
                  // Scaffold strips the body's top padding when there is an
                  // app bar; the inset must survive that (AppActionView is
                  // the body, so this is where it gets read).
                  below = AppScaffold.bodyTopInset(inner);
                  return const SizedBox();
                },
              ),
            );
          },
        ),
      ),
    );

    expect(above, 47 + kToolbarHeight);
    expect(below, above);
  });

  testWidgets('bodyTopInset is 0 without glass — the bar is opaque then', (
    tester,
  ) async {
    AppGlass.debugSupported = false;
    addTearDown(() => AppGlass.debugSupported = null);
    tester.view.padding = const FakeViewPadding(top: 141);
    addTearDown(tester.view.reset);

    late final double inset;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            inset = AppScaffold.bodyTopInset(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(inset, 0);
  });
}
