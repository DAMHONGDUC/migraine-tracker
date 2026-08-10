import 'package:meta/meta.dart';

import '../enums/pressure_trend.dart';

/// Everything the home-screen widget renders, already worded.
///
/// The widget is native SwiftUI and cannot reach the ARB files, so the app
/// pushes finished strings and the extension only lays them out (hard rule
/// 6). That is the opposite of how the notification list stores its rows, and
/// for the same reason underneath: the strings have to be produced wherever
/// the locale is known. Here that is the app, so the app renders them — and
/// re-publishes when the language changes.
@immutable
class HomeWidgetContent {
  const HomeWidgetContent({
    required this.logLabel,
    required this.weekLabel,
    required this.weekValue,
    required this.pressureLabel,
    required this.pressureValue,
    required this.pressureDetail,
    required this.pressureExpiresAtEpochSeconds,
    required this.trend,
  });

  /// The fixed button — the one thing on the widget that never changes.
  final String logLabel;

  final String weekLabel;

  /// How many attacks this week, worded and pluralised.
  final String weekValue;

  final String pressureLabel;

  /// "1013 hPa", or the no-reading dash.
  final String pressureValue;

  /// "-5.2 hPa / 24h". Empty when there is no reading to qualify.
  final String pressureDetail;

  /// When the reading stops standing for "now", as epoch seconds. Empty when
  /// there is no reading. The extension schedules a second timeline entry at
  /// this instant that blanks the pressure — nothing republishes while the
  /// phone sits untouched, so expiry has to be something the widget can do
  /// on its own.
  final String pressureExpiresAtEpochSeconds;

  final PressureTrend trend;

  /// Nothing to say — what the widget holds once it is switched off. Its keys
  /// are what [HomeWidgetRepository.clear] removes, so a key added to the
  /// payload is a key the clear already covers.
  static const HomeWidgetContent empty = HomeWidgetContent(
    logLabel: '',
    weekLabel: '',
    weekValue: '',
    pressureLabel: '',
    pressureValue: '',
    pressureDetail: '',
    pressureExpiresAtEpochSeconds: '',
    trend: PressureTrend.unknown,
  );

  /// The App Group payload. Keys are a contract with `BaroEaseWidget` —
  /// renaming one here means renaming it in the Swift entry too.
  Map<String, String> toData() => <String, String>{
    'log_label': logLabel,
    'week_label': weekLabel,
    'week_value': weekValue,
    'pressure_label': pressureLabel,
    'pressure_value': pressureValue,
    'pressure_detail': pressureDetail,
    'pressure_expires_at': pressureExpiresAtEpochSeconds,
    'trend': trend.token,
  };
}
