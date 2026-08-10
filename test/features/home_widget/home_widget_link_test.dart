import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/home_widget/domain/services/home_widget_link.dart';

void main() {
  group('resolve', () {
    test('reads the target from the host or the first path segment', () {
      expect(
        HomeWidgetLink.resolve(Uri.parse('baroease://log')),
        HomeWidgetDestination.log,
      );
      expect(
        HomeWidgetLink.resolve(Uri.parse('baroease:///log')),
        HomeWidgetDestination.log,
      );
    });

    test('ignores the plugin marker rather than tripping over it', () {
      expect(
        HomeWidgetLink.resolve(Uri.parse('baroease://log?homeWidget=true')),
        HomeWidgetDestination.log,
      );
    });

    test('refuses anything that is not ours', () {
      expect(HomeWidgetLink.resolve(null), isNull);
      expect(HomeWidgetLink.resolve(Uri.parse('baroease://elsewhere')), isNull);
      expect(HomeWidgetLink.resolve(Uri.parse('https://log')), isNull);
    });
  });

  // The Swift side builds the URL and no Dart code can catch it getting this
  // wrong — which is exactly how it shipped broken once: without the marker
  // the plugin drops the URL, the app opens on the dashboard, and nothing
  // anywhere reports a failure.
  test('the widget builds a URL the plugin will actually forward', () {
    final File view = File('ios/BaroEaseWidget/BaroEaseWidgetView.swift');
    final RegExp url = RegExp(r'URL\(string:\s*"([^"]+)"\)');
    final Match? match = url.firstMatch(view.readAsStringSync());

    expect(match, isNotNull, reason: 'no URL literal left in the widget view');

    final Uri built = Uri.parse(match!.group(1)!);

    expect(HomeWidgetLink.resolve(built), HomeWidgetDestination.log);
    expect(
      built.queryParameters.containsKey(HomeWidgetLink.pluginMarkerParam),
      isTrue,
      reason: 'home_widget silently ignores a URL without the marker',
    );
  });
}
