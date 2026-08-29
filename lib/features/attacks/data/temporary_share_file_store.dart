import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:system_design/common.dart';

import '../../../core/constants/log_tag_constant.dart';
import '../domain/services/attack_share_file_store.dart';

/// Keeps share images in one `attack_shares/` folder inside the app's temporary directory.
class TemporaryShareFileStore implements AttackShareFileStore {
  const TemporaryShareFileStore();

  static const String _folder = 'attack_shares';

  @override
  Future<String> write({
    required String attackId,
    required Uint8List bytes,
  }) async {
    final Directory dir = await _dir();
    final File file = File('${dir.path}/attack-$attackId.png');

    await file.writeAsBytes(bytes);

    return file.path;
  }

  @override
  Future<void> deleteAll() async {
    try {
      final Directory dir = await _dir();

      if (dir.existsSync()) await dir.delete(recursive: true);
    } catch (error, stackTrace) {
      // Best-effort, like every other wipe step that touches the filesystem: a folder that cannot be removed must not abort the rest of the wipe.
      SdLogger.error(
        LogTagConstant.attackShare,
        'Failed to clear share images',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'folder': _folder},
      );
    }
  }

  Future<Directory> _dir() async {
    final Directory temp = await getTemporaryDirectory();

    return Directory('${temp.path}/$_folder').create(recursive: true);
  }
}
