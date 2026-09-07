import '../../domain/entities/app_update_config.dart';

/// The `force_update` section of `app_config/current`, in one place. The collection and document names belong to `AppConfigSchema` — one owner for a path two features read.
abstract final class AppUpdateMapper {
  static const String androidField = 'android';
  static const String iosField = 'ios';
  static const String storeLinkField = 'store_link';
  static const String buildNameField = 'build_name';
  static const String buildNumberField = 'build_number';
  static const String enableForceUpdateField = 'enable_force_update';

  /// Null when neither platform has a usable section — there is nothing to compare against, so nothing can be blocked.
  static AppUpdateConfig? fromMap(Map<String, Object?> data) {
    final PlatformUpdateConfig? android = _platformFrom(data[androidField]);
    final PlatformUpdateConfig? ios = _platformFrom(data[iosField]);

    if (android == null && ios == null) return null;

    return AppUpdateConfig(android: android, ios: ios);
  }

  /// Null unless the section carries both a store link and a build number — without either there is nothing to block on.
  static PlatformUpdateConfig? _platformFrom(Object? value) {
    if (value is! Map) return null;

    final Object? storeLink = value[storeLinkField];
    final int? buildNumber = _intFrom(value[buildNumberField]);

    if (storeLink is! String || storeLink.isEmpty) return null;
    if (buildNumber == null) return null;
    return PlatformUpdateConfig(
      storeLink: storeLink,
      buildName: value[buildNameField] is String
          ? value[buildNameField] as String
          : '',
      buildNumber: buildNumber,
      forceUpdateEnabled: _boolFrom(value[enableForceUpdateField]),
    );
  }

  static int? _intFrom(Object? value) => switch (value) {
    final int number => number,
    final num number => number.toInt(),
    final String text => int.tryParse(text),
    _ => null,
  };

  /// Anything that is not an explicit true stays false: force update is opt-in, never inferred.
  static bool _boolFrom(Object? value) => switch (value) {
    final bool flag => flag,
    final String text => text.toLowerCase() == 'true',
    _ => false,
  };
}
