/// Where the user is, in words.
abstract interface class PlaceRepository {
  /// The name of the place the device is in, or null when there is no position, no permission, or no name for it.
  Future<String?> currentPlaceName({required String localeIdentifier});
}
