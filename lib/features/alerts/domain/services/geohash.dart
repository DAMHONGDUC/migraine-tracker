const _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

/// Encodes lat/lon positions to geohashes.
class Geohash {
  const Geohash._();

  static String encode(double latitude, double longitude, {int precision = 5}) {
    double latMin = -90.0, latMax = 90.0;
    double lonMin = -180.0, lonMax = 180.0;
    bool even = true;
    int bits = 0;
    int bitCount = 0;
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
