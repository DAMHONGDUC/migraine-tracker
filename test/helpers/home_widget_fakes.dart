import 'package:migraine_tracker/features/home_widget/domain/entities/home_widget_content.dart';
import 'package:migraine_tracker/features/home_widget/domain/repositories/home_widget_repository.dart';

/// A [HomeWidgetRepository] that records instead of touching the OS.
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
