import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/services/attack_live_activity.dart';
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

/// Records whether the Lock Screen card was taken down, and nothing else.
class RecordingLiveActivity implements AttackLiveActivity {
  int endCalls = 0;

  @override
  Future<bool> get isAvailable async => false;

  @override
  Future<void> start(
    Attack attack, {
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> end() async => endCalls++;
}
