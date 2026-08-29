import 'dart:typed_data';

/// Where the shareable attack images live on disk (a fake in tests).
abstract interface class AttackShareFileStore {
  /// Writes [bytes] for the attack [attackId] and returns the absolute path.
  Future<String> write({required String attackId, required Uint8List bytes});

  /// Drops every share image — part of the GDPR wipe.
  Future<void> deleteAll();
}
