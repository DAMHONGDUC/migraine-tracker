import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/env/app_env.dart';
import 'package:migraine_tracker/core/env/flavor_config_mismatch.dart';

/// The message is the whole feature: this can only happen on a developer's
/// machine, so a detail row nobody can act on is a guard that fires and helps
/// no one.
void main() {
  test('names both projects and the command that fixes it', () {
    const FlavorConfigMismatch mismatch = FlavorConfigMismatch(
      expected: 'acme-dev',
      actual: 'acme-prod',
    );

    expect('$mismatch', contains('acme-dev'));
    expect('$mismatch', contains('acme-prod'));
    expect('$mismatch', contains('melos run prepare-env-${AppEnv.flavor}'));
  });

  group('disagree', () {
    test('two different projects are a mismatch', () {
      expect(FlavorConfigMismatch.disagree('acme-dev', 'acme-prod'), isTrue);
    });

    test('the same project is not', () {
      expect(FlavorConfigMismatch.disagree('acme-dev', 'acme-dev'), isFalse);
    });

    // The case that breaks a fresh clone if the rule widens to `!=`: a half
    // that is empty is not configured yet, and an app with no backend must
    // still run.
    test('an empty half is an absence, not a mismatch', () {
      expect(FlavorConfigMismatch.disagree('', 'acme-prod'), isFalse);
      expect(FlavorConfigMismatch.disagree('acme-dev', ''), isFalse);
      expect(FlavorConfigMismatch.disagree('', ''), isFalse);
    });
  });
}
