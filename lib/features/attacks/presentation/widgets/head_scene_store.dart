import 'package:flutter_scene/scene.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import 'head_model_contract.dart';

/// The head model, parsed once for the process and handed out as a template.
///
/// **A miss is not an error the user should ever see.** Flutter GPU is off on
/// a device whose build never turned it on, and absent altogether in a widget
/// test, and either way the 2D diagram is what draws — so this reports null
/// rather than throwing, and says so in the log for whoever is looking.
final class HeadSceneStore {
  const HeadSceneStore._();

  static const String asset = 'assets/models/head.glb';

  static Future<Node?>? _pending;
  static Node? _template;
  static bool _unavailable = false;

  /// The loaded model, or null while it is still loading or after it failed.
  static Node? get template => _template;

  /// True once loading has been tried and could not be done here.
  static bool get unavailable => _unavailable;

  /// Loads the model, once. Every later call gets the same future.
  static Future<Node?> load() => _pending ??= _load();

  static Future<Node?> _load() async {
    SdLogger.action(
      LogTagConstant.attackLog,
      'Load head model',
      <String, Object?>{'asset': asset},
    );

    try {
      final Node node = await Node.fromGlbAsset(asset);

      HeadModelContract.validate(node);
      _template = node;
      SdLogger.info(LogTagConstant.attackLog, 'Head model loaded');

      return node;
    } catch (error, stackTrace) {
      _unavailable = true;
      SdLogger.warning(
        LogTagConstant.attackLog,
        'Head model unavailable, falling back to the flat diagram',
        error,
      );
      SdLogger.debug(LogTagConstant.attackLog, 'Head model stack', stackTrace);

      return null;
    }
  }

  /// Test seam: forgets what was loaded so the next call tries again.
  static void reset() {
    _pending = null;
    _template = null;
    _unavailable = false;
  }
}
