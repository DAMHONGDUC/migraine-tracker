import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../domain/entities/geo_point.dart';
import '../../domain/repositories/place_repository.dart';
import '../datasources/location_source.dart';
import '../datasources/place_name_source.dart';

/// The device's position, run through the platform's geocoder.
///
/// The same shape as `BackendWeatherRepository`: read the point, hand it to
/// the source, answer null for everything that can go wrong on the way.
class GeocodedPlaceRepository implements PlaceRepository {
  const GeocodedPlaceRepository(this._location, this._names);

  final LocationSource _location;
  final PlaceNameSource _names;

  @override
  Future<String?> currentPlaceName({required String localeIdentifier}) async {
    final GeoPoint? point = await _location.currentPosition();

    if (point == null) {
      SdLogger.info(
        LogTagConstant.location,
        'Place name skipped: no location/permission',
      );

      return null;
    }

    return _names.nameAt(point, localeIdentifier: localeIdentifier);
  }
}
