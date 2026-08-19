import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/permissions/app_permission_types.dart';

import '../../helpers/pump_app.dart';

/// The weather card's third state: no position, so the card asks for one
/// instead of reporting the feature as unavailable.
void main() {
  const String prompt =
      'Turn on location to see the weather and pressure where you are.';

  testWidgets('with no location permission the card asks for it', (
    tester,
  ) async {
    await pumpApp(tester, permissionStatus: AppPermissionStatus.denied);

    expect(find.text(prompt), findsOneWidget);
    expect(find.text('Enable location'), findsOneWidget);
    // The failure line belongs to states the user cannot fix; this one they can.
    expect(find.text('Weather is unavailable right now.'), findsNothing);

    await finishTest(tester);
  });

  testWidgets('granting it puts the reading back', (tester) async {
    final PumpedApp app = await pumpApp(
      tester,
      permissionStatus: AppPermissionStatus.denied,
    );

    app.permissions.statusFor = AppPermissionStatus.granted;
    await tapVisible(tester, find.text('Enable location'));
    await tester.pump(const Duration(milliseconds: 400));

    // The ask is gone, and the card is back to drawing the weather — which
    // the fake repository answers with nothing, so it is the empty line here.
    expect(find.text(prompt), findsNothing);
    expect(find.text('Weather is unavailable right now.'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('a permanent denial offers the Settings app instead', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(
      tester,
      permissionStatus: AppPermissionStatus.permanentlyDenied,
    );

    await tapVisible(tester, find.text('Enable location'));
    await tester.pump(const Duration(milliseconds: 400));

    // iOS will not show its dialog again, so the button has to lead somewhere:
    // the sheet, and from it the Settings app.
    expect(find.text('Turn on location'), findsOneWidget);
    await tapVisible(tester, find.text('Open Settings'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(app.permissions.openSettingsCalls, 1);

    await finishTest(tester);
  });
}
