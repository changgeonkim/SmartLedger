import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import '../core/utils/geo_utils.dart';

class GeocodingService {
  GeocodingService._();
  static final instance = GeocodingService._();

  // 앱 세션 동안만 유지 — 재시작 시 소멸, Firestore 저장 없음
  final _cache = <String, String>{};

  Future<String?> reverseGeocode(double lat, double lng) async {
    final key = GeoUtils.cacheKey(lat, lng);
    if (_cache.containsKey(key)) return _cache[key];

    try {
      final uri = Uri.parse(
        'https://naveropenapi.apigw.ntruss.com/map-reversegeocode/v2/gc'
        '?coords=$lng,$lat&output=json&orders=roadaddr,addr',
      );
      final response = await http.get(uri, headers: {
        'X-NCP-APIGW-API-KEY-ID': AppConfig.naverMapsClientId,
        'X-NCP-APIGW-API-KEY': AppConfig.naverMapsClientSecret,
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final results = json['results'] as List?;
      if (results == null || results.isEmpty) return null;

      final address = _parseAddress(results.first as Map<String, dynamic>);
      if (address != null) _cache[key] = address;
      return address;
    } catch (_) {
      return null;
    }
  }

  String? _parseAddress(Map<String, dynamic> result) {
    try {
      final region = result['region'] as Map<String, dynamic>;
      final land = result['land'] as Map<String, dynamic>?;

      final area1 = (region['area1'] as Map)['name'] as String? ?? '';
      final area2 = (region['area2'] as Map)['name'] as String? ?? '';
      final area3 = (region['area3'] as Map)['name'] as String? ?? '';

      // 도로명 주소 우선
      if (land != null) {
        final roadName = land['name'] as String? ?? '';
        final num1 = land['number1'] as String? ?? '';
        if (roadName.isNotEmpty) {
          return '$area1 $area2 $roadName $num1'.trim();
        }
      }

      // 지번 주소 fallback
      return '$area1 $area2 $area3'.trim().isEmpty
          ? null
          : '$area1 $area2 $area3'.trim();
    } catch (_) {
      return null;
    }
  }
}
