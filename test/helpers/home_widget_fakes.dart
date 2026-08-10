import 'package:migraine_tracker/features/home_widget/domain/entities/home_widget_content.dart';
import 'package:migraine_tracker/features/home_widget/domain/repositories/home_widget_repository.dart';

/// A [HomeWidgetRepository] that records instead of touching the OS.
///
/// [clears] is what the GDPR wipe test asserts on: the App Group holds a week
/// count and a pressure reading, so a wipe that skipped it would leave the
/// user's numbers on their home screen (hard rule 8).
class RecordingHomeWidgetRepository implements HomeWidgetRepository {
  final List<HomeWidgetContent> published = <HomeWidgetContent>[];
  int clears = 0;

  @override
  bool get isSupported => true;

  @override
  Future<void> publish(HomeWidgetContent content) async =>
      published.add(content);

  @override
  Future<void> clear() async => clears++;

  @override
  Stream<Uri?> get taps => const Stream<Uri?>.empty();

  @override
  Future<Uri?> takeLaunchUri() async => null;
}
