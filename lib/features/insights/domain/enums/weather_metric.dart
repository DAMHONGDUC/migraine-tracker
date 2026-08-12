/// Which reading the weather card's hourly row is showing.
///
/// iOS Weather's own list, minus pressure: that one belongs to `/pressure`,
/// where it is the premium chart, and showing it here would be the same
/// reading free on one screen and sold on another.
enum WeatherMetric {
  conditions,
  uvIndex,
  wind,
  precipitation,
  humidity,
  visibility,
}
