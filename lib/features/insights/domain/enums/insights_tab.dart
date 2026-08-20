/// Which of Insights' cards is showing.
///
/// One tab per card: the pressure the user is in, then what their own body
/// did. **Weather is not one of them any more** — the live conditions moved
/// to the dashboard (`CurrentWeatherCard`), where a glance does not cost a
/// tab switch.
///
/// [sleep] is absent off iOS, where there is no HealthKit to read it from —
/// the screen builds its tab list from what is actually available rather than
/// offering a tab that could only say "unavailable".
enum InsightsTab { pressure, activity, sleep }
