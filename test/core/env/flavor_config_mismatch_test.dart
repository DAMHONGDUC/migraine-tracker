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

    final List<String> lines = '$mismatch'.split('\n');

    // One labelled fact per line: what this is, what each half says, and the
    // command. Read in a console and on the error screen, both of which
    // punish a single long sentence.
    expect(lines, hasLength(4));
    expect(lines[0], contains('wrong Firebase project'));
    expect(lines[1], 'env/${AppEnv.flavor}.json expects: acme-dev');
    expect(lines[2], 'native config is: acme-prod');
    expect(lines[3], 'Fix: melos run prepare-env-${AppEnv.flavor}');
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
