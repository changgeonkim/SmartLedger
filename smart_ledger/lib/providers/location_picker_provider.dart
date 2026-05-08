import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../core/utils/geo_utils.dart';
import '../models/place_result.dart';
import '../services/geocoding_service.dart';
import '../services/place_search_service.dart';

// ── State ─────────────────────────────────────────────────────────────────

@immutable
class LocationPickerState {
  // Core — 저장/로직에 영향
  final double? pinLat;
  final double? pinLng;
  final PlaceResult? selectedPlace;
  final List<PlaceResult> nearbyPlaces;
  final String? lastNearbySearchGeohash; // geohash7 기반 중복 호출 방지

  // GPS — 초기화용 (현재 위치 FAB 복귀용)
  final double? gpsLat;
  final double? gpsLng;

  // UI — 표시 목적만 (저장 안 함)
  final String? displayAddress;
  final List<PlaceResult> searchResults;

  // Loading
  final bool isInitializing;
  final bool isLoadingNearby;
  final bool isLoadingAddress;
  final bool isSearching;

  const LocationPickerState({
    this.pinLat,
    this.pinLng,
    this.selectedPlace,
    this.nearbyPlaces = const [],
    this.lastNearbySearchGeohash,
    this.gpsLat,
    this.gpsLng,
    this.displayAddress,
    this.searchResults = const [],
    this.isInitializing = false,
    this.isLoadingNearby = false,
    this.isLoadingAddress = false,
    this.isSearching = false,
  });

  // 저장 시 사용할 확정 좌표: 장소 선택 > 핀 > GPS
  double? get effectiveLat => selectedPlace?.lat ?? pinLat ?? gpsLat;
  double? get effectiveLng => selectedPlace?.lng ?? pinLng ?? gpsLng;
  bool get canSave => effectiveLat != null;
  bool get hasNearby => nearbyPlaces.isNotEmpty;

  LocationPickerState copyWith({
    double? pinLat,
    double? pinLng,
    PlaceResult? selectedPlace,
    List<PlaceResult>? nearbyPlaces,
    String? lastNearbySearchGeohash,
    double? gpsLat,
    double? gpsLng,
    String? displayAddress,
    List<PlaceResult>? searchResults,
    bool? isInitializing,
    bool? isLoadingNearby,
    bool? isLoadingAddress,
    bool? isSearching,
    bool clearSelectedPlace = false,
    bool clearNearbyPlaces = false,
    bool clearSearchResults = false,
    bool clearDisplayAddress = false,
    bool clearLastGeohash = false,
  }) {
    return LocationPickerState(
      pinLat: pinLat ?? this.pinLat,
      pinLng: pinLng ?? this.pinLng,
      selectedPlace:
          clearSelectedPlace ? null : (selectedPlace ?? this.selectedPlace),
      nearbyPlaces:
          clearNearbyPlaces ? [] : (nearbyPlaces ?? this.nearbyPlaces),
      lastNearbySearchGeohash: clearLastGeohash
          ? null
          : (lastNearbySearchGeohash ?? this.lastNearbySearchGeohash),
      gpsLat: gpsLat ?? this.gpsLat,
      gpsLng: gpsLng ?? this.gpsLng,
      displayAddress: clearDisplayAddress
          ? null
          : (displayAddress ?? this.displayAddress),
      searchResults:
          clearSearchResults ? [] : (searchResults ?? this.searchResults),
      isInitializing: isInitializing ?? this.isInitializing,
      isLoadingNearby: isLoadingNearby ?? this.isLoadingNearby,
      isLoadingAddress: isLoadingAddress ?? this.isLoadingAddress,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────

final locationPickerProvider = StateNotifierProvider.autoDispose<
    LocationPickerNotifier, LocationPickerState>(
  (_) => LocationPickerNotifier(),
);

// ── Notifier ──────────────────────────────────────────────────────────────

class LocationPickerNotifier extends StateNotifier<LocationPickerState> {
  LocationPickerNotifier() : super(const LocationPickerState());

  // 1. 진입 초기화 — GPS 취득 or 기존 좌표 사용
  Future<void> initialize({double? lat, double? lng}) async {
    if (lat != null && lng != null) {
      state = state.copyWith(
        gpsLat: lat,
        gpsLng: lng,
        pinLat: lat,
        pinLng: lng,
      );
      return;
    }

    state = state.copyWith(isInitializing: true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        debugPrint('[LocationPicker] GPS 권한 없음 — 지도 중심을 초기 pin으로 사용');
        // pinLat/Lng는 null 유지 → onMapReady에서 지도 중심으로 세팅됨
        state = state.copyWith(isInitializing: false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      if (!mounted) return;
      state = state.copyWith(
        gpsLat: pos.latitude,
        gpsLng: pos.longitude,
        pinLat: pos.latitude,
        pinLng: pos.longitude,
        isInitializing: false,
      );
    } catch (e) {
      debugPrint('[LocationPicker] GPS 실패: $e');
      if (mounted) state = state.copyWith(isInitializing: false);
    }
  }

  // GPS 없이 지도 중심 좌표를 초기 pin으로 설정 (onMapReady fallback용)
  void setInitialPinFromMap(double lat, double lng) {
    if (state.pinLat != null) return; // 이미 GPS로 설정된 경우 무시
    state = state.copyWith(pinLat: lat, pinLng: lng);
  }

  // 2. 지도 드래그 → pin 이동, selectedPlace / nearbyPlaces / geohash 초기화
  //    geohash도 같이 지워야 같은 구역에서 [주변 장소 찾기]가 다시 작동함
  void updatePinPosition(double lat, double lng) {
    state = state.copyWith(
      pinLat: lat,
      pinLng: lng,
      clearSelectedPlace: true,
      clearNearbyPlaces: true,
      clearDisplayAddress: true,
      clearLastGeohash: true,
    );
  }

  // 3. [주변 장소 찾기] — geohash7 단위 중복 방지
  Future<void> searchNearbyPlaces() async {
    final lat = state.pinLat ?? state.gpsLat;
    final lng = state.pinLng ?? state.gpsLng;
    if (lat == null || lng == null) return;

    final currentGeohash =
        GeoUtils.encodeGeohash(lat, lng, precision: 7);
    if (currentGeohash == state.lastNearbySearchGeohash) return;

    state = state.copyWith(isLoadingNearby: true);

    final places =
        await PlaceSearchService.instance.searchNearby(lat, lng);
    if (!mounted) return;

    debugPrint('[LocationPicker] nearby 결과: ${places.length}개');
    state = state.copyWith(
      nearbyPlaces: places,
      // 결과가 있을 때만 geohash 저장 → 빈 결과(API 오류 포함) 시 재시도 허용
      lastNearbySearchGeohash: places.isNotEmpty ? currentGeohash : null,
      isLoadingNearby: false,
    );

    // nearby가 비어있을 때만 reverseGeocode fallback (background)
    if (places.isEmpty) {
      debugPrint('[LocationPicker] nearby 없음, reverseGeocode fallback 시도');
      _loadAddressBackground(lat, lng);
    }
  }

  // 4. reverseGeocode — fallback 또는 수동 호출
  Future<void> searchAddress() async {
    final lat = state.pinLat ?? state.gpsLat;
    final lng = state.pinLng ?? state.gpsLng;
    if (lat == null || lng == null) return;
    _loadAddressBackground(lat, lng);
  }

  Future<void> _loadAddressBackground(double lat, double lng) async {
    state = state.copyWith(isLoadingAddress: true);
    final addr =
        await GeocodingService.instance.reverseGeocode(lat, lng);
    if (!mounted) return;
    state = state.copyWith(
      displayAddress: addr,
      isLoadingAddress: false,
    );
  }

  // 5. 검색창 키워드 검색
  Future<void> searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(clearSearchResults: true);
      return;
    }
    state = state.copyWith(isSearching: true);
    final results = await PlaceSearchService.instance.searchByKeyword(
      query,
      lat: state.pinLat ?? state.gpsLat,
      lng: state.pinLng ?? state.gpsLng,
    );
    if (!mounted) return;
    state = state.copyWith(
      searchResults: results,
      isSearching: false,
    );
  }

  // 6. 장소 선택 (칩 탭 or 검색 결과 탭)
  void selectPlace(PlaceResult place) {
    state = state.copyWith(
      selectedPlace: place,
      pinLat: place.lat,
      pinLng: place.lng,
      displayAddress: place.address,
      clearSearchResults: true,
    );
  }

  // 7. 선택 해제 ("위치만" 칩 탭)
  void clearSelection() {
    state = state.copyWith(clearSelectedPlace: true);
  }
}
