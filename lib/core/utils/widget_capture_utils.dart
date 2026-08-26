import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:system_design/common.dart';

/// Turns a widget the user is looking at into a PNG.
///
/// `core/utils/` rather than a feature: it is platform rendering and knows
/// nothing about attacks. It is deliberately NOT in any `domain/`, which is
/// pure Dart by rule and could not import `flutter/rendering.dart` at all.
final class WidgetCaptureUtils {
  /// Three times the logical size. A card captured at 1x goes soft the moment
  /// a messaging app scales it up, and these images exist to be looked at by
  /// somebody else.
  static const double defaultPixelRatio = 3;

  /// PNG bytes for the [RepaintBoundary] behind [boundaryKey], or null when
  /// it is not on screen or the platform refused the capture.
  ///
  /// Capturing a boundary that is **already on screen** is the point: the
  /// preview and the file are then the same pixels by construction, so a
  /// share cannot carry anything the user was not shown.
  static Future<Uint8List?> toPng(
    GlobalKey boundaryKey, {
    double pixelRatio = defaultPixelRatio,
    required String tag,
  }) async {
    final RenderObject? object = boundaryKey.currentContext?.findRenderObject();

    if (object is! RenderRepaintBoundary) {
      SdLogger.warning(tag, 'No repaint boundary to capture', <String, Object?>{
        'hasContext': boundaryKey.currentContext != null,
      });

      return null;
    }

    try {
      final ui.Image image = await object.toImage(pixelRatio: pixelRatio);
      final ByteData? bytes = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      image.dispose();
      SdLogger.info(tag, 'Captured widget to PNG', <String, Object?>{
        'bytes': bytes?.lengthInBytes,
        'pixelRatio': pixelRatio,
      });

      return bytes?.buffer.asUint8List();
    } catch (error, stackTrace) {
      SdLogger.error(
        tag,
        'Failed to capture widget to PNG',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'pixelRatio': pixelRatio},
      );

      return null;
    }
  }
}
