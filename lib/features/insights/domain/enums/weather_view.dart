/// Which face of the weather card is showing.
///
/// [chart] is first, and first is the default: the pressure line is the
/// reading this app exists for, and it sits directly above the alert that
/// acts on it. The other three are iOS Weather's own — the hours ahead, the
/// days after them, and the readings that fit on neither.
enum WeatherView { chart, hourly, daily, details }
