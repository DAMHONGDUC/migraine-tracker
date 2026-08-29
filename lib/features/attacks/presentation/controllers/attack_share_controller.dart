import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/utils/widget_capture_utils.dart';
import '../../../settings/providers.dart';
import '../../providers.dart';

/// Renders the previewed card and hands it to the system share sheet.
class AttackShareController {
  const AttackShareController(this._ref);

  final Ref _ref;

  static const String _mimeType = 'image/png';

  /// True once the share sheet has been handed the file.
  Future<bool> share({
    required GlobalKey boundaryKey,
    required String attackId,
  }) async {
    SdLogger.action(LogTagConstant.attackShare, 'Share attack card', <String,
        Object?>{'attackId': attackId});

    final Uint8List? bytes = await WidgetCaptureUtils.toPng(
      boundaryKey,
      tag: LogTagConstant.attackShare,
    );

    if (bytes == null) return false;

    try {
      final String path = await _ref
          .read(attackShareFileStoreProvider)
          .write(attackId: attackId, bytes: bytes);

      await _ref
          .read(exportSharerProvider)
          .shareFile(path: path, mimeType: _mimeType);
      AppAnalytics.logAttackShared();
      SdLogger.info(LogTagConstant.attackShare, 'Shared attack card', <String,
          Object?>{'attackId': attackId, 'bytes': bytes.length});

      return true;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.attackShare,
        'Failed to share attack card',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'attackId': attackId, 'bytes': bytes.length},
      );

      return false;
    }
  }
}
