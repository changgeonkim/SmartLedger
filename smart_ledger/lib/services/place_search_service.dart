import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import '../models/place_result.dart';

class PlaceSearchService {
  PlaceSearchService._();
  static final instance = PlaceSearchService._();

  static const _timeout = Duration(seconds: 5);

  Map<String, String> get _headers => {
        'Authorization': 'KakaoAK ${AppConfig.kakaoRestApiKey}',
      };

  // 좌표 기반 주변 장소 — 음식점·카페·편의점 병렬 조회, 거리순 최대 10개
  Future<List<PlaceResult>> searchNearby(double lat, double lng) async {
    final results = await Future.wait([
      _categorySearch(lat, lng, 'FD6'), // 음식점
      _categorySearch(lat, lng, 'CE7'), // 카페
      _categorySearch(lat, lng, 'CS2'), // 편의점
    ]);
    final merged = results.expand((list) => list).toList()
      ..sort((a, b) =>
          (a.distance ?? 9999).compareTo(b.distance ?? 9999));
    return merged.take(10).toList();
  }

  Future<List<PlaceResult>> _categorySearch(
      double lat, double lng, String code) async {
    try {
      final uri = Uri.parse(
        'https://dapi.kakao.com/v2/local/search/category.json'
        '?category_group_code=$code'
        '&x=${lng.toStringAsFixed(6)}'
        '&y=${lat.toStringAsFixed(6)}'
        '&radius=500&size=5&sort=distance',
      );
      final res =
          await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode != 200) {
        debugPrint('[PlaceSearch] category $code → ${res.statusCode}: ${res.body}');
        return [];
      }
      return _parseDocuments(jsonDecode(res.body));
    } catch (e) {
      debugPrint('[PlaceSearch] category $code exception: $e');
      return [];
    }
  }

  // 키워드 검색 — 검색창 전용
  Future<List<PlaceResult>> searchByKeyword(
    String query, {
    double? lat,
    double? lng,
  }) async {
    if (query.trim().isEmpty) return [];
    try {
      final params = <String, String>{'query': query, 'size': '10'};
      if (lat != null && lng != null) {
        params['x'] = lng.toStringAsFixed(6);
        params['y'] = lat.toStringAsFixed(6);
        params['sort'] = 'distance';
      }
      final uri = Uri.https(
          'dapi.kakao.com', '/v2/local/search/keyword.json', params);
      final res =
          await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode != 200) {
        debugPrint('[PlaceSearch] keyword "$query" → ${res.statusCode}: ${res.body}');
        return [];
      }
      return _parseDocuments(jsonDecode(res.body));
    } catch (e) {
      debugPrint('[PlaceSearch] keyword "$query" exception: $e');
      return [];
    }
  }

  List<PlaceResult> _parseDocuments(Map<String, dynamic> json) {
    final docs = json['documents'] as List? ?? [];
    return docs.map((d) {
      final doc = d as Map<String, dynamic>;
      final lat = double.tryParse(doc['y'] as String? ?? '');
      final lng = double.tryParse(doc['x'] as String? ?? '');
      if (lat == null || lng == null) return null;
      final roadAddr = doc['road_address_name'] as String? ?? '';
      final addr = doc['address_name'] as String? ?? '';
      return PlaceResult(
        name: doc['place_name'] as String? ?? '',
        category: doc['category_name'] as String?,
        address: roadAddr.isNotEmpty
            ? roadAddr
            : (addr.isNotEmpty ? addr : null),
        lat: lat,
        lng: lng,
        distance:
            double.tryParse(doc['distance'] as String? ?? ''),
      );
    }).whereType<PlaceResult>().where((p) => p.name.isNotEmpty).toList();
  }
}
