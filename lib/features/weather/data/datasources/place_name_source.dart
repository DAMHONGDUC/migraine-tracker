import 'dart:ui';

import 'package:geocoding/geocoding.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../domain/entities/geo_point.dart';

/// Turns a coordinate into the name of the place it falls in.
///
/// Abstracted for the same reason [LocationSource] is: the plugin talks to
/// the OS, so nothing above this is testable while it is called directly.
abstract interface class PlaceNameSource {
  /// The most specific name the platform has for [point], or null when it has
  /// none. Never throws — a card without a place name is still a card.
  ///
  /// [localeIdentifier] is the app's own language, not the device's: a user
  /// reading the app in Vietnamese must not get their district in English.
  Future<String?> nameAt(GeoPoint point, {required String localeIdentifier});
}

/// The platform's own geocoder — `CLGeocoder` on iOS, `Geocoder` on Android.
///
/// **No API key and no service of ours.** The coordinate goes to the OS,
/// which answers from Apple's or Google's geocoder; the app's backend never
/// sees a position finer than the ~11km it already rounds to.
class GeocodingPlaceNameSource implements PlaceNameSource {
  const GeocodingPlaceNameSource();

  @override
  Future<String?> nameAt(
    GeoPoint point, {
    required String localeIdentifier,
  }) async {
    try {
      // Per call, not on the instance: `Geocoding({locale})` drops the
      // argument on the floor in 5.0.0, so a constructor locale is a no-op.
      final List<Placemark> places = await Geocoding()
          .placemarkFromCoordinates(
            point.latitude,
            point.longitude,
            locale: Locale(localeIdentifier),
          );
      final String? name = places.isEmpty ? null : _name(places.first);

      SdLogger.info(LogTagConstant.location, 'Reverse geocoded', name);

      return name;
    } catch (error) {
      // - a name is decoration on a weather card, so this is recoverable
      // - `.warning` prints the error without filing a non-fatal for it
      SdLogger.warning(
        LogTagConstant.location,
        'Reverse geocoding failed',
        error,
      );

      return null;
    }
  }

  /// The narrowest field the platform filled in, widening until one lands.
  ///
  /// **One name, never a chain of them.** The card has a line, not a
  /// paragraph, and the user already knows which country they are standing
  /// in — what they cannot tell from a temperature is which side of town it
  /// was measured on.
  ///
  /// Ward first, then district, then city: the app asks for reduced accuracy
  /// (hard rule 2), so the ward is often absent and the honest answer is the
  /// widest one that is actually true.
  String? _name(Placemark place) {
    final List<String?> candidates = <String?>[
      place.subLocality,
      place.subAdministrativeArea,
      place.locality,
      place.administrativeArea,
      place.country,
    ];

    return candidates
        .map((String? value) => value?.trim())
        .firstWhere(
          (String? value) => value != null && value.isNotEmpty,
          orElse: () => null,
        );
  }
}
