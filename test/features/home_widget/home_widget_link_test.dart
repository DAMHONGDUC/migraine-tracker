import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/home_widget/domain/services/home_widget_link.dart';

void main() {
  test('the widget URL still opens the log flow', () {
    expect(
      HomeWidgetLink.resolve(Uri.parse('baroease://log?homeWidget=true')),
      HomeWidgetDestination.log,
    );
  });

  // Siri comes down the same URL, so one contract serves both.
  test('the Siri check-in URL opens the check-in', () {
    expect(
      HomeWidgetLink.resolve(Uri.parse('baroease://checkin?homeWidget=true')),
      HomeWidgetDestination.checkIn,
    );
  });

  // `baroease://log` puts the word in the host, `baroease:///log` in the path.
  test('a path URL reads the same as a host one', () {
    expect(
      HomeWidgetLink.resolve(Uri.parse('baroease:///checkin')),
      HomeWidgetDestination.checkIn,
    );
  });

  test('a destination we do not serve resolves to nothing', () {
    expect(HomeWidgetLink.resolve(Uri.parse('baroease://paywall')), isNull);
    expect(HomeWidgetLink.resolve(Uri.parse('https://log')), isNull);
    expect(HomeWidgetLink.resolve(null), isNull);
  });
}
