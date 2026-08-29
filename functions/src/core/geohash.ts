const BASE32 = "0123456789bcdefghjkmnpqrstuvwxyz";

export interface LatLon {
  lat: number;
  lon: number;
}

/** Decodes a geohash to the center of its bounding box. The app stores 5-char hashes (~±2.4km), which is all the precision alerts ever need. */
export function geohashCenter(hash: string): LatLon {
  if (hash.length === 0) throw new Error("empty geohash");
  let even = true;
  let latMin = -90;
  let latMax = 90;
  let lonMin = -180;
  let lonMax = 180;

  for (const char of hash.toLowerCase()) {
    const bits = BASE32.indexOf(char);
    if (bits === -1) throw new Error(`invalid geohash char: ${char}`);
    for (let mask = 16; mask >= 1; mask >>= 1) {
      if (even) {
        const mid = (lonMin + lonMax) / 2;
        if (bits & mask) lonMin = mid;
        else lonMax = mid;
      } else {
        const mid = (latMin + latMax) / 2;
        if (bits & mask) latMin = mid;
        else latMax = mid;
      }
      even = !even;
    }
  }
  return { lat: (latMin + latMax) / 2, lon: (lonMin + lonMax) / 2 };
}
