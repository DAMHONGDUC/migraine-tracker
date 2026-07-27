import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/app_update/domain/entities/app_update_config.dart';

import '../../helpers/pump_app.dart';

/// The wrapper runs on every app entry, so these also guard the case that
/// matters most: it must NOT block anyone when the record says nothing.
void main() {
  AppUpdateConfig record({bool enabled = true, int buildNumber = 50}) =>
      AppUpdateConfig(
        createdAt: DateTime.utc(2026, 7, 20),
        android: PlatformUpdateConfig(
          storeLink: 'https://play.google.com/store/apps/details?id=x',
          buildName: '1.4.0',
          buildNumber: buildNumber,
          forceUpdateEnabled: enabled,
        ),
        ios: PlatformUpdateConfig(
          storeLink: 'https://apps.apple.com/app/id1',
          buildName: '1.4.0',
          buildNumber: buildNumber,
          forceUpdateEnabled: enabled,
        ),
      );

  testWidgets('no record: the app opens normally', (tester) async {
    final PumpedApp app = await pumpApp(tester);

    expect(app.appUpdate.calls, 1);
    expect(find.text('Update required'), findsNothing);
    expect(find.text('Log an attack'), findsOneWidget);
    await finishTest(tester);
  });

  testWidgets('an out-of-date build gets the blocking sheet', (tester) async {
    await pumpApp(
      tester,
      appUpdate: record(),
      installedBuildName: '1.3.0',
      installedBuildNumber: 49,
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Update required'), findsOneWidget);
    expect(find.text('Latest version: 1.4.0'), findsOneWidget);
    await finishTest(tester);
  });

  testWidgets('the sheet cannot be dismissed by tapping the barrier', (
    tester,
  ) async {
    await pumpApp(
      tester,
      appUpdate: record(),
      installedBuildName: '1.3.0',
      installedBuildNumber: 49,
    );
    await tester.pump(const Duration(milliseconds: 400));

    // Top-left is outside the sheet — on the modal barrier.
    await tester.tapAt(const Offset(10, 10));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Update required'), findsOneWidget);
    await finishTest(tester);
  });

  testWidgets('the system back gesture cannot dismiss it either', (
    tester,
  ) async {
    await pumpApp(
      tester,
      appUpdate: record(),
      installedBuildName: '1.3.0',
      installedBuildNumber: 49,
    );
    await tester.pump(const Duration(milliseconds: 400));

    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Update required'), findsOneWidget);
    await finishTest(tester);
  });

  testWidgets('Update now hands the store link to the launcher', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(
      tester,
      appUpdate: record(),
      installedBuildName: '1.3.0',
      installedBuildNumber: 49,
    );
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Update now'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // pumpApp reports the Android target platform under test.
    expect(app.storeLauncher.opened, <String>[
      'https://play.google.com/store/apps/details?id=x',
    ]);
    await finishTest(tester);
  });

  testWidgets('a failed launch tells the user instead of doing nothing', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(
      tester,
      appUpdate: record(),
      installedBuildName: '1.3.0',
      installedBuildNumber: 49,
    );
    app.storeLauncher.succeeds = false;
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Update now'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining("Couldn't open the store"), findsOneWidget);
    await finishTest(tester);
  });

  testWidgets('force update off never blocks, however old the build', (
    tester,
  ) async {
    await pumpApp(
      tester,
      appUpdate: record(enabled: false),
      installedBuildName: '0.1.0',
      installedBuildNumber: 1,
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Update required'), findsNothing);
    expect(find.text('Log an attack'), findsOneWidget);
    await finishTest(tester);
  });

  testWidgets('a current build is never blocked', (tester) async {
    await pumpApp(
      tester,
      appUpdate: record(),
      installedBuildName: '1.4.0',
      installedBuildNumber: 50,
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Update required'), findsNothing);
    await finishTest(tester);
  });

  testWidgets('same version name, older build: the number breaks the tie', (
    tester,
  ) async {
    await pumpApp(
      tester,
      appUpdate: record(),
      installedBuildName: '1.4.0',
      installedBuildNumber: 49,
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Update required'), findsOneWidget);
    await finishTest(tester);
  });

  testWidgets('a newer version name wins over a lower build number', (
    tester,
  ) async {
    await pumpApp(
      tester,
      appUpdate: record(),
      installedBuildName: '1.5.0',
      installedBuildNumber: 1,
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Update required'), findsNothing);
    await finishTest(tester);
  });
}
