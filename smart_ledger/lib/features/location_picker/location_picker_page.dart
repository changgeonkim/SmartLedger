import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/place_result.dart';
import '../../providers/location_picker_provider.dart';

class LocationPickerPage extends ConsumerStatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const LocationPickerPage({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  @override
  ConsumerState<LocationPickerPage> createState() =>
      _LocationPickerPageState();
}

class _LocationPickerPageState extends ConsumerState<LocationPickerPage> {
  NaverMapController? _ctrl;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  bool _showDropdown = false;
  Timer? _cameraDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationPickerProvider.notifier).initialize(
            lat: widget.initialLat,
            lng: widget.initialLng,
          );
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _cameraDebounce?.cancel();
    super.dispose();
  }

  // 사용자 드래그(gesture)일 때만 pin 위치 업데이트
  // developer(programmatic) 이동은 무시 → 장소 선택 후 selectedPlace 보존
  void _onCameraChange(NCameraUpdateReason reason, bool animated) {
    if (reason != NCameraUpdateReason.gesture) return;
    _cameraDebounce?.cancel();
    _cameraDebounce =
        Timer(const Duration(milliseconds: 300), _onCameraIdle);
  }

  Future<void> _onCameraIdle() async {
    if (_ctrl == null || !mounted) return;
    final pos = await _ctrl!.getCameraPosition();
    if (!mounted) return;
    ref.read(locationPickerProvider.notifier).updatePinPosition(
          pos.target.latitude,
          pos.target.longitude,
        );
  }

  void _moveCameraTo(double lat, double lng, {double zoom = 17}) {
    _ctrl?.updateCamera(
      NCameraUpdate.withParams(
        target: NLatLng(lat, lng),
        zoom: zoom,
      ),
    );
  }

  void _confirm() {
    final s = ref.read(locationPickerProvider);
    if (!s.canSave) return;
    Navigator.of(context).pop(LocationPickerResult(
      lat: s.effectiveLat!,
      lng: s.effectiveLng!,
      userSelectedPlaceName: s.selectedPlace?.name,
      displayAddress: s.selectedPlace?.address ?? s.displayAddress,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(locationPickerProvider);

    // GPS 취득 완료 시 지도 이동 (onMapReady보다 늦게 도착하는 경우 대비)
    ref.listen<LocationPickerState>(locationPickerProvider, (prev, next) {
      if (prev?.gpsLat == null && next.gpsLat != null && _ctrl != null) {
        _moveCameraTo(next.gpsLat!, next.gpsLng!, zoom: 16);
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // ── 전체화면 지도 ──────────────────────────────────────
          NaverMap(
            options: NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(
                target: NLatLng(
                  state.gpsLat ?? 37.5666,
                  state.gpsLng ?? 126.9784,
                ),
                zoom: 16,
              ),
              scrollGesturesEnable: true,
              zoomGesturesEnable: true,
              rotationGesturesEnable: false,
              tiltGesturesEnable: false,
              locationButtonEnable: false,
            ),
            onMapReady: (ctrl) async {
              _ctrl = ctrl;
              final s = ref.read(locationPickerProvider);
              if (s.pinLat != null) {
                _moveCameraTo(s.pinLat!, s.pinLng!, zoom: 16);
              } else {
                // GPS 권한 없는 경우: 지도 초기 중심을 pin 위치로 사용
                final pos = await ctrl.getCameraPosition();
                if (mounted) {
                  ref.read(locationPickerProvider.notifier)
                      .setInitialPinFromMap(
                        pos.target.latitude,
                        pos.target.longitude,
                      );
                }
              }
            },
            onCameraChange: _onCameraChange,
          ),

          // ── 중앙 고정 핀 (핀 끝이 정확히 화면 중앙) ──────────
          IgnorePointer(
            child: Center(
              child: Transform.translate(
                offset: Offset(0, -24), // 48px 아이콘의 절반 위로 이동
                child: Icon(
                  Icons.location_pin,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),

          // ── 상단: 뒤로가기 + 검색창 + 드롭다운 ──────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopSearchBar(
                  controller: _searchCtrl,
                  focusNode: _searchFocus,
                  isSearching: state.isSearching,
                  onChanged: (q) {
                    setState(() => _showDropdown = q.length >= 2);
                    if (q.length >= 2) {
                      ref
                          .read(locationPickerProvider.notifier)
                          .searchPlaces(q);
                    } else {
                      ref
                          .read(locationPickerProvider.notifier)
                          .searchPlaces('');
                    }
                  },
                  onSubmit: (q) =>
                      ref.read(locationPickerProvider.notifier).searchPlaces(q),
                  onClear: () {
                    _searchCtrl.clear();
                    setState(() => _showDropdown = false);
                    ref
                        .read(locationPickerProvider.notifier)
                        .searchPlaces('');
                  },
                  onBack: () => Navigator.of(context).pop(),
                ),
                if (_showDropdown && state.searchResults.isNotEmpty)
                  _SearchDropdown(
                    results: state.searchResults,
                    onSelect: (place) {
                      _searchFocus.unfocus();
                      _searchCtrl.text = place.name;
                      setState(() => _showDropdown = false);
                      ref
                          .read(locationPickerProvider.notifier)
                          .selectPlace(place);
                      _moveCameraTo(place.lat, place.lng);
                    },
                  ),
              ],
            ),
          ),

          // ── GPS FAB ────────────────────────────────────────────
          if (state.gpsLat != null)
            Positioned(
              right: 16,
              bottom: state.hasNearby ? 244 : 156,
              child: FloatingActionButton.small(
                heroTag: 'locationPicker_gps',
                backgroundColor: Colors.white,
                elevation: 2,
                onPressed: () =>
                    _moveCameraTo(state.gpsLat!, state.gpsLng!, zoom: 16),
                child: const Icon(
                  Icons.my_location,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),

          // ── 하단 액션 카드 ─────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomCard(
              state: state,
              onSearchNearby: () => ref
                  .read(locationPickerProvider.notifier)
                  .searchNearbyPlaces(),
              onSelectPlace: (place) {
                ref.read(locationPickerProvider.notifier).selectPlace(place);
                _moveCameraTo(place.lat, place.lng);
              },
              onClearSelection: () =>
                  ref.read(locationPickerProvider.notifier).clearSelection(),
              onSave: _confirm,
            ),
          ),

          // ── 초기화 로딩 오버레이 ───────────────────────────────
          if (state.isInitializing)
            const ColoredBox(
              color: Colors.black26,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

// ── 상단 검색 바 ───────────────────────────────────────────────────────────

class _TopSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSearching;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmit;
  final VoidCallback onClear;
  final VoidCallback onBack;

  const _TopSearchBar({
    required this.controller,
    required this.focusNode,
    required this.isSearching,
    required this.onChanged,
    required this.onSubmit,
    required this.onClear,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 2,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(24),
              color: Colors.white,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: '장소 또는 주소 검색',
                  hintStyle: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  suffixIcon: isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : (controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close,
                                  size: 18,
                                  color: AppColors.textSecondary),
                              onPressed: onClear,
                            )
                          : null),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: onChanged,
                onSubmitted: onSubmit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 검색 결과 드롭다운 ─────────────────────────────────────────────────────

class _SearchDropdown extends StatelessWidget {
  final List<PlaceResult> results;
  final ValueChanged<PlaceResult> onSelect;

  const _SearchDropdown({required this.results, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 4),
          shrinkWrap: true,
          itemCount: results.length,
          separatorBuilder: (_, _) =>
              const Divider(height: 1, indent: 52),
          itemBuilder: (_, i) {
            final p = results[i];
            return ListTile(
              leading: const Icon(
                Icons.place_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              title: Text(p.name,
                  style: const TextStyle(fontSize: 14)),
              subtitle: p.address != null
                  ? Text(p.address!,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary))
                  : null,
              dense: true,
              onTap: () => onSelect(p),
            );
          },
        ),
      ),
    );
  }
}

// ── 하단 액션 카드 ─────────────────────────────────────────────────────────

class _BottomCard extends StatelessWidget {
  final LocationPickerState state;
  final VoidCallback onSearchNearby;
  final ValueChanged<PlaceResult> onSelectPlace;
  final VoidCallback onClearSelection;
  final VoidCallback onSave;

  const _BottomCard({
    required this.state,
    required this.onSearchNearby,
    required this.onSelectPlace,
    required this.onClearSelection,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const SizedBox(height: 12),

              // 주변 장소 칩 영역
              if (state.hasNearby) ...[
                _NearbyChipRow(
                  places: state.nearbyPlaces,
                  selectedPlace: state.selectedPlace,
                  onSelectPlace: onSelectPlace,
                  onClearSelection: onClearSelection,
                ),
                const SizedBox(height: 12),
              ],

              // 버튼 행
              Row(
                children: [
                  // [주변 장소 찾기] — nearby 없을 때만 표시
                  if (!state.hasNearby) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: state.isLoadingNearby
                            ? null
                            : onSearchNearby,
                        icon: state.isLoadingNearby
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Icon(Icons.store_outlined, size: 16),
                        label: const Text('주변 장소 찾기'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // [저장]
                  Expanded(
                    child: ElevatedButton(
                      onPressed: state.canSave ? onSave : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.4),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        state.selectedPlace != null
                            ? '${state.selectedPlace!.name} 저장'
                            : '위치만 저장',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 주변 장소 칩 행 ────────────────────────────────────────────────────────

class _NearbyChipRow extends StatelessWidget {
  final List<PlaceResult> places;
  final PlaceResult? selectedPlace;
  final ValueChanged<PlaceResult> onSelectPlace;
  final VoidCallback onClearSelection;

  const _NearbyChipRow({
    required this.places,
    required this.selectedPlace,
    required this.onSelectPlace,
    required this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // "위치만" 칩 — selectedPlace == null 이 기본값
          _PlaceChip(
            icon: Icons.location_on_outlined,
            name: '위치만',
            sublabel: null,
            isSelected: selectedPlace == null,
            onTap: onClearSelection,
          ),
          const SizedBox(width: 8),
          ...places.map((p) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _PlaceChip(
                  icon: _iconForCategory(p.category),
                  name: p.name,
                  sublabel: p.distance != null
                      ? '${p.distance!.round()}m'
                      : null,
                  isSelected: selectedPlace == p,
                  onTap: () => onSelectPlace(p),
                ),
              )),
        ],
      ),
    );
  }

  IconData _iconForCategory(String? category) {
    if (category == null) return Icons.place_outlined;
    if (category.contains('카페')) return Icons.coffee_outlined;
    if (category.contains('편의점')) return Icons.storefront_outlined;
    if (category.contains('음식') || category.contains('식당')) {
      return Icons.restaurant_outlined;
    }
    return Icons.place_outlined;
  }
}

// ── 개별 장소 칩 ───────────────────────────────────────────────────────────

class _PlaceChip extends StatelessWidget {
  final IconData icon;
  final String name;
  final String? sublabel;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlaceChip({
    required this.icon,
    required this.name,
    required this.sublabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 100,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (sublabel != null)
              Text(
                sublabel!,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
