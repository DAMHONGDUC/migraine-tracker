import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/app_update/data/repositories/app_update_mapper.dart';
import 'package:migraine_tracker/features/app_update/domain/entities/app_update_config.dart';
import 'package:migraine_tracker/features/app_update/domain/enums/app_platform.dart';

/// The `force_update` section of `app_config/current` is typed by hand in the Firebase console, so every parse has to degrade to "don't block" instead of throwing on launch.
void main() {
  Map<String, Object?> platform({
    Object? buildNumber = 12,
    Object? enable = true,
    Object? storeLink = 'https://play.google.com/store/apps/details?id=x',
  }) => <String, Object?>{
    'store_link': storeLink,
    'build_name': '1.4.0',
    'build_number': buildNumber,
    'enable_force_update': enable,
  };

  test('parses a well-formed record', () {
    final AppUpdateConfig? config = AppUpdateMapper.fromMap(<String, Object?>{
      'android': platform(),
      'ios': platform(buildNumber: 14),
    });

    expect(config, isNotNull);
    expect(config!.forPlatform(AppPlatform.android)!.buildNumber, 12);
    expect(config.forPlatform(AppPlatform.ios)!.buildNumber, 14);
    expect(config.forPlatform(AppPlatform.android)!.forceUpdateEnabled, isTrue);
  });

  test('accepts a build number and flag typed as strings', () {
    final AppUpdateConfig? config = AppUpdateMapper.fromMap(<String, Object?>{
      'ios': platform(buildNumber: '14', enable: 'true'),
    });

    expect(config!.ios!.buildNumber, 14);
    expect(config.ios!.forceUpdateEnabled, isTrue);
  });

  test('a missing platform section is null, not a crash', () {
    final AppUpdateConfig? config = AppUpdateMapper.fromMap(<String, Object?>{
      'android': platform(),
    });

    expect(config!.ios, isNull);
    expect(config.android, isNotNull);
  });

  // Both keep a usable `android` alongside: one platform dropping must not
  // take the other with it, and a record with neither is null (below).
  test('a section without a usable build number is dropped', () {
    final AppUpdateConfig? config = AppUpdateMapper.fromMap(<String, Object?>{
      'android': platform(),
      'ios': platform(buildNumber: 'not a number'),
    });

    expect(config!.ios, isNull);
    expect(config.android, isNotNull);
  });

  test('a section without a store link is dropped', () {
    final AppUpdateConfig? config = AppUpdateMapper.fromMap(<String, Object?>{
      'android': platform(),
      'ios': platform(storeLink: null),
    });

    expect(config!.ios, isNull);
    expect(config.android, isNotNull);
  });

  test('anything but an explicit true leaves force update off', () {
    final AppUpdateConfig? config = AppUpdateMapper.fromMap(<String, Object?>{
      'ios': platform(enable: 'yes'),
    });

    expect(config!.ios!.forceUpdateEnabled, isFalse);
  });

  test('a section with neither platform usable is null, not an empty record', () {
    // Nothing to compare an install against, so the checker must never be
    // handed a record at all — `blockingUpdate` fails open on null.
    expect(AppUpdateMapper.fromMap(<String, Object?>{}), isNull);
    expect(
      AppUpdateMapper.fromMap(<String, Object?>{'ios': platform(storeLink: null)}),
      isNull,
    );
  });
}
