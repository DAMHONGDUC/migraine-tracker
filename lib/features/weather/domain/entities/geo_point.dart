import 'package:meta/meta.dart';

/// A coarse position — reduced accuracy is all this app ever requests.
@immutable
class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}
