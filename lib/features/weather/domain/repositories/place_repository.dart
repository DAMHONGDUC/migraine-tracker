/// Where the user is, in words.
///
/// Its own repository rather than a method on [WeatherRepository]: the weather
/// comes from the backend and the name comes from the OS, and one interface
/// over two unrelated sources is what makes a fake in a test have to stub
/// both to answer either.
abstract interface class PlaceRepository {
  /// The name of the place the device is in, or null when there is no
  /// position, no permission, or no name for it. Best-effort like every other
  /// location read (hard rule 4) — it never throws.
  ///
  /// [localeIdentifier] is the app's language, so the name is in the one the
  /// rest of the screen is written in.
  Future<String?> currentPlaceName({required String localeIdentifier});
}
