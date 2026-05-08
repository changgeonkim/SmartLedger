import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/format_utils.dart';
import '../../models/expense_model.dart';
import '../../providers/map_provider.dart';
import '../../services/geocoding_service.dart';
import '../expense/expense_detail_screen.dart';

// ── 데이터 클래스 ──────────────────────────────────────────────

class _ExpenseCluster {
  final double lat;
  final double lng;
  final List<ExpenseModel> expenses;

  const _ExpenseCluster({
    required this.lat,
    required this.lng,
    required this.expenses,
  });

  double get totalAmount => expenses.fold(0.0, (s, e) => s + e.amount);
}

// ── 화면 ───────────────────────────────────────────────────────

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  NaverMapController? _mapController;
  Timer? _debounce;
  double _currentZoom = 14.0;

  static const _defaultTarget = NLatLng(37.5666, 126.9784);
  static const _defaultZoom = 14.0;

  bool _locationGranted = false;
  bool _locationLoading = true;

  @override
  void initState() {
    super.initState();
    _requestLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // ── 위치 권한 ──

  Future<void> _requestLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _locationLoading = false);
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    final granted = permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
    setState(() {
      _locationGranted = granted;
      _locationLoading = false;
    });
    if (granted) _moveToCurrentLocation();
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final ctrl = _mapController;
      if (ctrl == null || !mounted) return;
      await ctrl.updateCamera(
        NCameraUpdate.withParams(target: NLatLng(pos.latitude, pos.longitude), zoom: 16),
      );
      ctrl.setLocationTrackingMode(NLocationTrackingMode.follow);
    } catch (_) {}
  }

  // ── 클러스터링 ──

  /// 줌 레벨 → geohash precision 매핑
  int _precisionForZoom(double zoom) {
    if (zoom >= 17) return 8; // ~38m  건물 단위
    if (zoom >= 15) return 7; // ~153m 블록 단위
    if (zoom >= 13) return 6; // ~1.2km 동네 단위
    if (zoom >= 10) return 5; // ~5km  구 단위
    return 4;                 // ~20km 시 단위
  }

  List<_ExpenseCluster> _clusterExpenses(List<ExpenseModel> expenses, int precision) {
    final groups = <String, List<ExpenseModel>>{};
    for (final e in expenses) {
      if (!e.hasLocation || e.geohash8 == null) continue;
      final key = e.geohash8!.substring(0, precision.clamp(1, 8));
      groups.putIfAbsent(key, () => []).add(e);
    }
    return groups.values.map((list) {
      final avgLat = list.map((e) => e.lat!).reduce((a, b) => a + b) / list.length;
      final avgLng = list.map((e) => e.lng!).reduce((a, b) => a + b) / list.length;
      return _ExpenseCluster(lat: avgLat, lng: avgLng, expenses: list);
    }).toList();
  }

  Color _markerColor(int count) {
    if (count == 1) return const Color(0xFF1D4ED8); // 진한 파랑
    if (count < 5) return const Color(0xFFB45309);  // 진한 주황
    return const Color(0xFFB91C1C);                 // 진한 빨강 (hotspot)
  }

  // ── 마커 갱신 ──

  Future<void> _refreshMarkers() async {
    final ctrl = _mapController;
    if (ctrl == null) return;

    final expenses = ref.read(locationExpensesProvider).valueOrNull ?? [];
    final clusters = _clusterExpenses(expenses, _precisionForZoom(_currentZoom));

    await ctrl.clearOverlays(type: NOverlayType.marker);
    if (clusters.isEmpty) return;

    final markers = clusters.asMap().entries.map((entry) {
      final i = entry.key;
      final cluster = entry.value;
      final isMultiple = cluster.expenses.length > 1;

      final marker = NMarker(
        id: 'cluster_$i',
        position: NLatLng(cluster.lat, cluster.lng),
      );
      marker.setCaption(NOverlayCaption(
        text: isMultiple
            ? '${cluster.expenses.length}건'
            : FormatUtils.formatWon(cluster.expenses.first.amount),
        textSize: 11,
        color: Colors.white,
        haloColor: Colors.black87,
      ));
      marker.setIconTintColor(_markerColor(cluster.expenses.length));
      marker.setOnTapListener((_) => _showClusterSheet(cluster));
      return marker;
    }).toSet();

    await ctrl.addOverlayAll(markers);
  }

  void _onCameraChange(NCameraUpdateReason reason, bool animated) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final ctrl = _mapController;
      if (ctrl == null || !mounted) return;
      final pos = await ctrl.getCameraPosition();
      if (!mounted) return;
      _currentZoom = pos.zoom;
      _refreshMarkers();
    });
  }

  // ── 바텀시트 ──

  void _showClusterSheet(_ExpenseCluster cluster) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
      builder: (_) => _ClusterSheet(cluster: cluster),
    );
  }

  // ── 빌드 ──

  @override
  Widget build(BuildContext context) {
    // expenses 로드 완료 시 마커 갱신
    ref.listen(locationExpensesProvider, (_, next) {
      if (next.hasValue) _refreshMarkers();
    });

    final expensesAsync = ref.watch(locationExpensesProvider);

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
            onMapReady: (ctrl) {
              _mapController = ctrl;
              if (_locationGranted) _moveToCurrentLocation();
              _refreshMarkers();
            },
            onCameraChange: _onCameraChange,
          ),
          if (_locationLoading)
            const Center(child: CircularProgressIndicator()),
          // expenses 로딩 인디케이터 (지도 우상단)
          if (expensesAsync.isLoading)
            const Positioned(
              top: 12,
              right: 12,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
          if (!_locationLoading && !_locationGranted)
            _PermissionBanner(),
        ],
      ),
    );
  }
}

// ── 위치 권한 배너 ─────────────────────────────────────────────

class _PermissionBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
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
                onPressed: Geolocator.openAppSettings,
                child: const Text('설정'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 클러스터 바텀시트 ──────────────────────────────────────────

class _ClusterSheet extends StatefulWidget {
  final _ExpenseCluster cluster;
  const _ClusterSheet({required this.cluster});

  @override
  State<_ClusterSheet> createState() => _ClusterSheetState();
}

class _ClusterSheetState extends State<_ClusterSheet> {
  String? _address;
  bool _addressLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    final addr = await GeocodingService.instance.reverseGeocode(
      widget.cluster.lat,
      widget.cluster.lng,
    );
    if (mounted) setState(() { _address = addr; _addressLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final expenses = widget.cluster.expenses;
    final isMultiple = expenses.length > 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 드래그 핸들
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 주소 행 (역지오코딩 결과, 세션 캐시)
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              if (_addressLoading)
                const SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                )
              else
                Expanded(
                  child: Text(
                    _address ?? '주소를 불러올 수 없음',
                    style: AppTextStyles.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // 헤더 (장소명 + 금액)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isMultiple
                      ? '${expenses.length}개 소비 내역'
                      : (expenses.first.storeName.isNotEmpty
                          ? expenses.first.storeName
                          : expenses.first.categoryName),
                  style: AppTextStyles.heading2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                FormatUtils.formatWon(widget.cluster.totalAmount),
                style: AppTextStyles.heading2.copyWith(color: AppColors.expense),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          // 내역 리스트
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: expenses.length,
              itemBuilder: (ctx, i) {
                final e = expenses[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 2),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    radius: 18,
                    child: Text(
                      e.categoryName.isNotEmpty ? e.categoryName[0] : '?',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  title: Text(
                    e.storeName.isNotEmpty ? e.storeName : e.categoryName,
                    style: AppTextStyles.body,
                  ),
                  subtitle: Text(
                    AppDateUtils.formatDate(e.paymentDate),
                    style: AppTextStyles.caption,
                  ),
                  trailing: Text(
                    FormatUtils.formatWon(e.amount),
                    style: AppTextStyles.amount.copyWith(color: AppColors.expense),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    showDialog(
                      context: context,
                      builder: (_) => ExpenseDetailScreen(expense: e),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
