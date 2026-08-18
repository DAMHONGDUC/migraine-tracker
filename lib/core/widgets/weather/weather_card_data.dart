part of 'weather_card.dart';

/// Everything [WeatherCard] can draw, already reduced to the fields it draws.
///
/// **A view model, not a third weather entity.** The two sources it is built
/// from — live [WeatherConditions] and a stored [WeatherSnapshot] — carry
/// different fields for different reasons, and the card must not branch on
/// which one it was handed. Every field is nullable for the same reason the
/// entities' are: WeatherKit omits what it has no value for at a location,
/// and a reading that never arrived is left out rather than printed as a zero.
@immutable
class WeatherCardData {
  const WeatherCardData({
    this.condition,
    this.daylight,
    this.temperatureCelsius,
    this.apparentTemperatureCelsius,
    this.pressureHpa,
    this.pressureDelta24hHpa,
    this.humidityPercent,
    this.windSpeedKph,
    this.uvIndex,
    this.visibilityKm,
  });

  /// The conditions the user is standing in.
  ///
  /// **No pressure, deliberately, and the reading is there to take.** It
  /// belongs to the pressure card, which is where it is sold
  /// (`docs/PREMIUM_RULES.md`: weather is free, pressure is the product) —
  /// and on the dashboard the Today section already carries it for the users
  /// who have paid, so a cell here would print the same number twice on one
  /// screen. The rule came with the card from Insights; do not add it back
  /// without the owner saying so.
  factory WeatherCardData.of(WeatherConditions conditions) => WeatherCardData(
    condition: conditions.condition,
    daylight: conditions.daylight,
    temperatureCelsius: conditions.temperatureCelsius,
    apparentTemperatureCelsius: conditions.apparentTemperatureCelsius,
    humidityPercent: conditions.humidityPercent,
    windSpeedKph: conditions.windSpeedKph,
    uvIndex: conditions.uvIndex,
    visibilityKm: conditions.visibilityKm,
  );

  /// The conditions an attack was logged in.
  ///
  /// Four fields, and that is all a snapshot has ever stored — no condition
  /// code, no wind, no UV. It carries the one thing live conditions do not:
  /// the 24-hour pressure change, which is the reading the whole app is about.
  ///
  /// It carries pressure where [WeatherCardData.of] does not, and that is not
  /// a contradiction: the snapshot attached to an attack is the user's own
  /// record, free for everyone (`docs/PREMIUM_RULES.md`), and it is the whole
  /// reason the attack has weather on it at all.
  factory WeatherCardData.ofSnapshot(WeatherSnapshot snapshot) =>
      WeatherCardData(
        temperatureCelsius: snapshot.temperatureCelsius,
        pressureHpa: snapshot.pressureHpa,
        pressureDelta24hHpa: snapshot.pressureDelta24hHpa,
        humidityPercent: snapshot.humidityPercent,
      );

  final WeatherCondition? condition;

  /// Whether the sun is up — what picks the day or night glyph.
  final bool? daylight;

  final double? temperatureCelsius;
  final double? apparentTemperatureCelsius;
  final double? pressureHpa;
  final double? pressureDelta24hHpa;
  final double? humidityPercent;
  final double? windSpeedKph;
  final double? uvIndex;
  final double? visibilityKm;

  /// Whether there is anything at all worth drawing.
  ///
  /// A report can come back with a `current` block whose every field is null;
  /// the card treats that as no data rather than as a card of blank rows.
  bool get isEmpty =>
      condition == null &&
      temperatureCelsius == null &&
      apparentTemperatureCelsius == null &&
      pressureHpa == null &&
      pressureDelta24hHpa == null &&
      humidityPercent == null &&
      windSpeedKph == null &&
      uvIndex == null &&
      visibilityKm == null;
}
