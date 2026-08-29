import 'dart:ui';

import 'package:geocoding/geocoding.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../domain/entities/geo_point.dart';

/// Turns a coordinate into the name of the place it falls in.
abstract interface class PlaceNameSource {
  /// The most specific name the platform has for [point], or null when it has none.
  Future<String?> nameAt(GeoPoint point, {required String localeIdentifier});
}

/// The platform's own geocoder — `CLGeocoder` on iOS, `Geocoder` on Android.
class GeocodingPlaceNameSource implements PlaceNameSource {
  const GeocodingPlaceNameSource();

  @override
  Future<String?> nameAt(
    GeoPoint point, {
    required String localeIdentifier,
  }) async {
    try {
      // Per call, not on the instance: `Geocoding({locale})` drops the argument on the floor in 5.0.0, so a constructor locale is a no-op.
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
      // - a name is decoration on a weather card, so this is recoverable - `.warning` prints the error without filing a non-fatal for it
      SdLogger.warning(
        LogTagConstant.location,
        'Reverse geocoding failed',
        error,
      );

      return null;
    }
  }

  /// The narrowest field the platform filled in, widening until one lands.
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
