import '../entities/midas_score.dart';

/// Reads and writes completed MIDAS questionnaires.
abstract interface class MidasRepository {
  /// Every entry, newest first.
  Stream<List<MidasEntry>> watchAll();

  /// The newest entry, or null when the questionnaire has never been answered.
  Future<MidasEntry?> latest();

  Future<void> upsert(MidasEntry entry);

  Future<void> deleteById(String id);

  /// Drops every entry (GDPR wipe).
  Future<void> deleteAll();
}
