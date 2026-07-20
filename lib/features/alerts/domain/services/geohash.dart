const _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

/// Encodes lat/lon positions to geohashes. The app always uses [precision] 5
/// (~±2.4 km) — coarse on purpose (hard rule 1): the backend only needs a
/// weather cell, never a precise location. Mirrors the decoder in
/// `functions/src/core/geohash.ts`.
class Geohash {
  const Geohash._();

  static String encode(
    double latitude,
    double longitude, {
    int precision = 5,
  }) {
    var latMin = -90.0, latMax = 90.0;
    var lonMin = -180.0, lonMax = 180.0;
    var even = true;
    var bits = 0;
    var bitCount = 0;
    final buffer = StringBuffer();

    while (buffer.length < precision) {
      if (even) {
        final mid = (lonMin + lonMax) / 2;
        if (longitude >= mid) {
          bits = (bits << 1) | 1;
          lonMin = mid;
        } else {
          bits = bits << 1;
          lonMax = mid;
        }
      } else {
        final mid = (latMin + latMax) / 2;
        if (latitude >= mid) {
          bits = (bits << 1) | 1;
          latMin = mid;
        } else {
          bits = bits << 1;
          latMax = mid;
        }
      }
      even = !even;
      bitCount++;
      if (bitCount == 5) {
        buffer.write(_base32[bits]);
        bits = 0;
        bitCount = 0;
      }
    }
    return buffer.toString();
  }
}
