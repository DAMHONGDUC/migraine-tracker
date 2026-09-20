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
}
