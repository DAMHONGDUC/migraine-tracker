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
    this.precipitationChancePercent,
    this.precipitationAmountMm,
    this.sunrise,
    this.sunset,
    this.forecast,
    this.days = const <WeatherDaily>[],
    this.hours = const <WeatherHourly>[],
  });

  /// The conditions the user is standing in.
  ///
  /// **Pressure is carried, but it never reaches the card** (owner's call).
  /// It is last in `_metrics`, past `_MetricStrip.maxOnCard`, so only the
  /// detail sheet draws it — which keeps the dashboard card from printing the
  /// same number the Today section under it already shows, and keeps the card
  /// at four readings.
  factory WeatherCardData.of(WeatherReport report) {
    final WeatherConditions? now = report.current;
    final List<WeatherDaily> week = report.week;

    return WeatherCardData(
      condition: now?.condition,
      daylight: now?.daylight,
      temperatureCelsius: now?.temperatureCelsius,
      apparentTemperatureCelsius: now?.apparentTemperatureCelsius,
      humidityPercent: now?.humidityPercent,
      windSpeedKph: now?.windSpeedKph,
      uvIndex: now?.uvIndex,
      visibilityKm: now?.visibilityKm,
      pressureHpa: now?.pressureHpa,
      // The coming 24 hours, which is the window the drop alert itself runs
      // on — the app's one definition of "a 24h change" in the future.
      pressureDelta24hHpa: _pressureChange(report.hours.take(_dayHours + 1)),
      // The three the current block never carries: a chance of rain, a
      // sunrise and a sunset are facts about a day, not about an instant.
      precipitationChancePercent: week.isEmpty
          ? null
          : week.first.precipitationChancePercent,
      precipitationAmountMm: week.isEmpty
          ? null
          : week.first.precipitationAmountMm,
      sunrise: week.isEmpty ? null : week.first.sunrise,
      sunset: week.isEmpty ? null : week.first.sunset,
      forecast: week.isEmpty ? null : week.first,
      days: week,
      hours: report.hours,
    );
  }

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
  final double? precipitationChancePercent;

  /// How much rain the day is expected to bring, in millimetres.
  ///
  /// **A day's total, never an hour's** — the same window the chance beside it
  /// covers, so the two readings answer the same question. It reaches the
  /// sheet alone, behind the chance: a chance is what a user checks before
  /// leaving the house, an amount is what tells them whether it matters.
  final double? precipitationAmountMm;

  /// Today's, in UTC like everything else off the wire.
  final DateTime? sunrise;
  final DateTime? sunset;

  /// The week ahead, today first — `WeatherReport.week`, so at most
  /// `WeatherReport.weekLength` (7) of them.
  ///
  /// **Drawn only by the sheet.** The card is two lines and a forecast is not
  /// one of them; the whole point of the sheet is to have room for this.
  /// Empty for an attack's snapshot, which never stored a forecast — the week
  /// a migraine happened in is not something the app can reconstruct after
  /// the fact.
  final List<WeatherDaily> days;

  /// The day this data describes — today for a live report, or whichever day
  /// [dayAt] was asked for.
  ///
  /// Separate from [days], which is always the whole week: the sheet draws
  /// the week from one and the headline from the other, and folding them into
  /// one field made "the day I am about" and "the days I can offer" the same
  /// list.
  final WeatherDaily? forecast;

  /// Every hour the report carried, across the whole week. [dayAt] slices it;
  /// nothing draws it directly.
  final List<WeatherHourly> hours;

  /// The same readings, for another day of [days].
  ///
  /// **Index 0 is returned untouched**, because today already has something
  /// better than a forecast: the live reading. Every other day is assembled
  /// from what a forecast actually carries — the day's own condition, its UV
  /// peak, its chance of rain, its sunrise and sunset — plus the three that
  /// only exist hour by hour.
  ///
  /// **Those three are the day's mean, and that is a summary, not a
  /// measurement.** WeatherKit reports humidity, wind and visibility per
  /// hour and never per day; a day has no single value for them, so one has
  /// to be chosen. The mean is the honest choice — a maximum would answer
  /// "how windy could it get", which is a different question and a scarier
  /// one — and it is only ever shown against a future day, where every number
  /// on the sheet is already a forecast.
  ///
  /// There is no temperature and no feels-like: a day that has not happened
  /// has no "now", so the headline falls back to its high and low.
  WeatherCardData dayAt(int index) {
    if (index <= 0 || index >= days.length) return this;

    final WeatherDaily day = days[index];
    final List<WeatherHourly> onDay = hours
        .where((WeatherHourly hour) => DateTimeUtils.isSameDay(hour.time, day.date))
        .toList();

    return WeatherCardData(
      condition: day.condition,
      humidityPercent: _mean(
        onDay.map((WeatherHourly hour) => hour.humidityPercent),
      ),
      windSpeedKph: _mean(
        onDay.map((WeatherHourly hour) => hour.windSpeedKph),
      ),
      uvIndex: day.uvIndexMax,
      visibilityKm: _mean(
        onDay.map((WeatherHourly hour) => hour.visibilityKm),
      ),
      pressureHpa: _mean(
        onDay.map((WeatherHourly hour) => hour.pressureHpa),
      ),
      // First hour to last, which for a whole day IS the 24-hour change.
      pressureDelta24hHpa: _pressureChange(onDay),
      precipitationChancePercent: day.precipitationChancePercent,
      precipitationAmountMm: day.precipitationAmountMm,
      sunrise: day.sunrise,
      sunset: day.sunset,
      forecast: day,
      days: days,
      hours: hours,
    );
  }

  /// A day's worth of hourly readings.
  static const int _dayHours = 24;

  /// How far the pressure moves across [hours], first reading to last.
  ///
  /// **Forward-looking, unlike the snapshot's**, and deliberately the same
  /// label: an attack's stored delta is the 24 hours before it was logged,
  /// this is the 24 hours ahead. Both answer "how far is the pressure
  /// moving", which is the question this app is about, and a user reading a
  /// forecast is already reading the future.
  ///
  /// Null under two readings, because one hour describes no change at all.
  static double? _pressureChange(Iterable<WeatherHourly> hours) {
    final List<WeatherHourly> ordered = hours.toList();

    if (ordered.length < 2) return null;

    return ordered.last.pressureHpa - ordered.first.pressureHpa;
  }

  /// The mean of the values that exist, or null when none do — an hour Apple
  /// had no reading for must not be counted as a zero.
  static double? _mean(Iterable<double?> values) {
    final List<double> present = values.nonNulls.toList();

    if (present.isEmpty) return null;

    return present.reduce((double a, double b) => a + b) / present.length;
  }

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
      visibilityKm == null &&
      precipitationChancePercent == null &&
      precipitationAmountMm == null &&
      sunrise == null &&
      sunset == null &&
      days.isEmpty;
}
