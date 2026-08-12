/// Which of Insights' cards is showing.
///
/// One tab per card, in the order the screen used to stack them: the weather
/// you are in, the pressure inside it, then what your own body did.
///
/// [sleep] is absent off iOS, where there is no HealthKit to read it from —
/// the screen builds its tab list from what is actually available rather than
/// offering a tab that could only say "unavailable".
enum InsightsTab { weather, pressure, activity, sleep }
