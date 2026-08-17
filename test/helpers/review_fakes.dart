import 'package:migraine_tracker/features/review/domain/services/review_prompter.dart';

/// Counts the asks instead of drawing the OS dialog.
///
/// The real prompter is a platform channel, so without this every widget test
/// that logs an attack or shares a report reaches for one that is not there.
class RecordingReviewPrompter implements ReviewPrompter {
  RecordingReviewPrompter({this.available = true});

  /// What [request] answers — false is a device with no review flow, which is
  /// every simulator.
  final bool available;

  int requests = 0;

  @override
  Future<bool> request() async {
    requests++;
    return available;
  }
}
