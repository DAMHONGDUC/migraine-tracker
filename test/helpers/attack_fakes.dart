import 'dart:typed_data';

import 'package:migraine_tracker/features/attacks/domain/services/attack_share_file_store.dart';

/// Records whether the wipe reached the share images.
///
/// In `helpers/` rather than beside one test because two of them build a
/// `DataWipeService` — the wipe's own suite and the dev-seed one — and a
/// second copy is how the two come to disagree about what a wipe does.
class RecordingShareFileStore implements AttackShareFileStore {
  bool cleared = false;

  @override
  Future<String> write({
    required String attackId,
    required Uint8List bytes,
  }) async => '/tmp/attack-$attackId.png';

  @override
  Future<void> deleteAll() async => cleared = true;
}
