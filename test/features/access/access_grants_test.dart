import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/features/access/data/repositories/firestore_access_repository.dart';
import 'package:migraine_tracker/features/access/domain/entities/access_grants.dart';
import 'package:migraine_tracker/features/access/domain/repositories/access_repository.dart';
import 'package:migraine_tracker/features/access/providers.dart';
import 'package:migraine_tracker/features/auth/providers.dart';

import '../../helpers/pump_app.dart';

/// Stands in for the `app_access` document, and records which address was asked for — the one thing the rules will hand a client and nothing wider.
class FakeAccessRepository implements AccessRepository {
  FakeAccessRepository([this.grants = AccessGrants.none]);

  AccessGrants grants;

  /// Addresses [watch] was called with, in order. Empty means Firestore was never touched.
  final List<String> watched = <String>[];

  /// Not broadcast, and not an `async*` generator: both drop an event pushed
  /// before the subscription is live, which is exactly the race a test that
  /// emits right after the first value would lose.
  StreamController<AccessGrants> _controller = StreamController<AccessGrants>();

  @override
  Stream<AccessGrants> watch(String email) {
    watched.add(email);
    _controller = StreamController<AccessGrants>();
    _controller.add(grants);

    return _controller.stream;
  }

  /// Pushes a revocation (or a grant) the way the owner editing the console does.
  void emit(AccessGrants next) => _controller.add(next);
}

/// A container wired the way the app wires it, minus Firebase.
ProviderContainer containerFor({
  required bool signedIn,
  required FakeAccessRepository access,
}) {
  final ProviderContainer container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(signedIn: signedIn),
      ),
      accessRepositoryProvider.overrideWithValue(access),
    ],
  );

  // Providers are auto-dispose: without a listener the stream is torn down
  // between the read that starts it and the value it was going to emit.
  container.listen<AsyncValue<AccessGrants>>(
    accessGrantsProvider,
    (AsyncValue<AccessGrants>? previous, AsyncValue<AccessGrants> next) {},
    fireImmediately: true,
  );

  addTearDown(container.dispose);
  return container;
}

void main() {
  test(
    'an anonymous session is granted nothing and never reads the document',
    () async {
      final FakeAccessRepository access = FakeAccessRepository(
        const AccessGrants(premium: true, devSettings: true),
      );
      final ProviderContainer container = containerFor(
        signedIn: false,
        access: access,
      );

      expect(
        await container.read(accessGrantsProvider.future),
        AccessGrants.none,
      );
      // The rules would deny the read anyway; not issuing it is what keeps
      // Firestore out of every widget test that never signs in.
      expect(access.watched, isEmpty);
    },
  );

  test('a signed-in address is granted what its document says', () async {
    final FakeAccessRepository access = FakeAccessRepository(
      const AccessGrants(premium: true, devSettings: true),
    );
    final ProviderContainer container = containerFor(
      signedIn: true,
      access: access,
    );

    expect(
      await container.read(accessGrantsProvider.future),
      const AccessGrants(premium: true, devSettings: true),
    );
    expect(access.watched, <String>['tester@example.com']);
    expect(container.read(hasAccessPremiumProvider), isTrue);
  });

  test('nothing is granted while the read is still in flight', () {
    final ProviderContainer container = containerFor(
      signedIn: true,
      access: FakeAccessRepository(const AccessGrants(premium: true)),
    );

    // Read before the stream has emitted: a gate must never open on a
    // document the app has not actually seen.
    expect(container.read(hasAccessPremiumProvider), isFalse);
  });

  test('revoking the row closes the gate again', () async {
    final FakeAccessRepository access = FakeAccessRepository(
      const AccessGrants(premium: true),
    );
    final ProviderContainer container = containerFor(
      signedIn: true,
      access: access,
    );

    await container.read(accessGrantsProvider.future);
    expect(container.read(hasAccessPremiumProvider), isTrue);

    access.emit(AccessGrants.none);
    // The future is already complete, so it hands back the old value: the new
    // one arrives on the stream, which means letting the queue drain.
    await pumpEventQueue();

    expect(container.read(hasAccessPremiumProvider), isFalse);
  });

  test('a dev flavour shows the Dev group without any grant at all', () async {
    // The suite runs on the dev flavour, which is the pre-existing default:
    // the allow-list is what adds the group to a PROD build, not what a
    // developer needs to see it.
    final ProviderContainer container = containerFor(
      signedIn: false,
      access: FakeAccessRepository(),
    );

    await container.read(accessGrantsProvider.future);

    expect(container.read(showDevSettingsProvider), isTrue);
  });

  test('the document is keyed and shaped the way the console writes it', () {
    // The Dart entity is camelCase and the document is snake_case
    // (docs/rules/DATA_AND_SYNC.md), so a rename on one side silently stops
    // matching the other — and a wrong id is unreadable even to its owner,
    // because the rule compares it to the lower-cased token address.
    expect(FirestoreAccessRepository.premiumField, 'premium');
    expect(FirestoreAccessRepository.devSettingsField, 'dev_settings');
    expect(
      FirestoreAccessRepository.documentId('  Review@BaroEase.app  '),
      'review@baroease.app',
    );
  });
}
