import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/app_config/domain/services/version_utils.dart';

void main() {
  group('parse', () {
    test('reads plain versions', () {
      expect(VersionUtils.parse('1.4.0'), <int>[1, 4, 0]);
      expect(VersionUtils.parse('1.4'), <int>[1, 4]);
      expect(VersionUtils.parse('12'), <int>[12]);
    });

    test('tolerates what a human types into a console', () {
      expect(VersionUtils.parse(' 1.4.0 '), <int>[1, 4, 0]);
      expect(VersionUtils.parse('v1.4.0'), <int>[1, 4, 0]);
      expect(VersionUtils.parse('1.4.0-beta.2'), <int>[1, 4, 0]);
    });

    test('is null when there is nothing to compare', () {
      expect(VersionUtils.parse(''), isNull);
      expect(VersionUtils.parse('latest'), isNull);
    });
  });

  group('compare', () {
    test('orders by segment value, not lexically', () {
      expect(VersionUtils.compare('1.10.0', '1.9.0'), greaterThan(0));
      expect(VersionUtils.compare('1.9.0', '1.10.0'), lessThan(0));
      expect(VersionUtils.compare('2.0.0', '10.0.0'), lessThan(0));
    });

    test('missing segments count as zero', () {
      expect(VersionUtils.compare('1.4', '1.4.0'), 0);
      expect(VersionUtils.compare('1.4.1', '1.4'), greaterThan(0));
    });

    test('is null when either side is unreadable', () {
      expect(VersionUtils.compare('latest', '1.4.0'), isNull);
      expect(VersionUtils.compare('1.4.0', ''), isNull);
    });
  });
}
