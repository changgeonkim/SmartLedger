import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/app_colors.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  NaverMapController? _mapController;

  static const _defaultTarget = NLatLng(37.5666, 126.9784); // 서울 기본값
  static const _defaultZoom = 14.0;

  bool _locationGranted = false;
  bool _locationLoading = true;

  @override
  void initState() {
    super.initState();
    _requestLocation();
  }

  Future<void> _requestLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _locationLoading = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    final granted = permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;

    setState(() {
      _locationGranted = granted;
      _locationLoading = false;
    });

    if (granted) {
      _moveToCurrentLocation();
    }
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final controller = _mapController;
      if (controller == null || !mounted) return;
      await controller.updateCamera(
        NCameraUpdate.withParams(
          target: NLatLng(pos.latitude, pos.longitude),
          zoom: 16,
        ),
      );
      controller.setLocationTrackingMode(NLocationTrackingMode.follow);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('지도'),
        actions: [
          if (_locationGranted)
            IconButton(
              icon: const Icon(Icons.my_location),
              tooltip: '현재 위치',
              onPressed: _moveToCurrentLocation,
            ),
        ],
      ),
      body: Stack(
        children: [
          NaverMap(
            options: NaverMapViewOptions(
              initialCameraPosition: const NCameraPosition(
                target: _defaultTarget,
                zoom: _defaultZoom,
              ),
              locationButtonEnable: _locationGranted,
              scrollGesturesEnable: true,
              zoomGesturesEnable: true,
              tiltGesturesEnable: true,
              rotationGesturesEnable: true,
            ),
            onMapReady: (controller) {
              _mapController = controller;
              if (_locationGranted) _moveToCurrentLocation();
            },
          ),
          if (_locationLoading)
            const Center(child: CircularProgressIndicator()),
          if (!_locationLoading && !_locationGranted)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.location_off, color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '위치 권한이 없어 현재 위치를 표시할 수 없습니다.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await Geolocator.openAppSettings();
                        },
                        child: const Text('설정'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
