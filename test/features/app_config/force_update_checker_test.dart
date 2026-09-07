import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/app_config/domain/entities/app_update_config.dart';
import 'package:migraine_tracker/features/app_config/domain/entities/installed_app_version.dart';
import 'package:migraine_tracker/features/app_config/domain/services/force_update_checker.dart';

/// The gate that can lock every install out of the app: build name first, build number as the tiebreaker, and every fail-open branch pinned.
void main() {
  const ForceUpdateChecker checker = ForceUpdateChecker();

  PlatformUpdateConfig published({
    String buildName = '1.4.0',
    int buildNumber = 10,
    bool enabled = true,
    String storeLink = 'https://apps.apple.com/app/id1',
  }) => PlatformUpdateConfig(
    storeLink: storeLink,
    buildName: buildName,
    buildNumber: buildNumber,
    forceUpdateEnabled: enabled,
  );

  InstalledAppVersion installed({
    String buildName = '1.4.0',
    int buildNumber = 10,
  }) => InstalledAppVersion(buildName: buildName, buildNumber: buildNumber);

  group('build name decides first', () {
    test('an older name blocks, whatever the build number says', () {
      expect(
        checker.blockingUpdate(
          published: published(),
          // Higher build number, older version name: the name wins.
          installed: installed(buildName: '1.3.9', buildNumber: 99),
        ),
        isNotNull,
      );
    });

    test('a newer name never blocks', () {
      expect(
        checker.blockingUpdate(
          published: published(),
          installed: installed(buildName: '1.5.0', buildNumber: 1),
        ),
        isNull,
      );
    });

    test('compares segments as numbers, not as strings', () {
      // The string compare that would lock everyone out: "1.10.0" < "1.9.0".
      expect(
        checker.blockingUpdate(
          published: published(buildName: '1.9.0'),
          installed: installed(buildName: '1.10.0'),
        ),
        isNull,
      );
    });

    test('1.4 and 1.4.0 are the same version', () {
      expect(
        checker.blockingUpdate(
          published: published(buildName: '1.4.0', buildNumber: 10),
          installed: installed(buildName: '1.4', buildNumber: 10),
        ),
        isNull,
      );
    });
  });

  group('build number breaks the tie', () {
    test('same name, older build blocks', () {
      expect(
        checker.blockingUpdate(
          published: published(buildNumber: 10),
          installed: installed(buildNumber: 9),
        ),
        isNotNull,
      );
    });

    test('same name, same build does not', () {
      expect(
        checker.blockingUpdate(
          published: published(buildNumber: 10),
          installed: installed(buildNumber: 10),
        ),
        isNull,
      );
    });

    test('an unreadable name falls back to the build number', () {
      expect(
        checker.blockingUpdate(
          published: published(buildName: 'latest'),
          installed: installed(buildName: 'dev', buildNumber: 9),
        ),
        isNotNull,
      );
    });

    test('an unreadable build number blocks nobody', () {
      expect(
        checker.blockingUpdate(
          published: published(),
          installed: installed(buildNumber: 0),
        ),
        isNull,
      );
    });
  });

  group('fails open', () {
    test('flag off never blocks, however old the build is', () {
      expect(
        checker.blockingUpdate(
          published: published(enabled: false),
          installed: installed(buildName: '0.1.0', buildNumber: 1),
        ),
        isNull,
      );
    });

    test('no section for this platform never blocks', () {
      expect(
        checker.blockingUpdate(published: null, installed: installed()),
        isNull,
      );
    });

    test('empty store link never blocks — the sheet would be a dead end', () {
      expect(
        checker.blockingUpdate(
          published: published(storeLink: ''),
          installed: installed(buildName: '0.1.0', buildNumber: 1),
        ),
        isNull,
      );
    });
  });
}
