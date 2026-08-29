import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/prefs_key_constant.dart';
import 'package:migraine_tracker/core/l10n/locale_provider.dart';
import 'package:migraine_tracker/features/alerts/domain/entities/alerts_settings.dart';
import 'package:migraine_tracker/features/alerts/domain/enums/alert_registration_error.dart';
import 'package:migraine_tracker/features/alerts/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/alert_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Prefs are the source of truth for the UI, so every case starts from a stored state and asserts what ended up back in prefs.
  Future<ProviderContainer> containerWith({
    Map<String, Object> stored = const <String, Object>{},
    RecordingAlertRegistration? registration,
  }) async {
    SharedPreferences.setMockInitialValues(stored);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final ProviderContainer container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        alertRegistrationRepositoryProvider.overrideWithValue(
          registration ?? RecordingAlertRegistration(),
        ),
      ],
    );

    addTearDown(container.dispose);
    return container;
  }

  group('build', () {
    test('defaults to off at the 5 hPa threshold', () async {
      final ProviderContainer container = await containerWith();

      final AlertsSettings settings = container
          .read(alertsControllerProvider)
          .requireValue;

      expect(settings.enabled, isFalse);
      expect(settings.thresholdHpa, 5);
    });

    test('reads what was persisted', () async {
      final ProviderContainer container = await containerWith(
        stored: <String, Object>{
          PrefsKeyConstant.alertsEnabled: true,
          PrefsKeyConstant.alertThreshold: 8.5,
        },
      );

      final AlertsSettings settings = container
          .read(alertsControllerProvider)
          .requireValue;

      expect(settings.enabled, isTrue);
      expect(settings.thresholdHpa, 8.5);
    });
  });

  group('setEnabled', () {
    test(
      'registers with the current threshold and persists the flag',
      () async {
        final RecordingAlertRegistration registration =
            RecordingAlertRegistration();
        final ProviderContainer container = await containerWith(
          stored: <String, Object>{PrefsKeyConstant.alertThreshold: 7.0},
          registration: registration,
        );
        final SharedPreferences prefs = container.read(
          sharedPreferencesProvider,
        );

        await container
            .read(alertsControllerProvider.notifier)
            .setEnabled(true);

        expect(registration.registeredThresholds, <double>[7]);
        expect(prefs.getBool(PrefsKeyConstant.alertsEnabled), isTrue);
        expect(
          container.read(alertsControllerProvider).requireValue.enabled,
          isTrue,
        );
      },
    );

    test('unregisters when turned off', () async {
      final RecordingAlertRegistration registration =
          RecordingAlertRegistration();
      final ProviderContainer container = await containerWith(
        stored: <String, Object>{PrefsKeyConstant.alertsEnabled: true},
        registration: registration,
      );
      final SharedPreferences prefs = container.read(sharedPreferencesProvider);

      await container.read(alertsControllerProvider.notifier).setEnabled(false);

      expect(registration.unregisterCalls, 1);
      expect(registration.registeredThresholds, isEmpty);
      expect(prefs.getBool(PrefsKeyConstant.alertsEnabled), isFalse);
    });

    // A registration that failed must not leave prefs saying alerts are on.
    test(
      'a failed registration surfaces as an error and persists nothing',
      () async {
        final ProviderContainer container = await containerWith(
          registration: RecordingAlertRegistration(
            failWith: AlertRegistrationError.notificationsDenied,
          ),
        );
        final SharedPreferences prefs = container.read(
          sharedPreferencesProvider,
        );

        await container
            .read(alertsControllerProvider.notifier)
            .setEnabled(true);

        final AsyncValue<AlertsSettings> state = container.read(
          alertsControllerProvider,
        );

        expect(state, isA<AsyncError<AlertsSettings>>());
        expect(
          (state as AsyncError<AlertsSettings>).error,
          isA<AlertRegistrationException>(),
        );
        expect(prefs.getBool(PrefsKeyConstant.alertsEnabled), isNull);
      },
    );
  });

  group('setThreshold', () {
    test('persists and pushes to the server while alerts are on', () async {
      final RecordingAlertRegistration registration =
          RecordingAlertRegistration();
      final ProviderContainer container = await containerWith(
        stored: <String, Object>{PrefsKeyConstant.alertsEnabled: true},
        registration: registration,
      );
      final SharedPreferences prefs = container.read(sharedPreferencesProvider);

      await container.read(alertsControllerProvider.notifier).setThreshold(9);

      expect(registration.updatedThresholds, <double>[9]);
      expect(prefs.getDouble(PrefsKeyConstant.alertThreshold), 9);
      expect(
        container.read(alertsControllerProvider).requireValue.thresholdHpa,
        9,
      );
    });

    // Nothing is registered while alerts are off, so there is no server record to update — the value is kept for the next time they go on.
    test('persists without touching the server while alerts are off', () async {
      final RecordingAlertRegistration registration =
          RecordingAlertRegistration();
      final ProviderContainer container = await containerWith(
        registration: registration,
      );
      final SharedPreferences prefs = container.read(sharedPreferencesProvider);

      await container.read(alertsControllerProvider.notifier).setThreshold(3);

      expect(registration.updatedThresholds, isEmpty);
      expect(prefs.getDouble(PrefsKeyConstant.alertThreshold), 3);
    });

    test('rethrows when the server update fails', () async {
      final ProviderContainer container = await containerWith(
        stored: <String, Object>{PrefsKeyConstant.alertsEnabled: true},
        registration: RecordingAlertRegistration(
          failWith: AlertRegistrationError.unknown,
        ),
      );

      await expectLater(
        container.read(alertsControllerProvider.notifier).setThreshold(9),
        throwsA(isA<AlertRegistrationException>()),
      );
    });
  });
}
