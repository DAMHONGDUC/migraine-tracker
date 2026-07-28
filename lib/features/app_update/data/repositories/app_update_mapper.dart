import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_update_config.dart';

/// The Firestore document schema, in one place.
///
/// ```
/// app_updates/{autoId}
///   create_date: Timestamp
///   android: { store_link, build_name, build_number, enable_force_update }
///   ios:     { store_link, build_name, build_number, enable_force_update }
/// ```
///
/// Every field is parsed defensively: a record typed by hand in the console
/// is the input here, and a typo must degrade to "don't block", never to a
/// crash on launch.
abstract final class AppUpdateMapper {
  static const String createDateField = 'create_date';
  static const String androidField = 'android';
  static const String iosField = 'ios';
  static const String storeLinkField = 'store_link';
  static const String buildNameField = 'build_name';
  static const String buildNumberField = 'build_number';
  static const String enableForceUpdateField = 'enable_force_update';

  /// Null when the record has no usable `create_date`.
  static AppUpdateConfig? fromMap(Map<String, Object?> data) {
    final DateTime? createdAt = _dateFrom(data[createDateField]);

    if (createdAt == null) return null;
    return AppUpdateConfig(
      createdAt: createdAt,
      android: _platformFrom(data[androidField]),
      ios: _platformFrom(data[iosField]),
    );
  }

  /// Null unless the section carries both a store link and a build number —
  /// without either there is nothing to block on.
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

  /// Always UTC, like every other date in the app.
  static DateTime? _dateFrom(Object? value) => switch (value) {
    final Timestamp timestamp => timestamp.toDate().toUtc(),
    final DateTime date => date.toUtc(),
    final String text => DateTime.tryParse(text),
    _ => null,
  };

  static int? _intFrom(Object? value) => switch (value) {
    final int number => number,
    final num number => number.toInt(),
    final String text => int.tryParse(text),
    _ => null,
  };

  /// Anything that is not an explicit true stays false: force update is
  /// opt-in, never inferred.
  static bool _boolFrom(Object? value) => switch (value) {
    final bool flag => flag,
    final String text => text.toLowerCase() == 'true',
    _ => false,
  };
}
