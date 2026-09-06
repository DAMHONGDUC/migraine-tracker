import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/features/app_config/domain/entities/app_config.dart';
import 'package:migraine_tracker/features/app_config/domain/entities/app_config_schema.dart';
import 'package:migraine_tracker/features/app_config/providers.dart';
import 'package:migraine_tracker/features/auth/providers.dart';
import 'package:migraine_tracker/features/premium/providers.dart';

import '../../helpers/pump_app.dart';

/// The address `FakeAuthRepository` signs in as.
const String kSignedIn = 'tester@example.com';

/// A container wired the way the app wires it, minus Firebase.
ProviderContainer containerFor({
  required bool signedIn,
  required FakeAppConfigRepository config,
  bool entitled = false,
}) {
  final ProviderContainer container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(signedIn: signedIn),
      ),
      appConfigRepositoryProvider.overrideWithValue(config),
      premiumRepositoryProvider.overrideWithValue(
        FakePremiumRepository(premium: entitled),
      ),
    ],
  );

  // Providers are auto-dispose: without a listener the stream is torn down
  // between the read that starts it and the value it was going to emit.
  container.listen<AsyncValue<AppConfig>>(
    appConfigProvider,
    (AsyncValue<AppConfig>? previous, AsyncValue<AppConfig> next) {},
    fireImmediately: true,
  );

  addTearDown(container.dispose);
  return container;
}

void main() {
  group('the address lists', () {
    test('grant the signed-in address what they name it', () async {
      final ProviderContainer container = containerFor(
        signedIn: true,
        config: FakeAppConfigRepository(
          config: AppConfig(
            premiumEmails: <String>{kSignedIn},
            devModeEmails: <String>{kSignedIn},
          ),
        ),
      );

      await container.read(appConfigProvider.future);

      expect(container.read(hasGrantedPremiumProvider), isTrue);
      expect(container.read(showDevSettingsProvider), isTrue);
      expect(container.read(isAccountBlockedProvider), isFalse);
    });

    test('grant an anonymous session nothing at all', () async {
      // A session with no address is on no list, however the lists are typed.
      final ProviderContainer container = containerFor(
        signedIn: false,
        config: FakeAppConfigRepository(
          config: AppConfig(
            premiumEmails: <String>{kSignedIn},
            blockedEmails: <String>{kSignedIn},
          ),
        ),
      );

      await container.read(appConfigProvider.future);

      expect(container.read(hasGrantedPremiumProvider), isFalse);
      expect(container.read(isAccountBlockedProvider), isFalse);
    });

    test('match case-insensitively, both sides', () async {
      // The owner types the list by hand and Firebase Auth stores addresses
      // lower-cased, so " Tester@Example.com " in the console has to match.
      final ProviderContainer container = containerFor(
        signedIn: true,
        config: FakeAppConfigRepository(
          config: AppConfig(premiumEmails: <String>{'  Tester@Example.COM  '}),
        ),
      );

      await container.read(appConfigProvider.future);

      expect(container.read(hasGrantedPremiumProvider), isTrue);
    });

    test('grant nothing while the read is still in flight', () {
      final ProviderContainer container = containerFor(
        signedIn: true,
        config: FakeAppConfigRepository(
          config: AppConfig(
            premiumEmails: <String>{kSignedIn},
            blockedEmails: <String>{kSignedIn},
          ),
        ),
      );

      // A gate must never open — nor a lock-out close — on a document the app
      // has not actually seen.
      expect(container.read(hasGrantedPremiumProvider), isFalse);
      expect(container.read(isAccountBlockedProvider), isFalse);
    });

    test('close the gate again when the address is taken off', () async {
      final FakeAppConfigRepository config = FakeAppConfigRepository(
        config: AppConfig(premiumEmails: <String>{kSignedIn}),
      );
      final ProviderContainer container = containerFor(
        signedIn: true,
        config: config,
      );

      await container.read(appConfigProvider.future);
      expect(container.read(hasGrantedPremiumProvider), isTrue);

      config.emit(AppConfig.empty);
      // The future is already complete, so it hands back the old value: the new
      // one arrives on the stream, which means letting the queue drain.
      await pumpEventQueue();

      expect(container.read(hasGrantedPremiumProvider), isFalse);
    });

    test('are read once, not once per gate', () async {
      final FakeAppConfigRepository config = FakeAppConfigRepository();
      final ProviderContainer container = containerFor(
        signedIn: true,
        config: config,
      );

      await container.read(appConfigProvider.future);
      container.read(hasGrantedPremiumProvider);
      container.read(isAccountBlockedProvider);
      container.read(showDevSettingsProvider);
      container.read(premiumEnabledProvider);

      // Four gates, one listener: they all read the same document.
      expect(config.watchCalls, 1);
    });

    test('a dev flavour shows the Dev group with nobody listed', () async {
      // The suite runs on the dev flavour, which is the pre-existing default:
      // the list is what adds the group to a PROD build, not what a developer
      // needs to see it.
      final ProviderContainer container = containerFor(
        signedIn: false,
        config: FakeAppConfigRepository(),
      );

      await container.read(appConfigProvider.future);

      expect(container.read(showDevSettingsProvider), isTrue);
    });
  });

  group('the app-wide premium switch', () {
    test('is on while the read is in flight, and for a missing document', () {
      final ProviderContainer container = containerFor(
        signedIn: false,
        config: FakeAppConfigRepository(),
      );

      // The opposite default to a list, and the reason for it: an offline
      // launch or a denied read must not take premium away from someone who
      // paid for it.
      expect(container.read(premiumEnabledProvider), isTrue);
    });

    test('closes the gate on a paying subscriber', () async {
      final ProviderContainer container = containerFor(
        signedIn: false,
        config: FakeAppConfigRepository(
          config: AppConfig(premiumEnabled: false),
        ),
        entitled: true,
      );

      await container.read(appConfigProvider.future);

      // Read straight off the repository rather than through the entitlement
      // stream: that is the same synchronous fallback every gate uses on its
      // first frame, and the frame the switch has to be right on.
      expect(container.read(hasPremiumProvider), isFalse);
    });

    test('closes the gate on a listed address too', () async {
      // The one branch that would otherwise talk its way past the switch: the
      // list is checked ahead of the entitlement, so the switch has to sit
      // ahead of the list.
      final ProviderContainer container = containerFor(
        signedIn: true,
        config: FakeAppConfigRepository(
          config: AppConfig(
            premiumEnabled: false,
            premiumEmails: <String>{kSignedIn},
          ),
        ),
      );

      await container.read(appConfigProvider.future);

      expect(container.read(hasGrantedPremiumProvider), isTrue);
      expect(container.read(hasPremiumProvider), isFalse);
    });

    test('throwing it back on reopens every gate', () async {
      final FakeAppConfigRepository config = FakeAppConfigRepository(
        config: AppConfig(premiumEnabled: false),
      );
      final ProviderContainer container = containerFor(
        signedIn: false,
        config: config,
        entitled: true,
      );

      await container.read(appConfigProvider.future);
      expect(container.read(hasPremiumProvider), isFalse);

      config.emit(AppConfig.empty);
      await pumpEventQueue();

      expect(container.read(hasPremiumProvider), isTrue);
    });
  });

  test('the document is named the way the console writes it', () {
    // The Dart entity is camelCase and the document is snake_case
    // (docs/rules/DATA_AND_SYNC.md), so a rename on one side silently stops
    // matching the other: an unknown key reads as absent, not as an error.
    expect(AppConfigSchema.collectionPath, 'app_config');
    expect(AppConfigSchema.documentId, 'app');
    expect(AppConfigSchema.premiumEnabledField, 'premium_enabled');
    expect(AppConfigSchema.forceUpdateField, 'force_update');
    expect(AppConfigSchema.premiumEmailsField, 'premium_emails');
    expect(AppConfigSchema.devModeEmailsField, 'dev_mode_emails');
    expect(AppConfigSchema.blockedEmailsField, 'blocked_emails');
  });
}
