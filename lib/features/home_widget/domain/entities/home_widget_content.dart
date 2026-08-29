import 'package:meta/meta.dart';

import '../enums/pressure_trend.dart';

/// Everything the home-screen widget renders, already worded.
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
    required this.attribution,
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

  /// When the reading stops standing for "now", as epoch seconds.
  final String pressureExpiresAtEpochSeconds;

  /// Apple's weather trademark.
  final String attribution;

  final PressureTrend trend;

  /// Nothing to say — what the widget holds once it is switched off.
  static const HomeWidgetContent empty = HomeWidgetContent(
    logLabel: '',
    weekLabel: '',
    weekValue: '',
    pressureLabel: '',
    pressureValue: '',
    pressureDetail: '',
    pressureExpiresAtEpochSeconds: '',
    attribution: '',
    trend: PressureTrend.unknown,
  );

  /// The App Group payload. Keys are a contract with `BaroEaseWidget` — renaming one here means renaming it in the Swift entry too.
  Map<String, String> toData() => <String, String>{
    'log_label': logLabel,
    'week_label': weekLabel,
    'week_value': weekValue,
    'pressure_label': pressureLabel,
    'pressure_value': pressureValue,
    'pressure_detail': pressureDetail,
    'pressure_expires_at': pressureExpiresAtEpochSeconds,
    'attribution': attribution,
    'trend': trend.token,
  };
}
