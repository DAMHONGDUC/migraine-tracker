import 'package:meta/meta.dart';

import '../../../../core/constants/home_widget_constant.dart';
import '../enums/pressure_trend.dart';

/// The facts the home-screen widget shows, before any of them are worded.
///
/// Deliberately separate from [HomeWidgetContent]: this is what the app
/// knows, that is what the widget draws. Splitting them keeps the numbers
/// testable without a locale, and keeps the strings in one place when the
/// language changes.
@immutable
class HomeWidgetSnapshot {
  const HomeWidgetSnapshot({
    required this.weekCount,
    this.pressureHpa,
    this.pressureDelta24hHpa,
    this.pressureExpiresAt,
  });

  /// Attacks logged in the current Monday-start week.
  final int weekCount;

  /// The most recent daily reading, or null when there is none recent enough
  /// to stand for "now" (see [HomeWidgetConstant.pressureMaxAge]).
  final double? pressureHpa;

  /// Change over the 24 hours before that reading; negative means falling.
  final double? pressureDelta24hHpa;

  /// When [pressureHpa] stops standing for "now".
  ///
  /// It travels to the widget because the widget outlives the app: nothing
  /// republishes while the phone sits on a table, so an extension that could
  /// not expire the reading itself would show a two-day-old number as the
  /// current one. The threshold stays here — the Swift side only compares.
  final DateTime? pressureExpiresAt;

  bool get hasPressure => pressureHpa != null;

  PressureTrend get trend {
    final double? delta = pressureDelta24hHpa;

    if (pressureHpa == null || delta == null) return PressureTrend.unknown;
    if (delta <= -HomeWidgetConstant.trendThresholdHpa) {
      return PressureTrend.falling;
    }
    if (delta >= HomeWidgetConstant.trendThresholdHpa) {
      return PressureTrend.rising;
    }

    return PressureTrend.steady;
  }

  @override
  bool operator ==(Object other) =>
      other is HomeWidgetSnapshot &&
      other.weekCount == weekCount &&
      other.pressureHpa == pressureHpa &&
      other.pressureDelta24hHpa == pressureDelta24hHpa &&
      other.pressureExpiresAt == pressureExpiresAt;

  @override
  int get hashCode => Object.hash(
    weekCount,
    pressureHpa,
    pressureDelta24hHpa,
    pressureExpiresAt,
  );
}
