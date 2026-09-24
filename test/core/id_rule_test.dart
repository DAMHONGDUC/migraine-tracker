import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every id comes from `SdId` (owner's rule, 2026-09-24): `SdId.unique()` for a
/// record, `SdId.owned()` for a user's document. A `Uuid()` beside it is a
/// second place ids are made, and the next derived id skips the owner.
void main() {
  test('no file in lib/ makes its own ids', () {
    final List<String> offenders = <String>[
      for (final FileSystemEntity file in Directory(
        'lib',
      ).listSync(recursive: true))
        if (file is File &&
            file.path.endsWith('.dart') &&
            file.readAsStringSync().contains('package:uuid/'))
          file.path,
    ];

    expect(
      offenders,
      isEmpty,
      reason: 'use SdId from package:system_design/common.dart',
    );
  });
}
