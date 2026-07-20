import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/enums/head_location.dart';
import '../../providers.dart';

/// Edits/deletes an already-logged attack from the detail screen. The
/// widget only renders the streamed attack and calls these.
class AttackDetailController {
  const AttackDetailController(this._ref);

  final Ref _ref;

  /// Corrects a mis-tapped intensity / location / medication.
  Future<void> updateCore(
    String id, {
    required int intensity,
    required HeadLocation location,
    required String? medicationName,
  }) => _ref
      .read(attackRepositoryProvider)
      .updateCore(
        id,
        intensity: intensity,
        location: location,
        medicationName: medicationName,
      );

  Future<void> delete(String id) =>
      _ref.read(attackRepositoryProvider).deleteById(id);
}
