import 'dart:typed_data';

/// Where the shareable attack images live on disk (a fake in tests).
///
/// Temporary storage, not documents: the picture is a copy of something the
/// app already holds, handed to the share sheet and never listed anywhere
/// afterwards. Exports go to documents for the opposite reason — the export
/// screen offers to re-share them later.
///
/// It has a [deleteAll] for one reason: the file is a fourth copy of health
/// data on the device, so the GDPR wipe has to reach it (hard rule 8).
abstract interface class AttackShareFileStore {
  /// Writes [bytes] for the attack [attackId] and returns the absolute path.
  Future<String> write({required String attackId, required Uint8List bytes});

  /// Drops every share image — part of the GDPR wipe.
  Future<void> deleteAll();
}
