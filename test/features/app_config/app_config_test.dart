import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/features/app_config/domain/entities/app_config_flags.dart';
import 'package:migraine_tracker/features/app_config/domain/entities/app_config_grants.dart';
import 'package:migraine_tracker/features/app_config/domain/entities/app_config_schema.dart';
import 'package:migraine_tracker/features/app_config/providers.dart';
import 'package:migraine_tracker/features/auth/providers.dart';
import 'package:migraine_tracker/features/premium/providers.dart';

import '../../helpers/pump_app.dart';

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
  container.listen<AsyncValue<AppConfigGrants>>(
    appConfigGrantsProvider,
    (AsyncValue<AppConfigGrants>? previous, AsyncValue<AppConfigGrants> next) {},
    fireImmediately: true,
  );
  container.listen<AsyncValue<AppConfigFlags>>(
    appConfigFlagsProvider,
    (AsyncValue<AppConfigFlags>? previous, AsyncValue<AppConfigFlags> next) {},
    fireImmediately: true,
  );

  addTearDown(container.dispose);
  return container;
}

void main() {
  group('grants, per address', () {
    test(
      'an anonymous session is granted nothing and never reads the document',
      () async {
        final FakeAppConfigRepository config = FakeAppConfigRepository(
          grants: const AppConfigGrants(premium: true, devSettings: true),
        );
        final ProviderContainer container = containerFor(
          signedIn: false,
          config: config,
        );

        expect(
          await container.read(appConfigGrantsProvider.future),
          AppConfigGrants.none,
        );
        // The rules would deny the read anyway; not issuing it is what keeps
        // Firestore out of every widget test that never signs in.
        expect(config.watched, isEmpty);
      },
    );

    test('a signed-in address is granted what its document says', () async {
      final FakeAppConfigRepository config = FakeAppConfigRepository(
        grants: const AppConfigGrants(premium: true, devSettings: true),
      );
      final ProviderContainer container = containerFor(
        signedIn: true,
        config: config,
      );

      expect(
        await container.read(appConfigGrantsProvider.future),
        const AppConfigGrants(premium: true, devSettings: true),
      );
      expect(config.watched, <String>['tester@example.com']);
      expect(container.read(hasGrantedPremiumProvider), isTrue);
    });

    test('nothing is granted while the read is still in flight', () {
      final ProviderContainer container = containerFor(
        signedIn: true,
        config: FakeAppConfigRepository(
          grants: const AppConfigGrants(premium: true),
        ),
      );

      // Read before the stream has emitted: a gate must never open on a
      // document the app has not actually seen.
      expect(container.read(hasGrantedPremiumProvider), isFalse);
    });

    test('revoking the row closes the gate again', () async {
      final FakeAppConfigRepository config = FakeAppConfigRepository(
        grants: const AppConfigGrants(premium: true),
      );
      final ProviderContainer container = containerFor(
        signedIn: true,
        config: config,
      );

      await container.read(appConfigGrantsProvider.future);
      expect(container.read(hasGrantedPremiumProvider), isTrue);

      config.emitGrants(AppConfigGrants.none);
      // The future is already complete, so it hands back the old value: the new
      // one arrives on the stream, which means letting the queue drain.
      await pumpEventQueue();

      expect(container.read(hasGrantedPremiumProvider), isFalse);
    });

    test(
      'a dev flavour shows the Dev group without any grant at all',
      () async {
        // The suite runs on the dev flavour, which is the pre-existing default:
        // the allow-list is what adds the group to a PROD build, not what a
        // developer needs to see it.
        final ProviderContainer container = containerFor(
          signedIn: false,
          config: FakeAppConfigRepository(),
        );

        await container.read(appConfigGrantsProvider.future);

        expect(container.read(showDevSettingsProvider), isTrue);
      },
    );
  });

  group('the app-wide premium switch', () {
    test('is on while the read is in flight, and for an empty collection', () {
      final ProviderContainer container = containerFor(
        signedIn: false,
        config: FakeAppConfigRepository(),
      );

      // Read before the stream has emitted. The opposite default to a grant,
      // and the reason for it: an offline launch or a denied read must not
      // take premium away from someone who paid for it.
      expect(container.read(premiumEnabledProvider), isTrue);
    });

    test('is read with no session at all — the app is usable anonymously', () async {
      final ProviderContainer container = containerFor(
        signedIn: false,
        config: FakeAppConfigRepository(
          flags: const AppConfigFlags(premiumEnabled: false),
        ),
      );

      await container.read(appConfigFlagsProvider.future);

      expect(container.read(premiumEnabledProvider), isFalse);
    });

    test('closes the gate on a paying subscriber', () async {
      final ProviderContainer container = containerFor(
        signedIn: false,
        config: FakeAppConfigRepository(
          flags: const AppConfigFlags(premiumEnabled: false),
        ),
        entitled: true,
      );

      await container.read(appConfigFlagsProvider.future);

      // Read straight off the repository rather than through the entitlement
      // stream: that is the same synchronous fallback every gate uses on its
      // first frame, and the frame the switch has to be right on.
      expect(container.read(hasPremiumProvider), isFalse);
    });

    test('closes the gate on an allow-listed address too', () async {
      // The one branch that would otherwise talk its way past the switch:
      // the allow-list is checked ahead of the entitlement, so the switch has
      // to sit ahead of the allow-list.
      final ProviderContainer container = containerFor(
        signedIn: true,
        config: FakeAppConfigRepository(
          grants: const AppConfigGrants(premium: true),
          flags: const AppConfigFlags(premiumEnabled: false),
        ),
      );

      await container.read(appConfigGrantsProvider.future);
      await container.read(appConfigFlagsProvider.future);

      expect(container.read(hasGrantedPremiumProvider), isTrue);
      expect(container.read(hasPremiumProvider), isFalse);
    });

    test('throwing it back on reopens every gate', () async {
      final FakeAppConfigRepository config = FakeAppConfigRepository(
        flags: const AppConfigFlags(premiumEnabled: false),
      );
      final ProviderContainer container = containerFor(
        signedIn: false,
        config: config,
        entitled: true,
      );

      await container.read(appConfigFlagsProvider.future);
      expect(container.read(hasPremiumProvider), isFalse);

      config.emitFlags(AppConfigFlags.allOn);
      await pumpEventQueue();

      expect(container.read(hasPremiumProvider), isTrue);
    });
  });

  group('a blocked address', () {
    test('is not blocked while the read is in flight', () {
      final ProviderContainer container = containerFor(
        signedIn: true,
        config: FakeAppConfigRepository(
          grants: const AppConfigGrants(blocked: true),
        ),
      );

      // Same direction as every other grant, and the only safe one: a read
      // that has not landed must never lock somebody out of an app whose data
      // is on their own device.
      expect(container.read(isAccountBlockedProvider), isFalse);
    });

    test('is blocked once the row says so', () async {
      final ProviderContainer container = containerFor(
        signedIn: true,
        config: FakeAppConfigRepository(
          grants: const AppConfigGrants(blocked: true),
        ),
      );

      await container.read(appConfigGrantsProvider.future);

      expect(container.read(isAccountBlockedProvider), isTrue);
    });

    test('an anonymous session is never blocked', () async {
      // The row is keyed on the address, so signing out IS the way out: an
      // anonymous session matches nothing.
      final ProviderContainer container = containerFor(
        signedIn: false,
        config: FakeAppConfigRepository(
          grants: const AppConfigGrants(blocked: true),
        ),
      );

      await container.read(appConfigGrantsProvider.future);

      expect(container.read(isAccountBlockedProvider), isFalse);
    });

    test('unblocking the row lets the app back in', () async {
      final FakeAppConfigRepository config = FakeAppConfigRepository(
        grants: const AppConfigGrants(blocked: true),
      );
      final ProviderContainer container = containerFor(
        signedIn: true,
        config: config,
      );

      await container.read(appConfigGrantsProvider.future);
      expect(container.read(isAccountBlockedProvider), isTrue);

      config.emitGrants(AppConfigGrants.none);
      await pumpEventQueue();

      expect(container.read(isAccountBlockedProvider), isFalse);
    });
  });

  test('the documents are keyed and shaped the way the console writes them', () {
    // The Dart entities are camelCase and the documents are snake_case
    // (docs/rules/DATA_AND_SYNC.md), so a rename on one side silently stops
    // matching the other — and a wrong id is unreadable even to its owner,
    // because the rule compares it to the lower-cased token address.
    expect(AppConfigSchema.collectionPath, 'app_config');
    expect(AppConfigSchema.premiumField, 'premium');
    expect(AppConfigSchema.devSettingsField, 'dev_settings');
    expect(AppConfigSchema.blockedField, 'blocked');
    expect(AppConfigSchema.premiumEnabledField, 'enable_premium');
    expect(AppConfigSchema.forceUpdateField, 'force_update');
    // The app-wide document lives on a fixed id, not on an address. It must
    // stay one no sign-in can produce, or a row would silently become the
    // global config — and that document is world-readable.
    expect(AppConfigSchema.globalDocumentId, 'app');
    expect(
      AppConfigSchema.rowId('  Review@BaroEase.app  '),
      'review@baroease.app',
    );
  });
}
