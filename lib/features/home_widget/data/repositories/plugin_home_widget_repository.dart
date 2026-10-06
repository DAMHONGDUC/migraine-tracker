import 'dart:io';

import 'package:home_widget/home_widget.dart';

import '../../../../core/constants/home_widget_constant.dart';
import '../../domain/entities/home_widget_content.dart';
import '../../domain/repositories/home_widget_repository.dart';

/// [HomeWidgetRepository] over the `home_widget` plugin.
class PluginHomeWidgetRepository implements HomeWidgetRepository {
  PluginHomeWidgetRepository();

  /// Set once per process, not per write: the plugin keeps it in a static.
  bool _groupSet = false;

  @override
  bool get isSupported => Platform.isIOS;

  @override
  Future<void> publish(HomeWidgetContent content) async {
    if (!isSupported) return;

    await _ensureAppGroup();
    for (final MapEntry<String, String> entry in content.toData().entries) {
      await HomeWidget.saveWidgetData<String>(entry.key, entry.value);
    }
    await HomeWidget.updateWidget(iOSName: HomeWidgetConstant.iOSWidgetName);
  }

  @override
  Future<void> clear() async {
    if (!isSupported) return;

    await _ensureAppGroup();
    // Empty strings, never null: home_widget 0.9.4 hands null to UserDefaults as NSNull, which iOS 27 aborts the app over. The extension reads "" as absent.
    for (final MapEntry<String, String> entry
        in HomeWidgetContent.empty.toData().entries) {
      await HomeWidget.saveWidgetData<String>(entry.key, entry.value);
    }
    await HomeWidget.updateWidget(iOSName: HomeWidgetConstant.iOSWidgetName);
  }

  /// Empty off iOS rather than the plugin's own stream: subscribing opens an `EventChannel` to a plugin that is not there.
  @override
  Stream<Uri?> get taps =>
      isSupported ? HomeWidget.widgetClicked : const Stream<Uri?>.empty();

  @override
  Future<Uri?> takeLaunchUri() async {
    if (!isSupported) return null;

    await _ensureAppGroup();

    return HomeWidget.initiallyLaunchedFromHomeWidget();
  }

  Future<void> _ensureAppGroup() async {
    if (_groupSet) return;

    await HomeWidget.setAppGroupId(HomeWidgetConstant.appGroupId);
    _groupSet = true;
  }
}
