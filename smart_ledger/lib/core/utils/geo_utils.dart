class GeoUtils {
  static const _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  static String encodeGeohash(double lat, double lng, {int precision = 8}) {
    var minLat = -90.0, maxLat = 90.0;
    var minLng = -180.0, maxLng = 180.0;
    var result = '';
    var bits = 0;
    var hashValue = 0;
    var isEven = true;

    while (result.length < precision) {
      if (isEven) {
        final mid = (minLng + maxLng) / 2;
        if (lng >= mid) {
          hashValue = (hashValue << 1) | 1;
          minLng = mid;
        } else {
          hashValue = hashValue << 1;
          maxLng = mid;
        }
      } else {
        final mid = (minLat + maxLat) / 2;
        if (lat >= mid) {
          hashValue = (hashValue << 1) | 1;
          minLat = mid;
        } else {
          hashValue = hashValue << 1;
          maxLat = mid;
        }
      }
      isEven = !isEven;
      if (++bits == 5) {
        result += _base32[hashValue];
        bits = 0;
        hashValue = 0;
      }
    }
    return result;
  }

  // reverse geocoding 세션 캐시 키: ~11m 단위 스냅
  static String cacheKey(double lat, double lng) {
    final la = (lat * 10000).round() / 10000;
    final lo = (lng * 10000).round() / 10000;
    return '${la}_$lo';
  }
}
