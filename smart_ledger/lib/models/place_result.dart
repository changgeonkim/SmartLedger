import 'package:flutter/foundation.dart';

@immutable
class PlaceResult {
  final String name;
  final String? category;
  final String? address;
  final double lat;
  final double lng;
  final double? distance; // meters

  const PlaceResult({
    required this.name,
    this.category,
    this.address,
    required this.lat,
    required this.lng,
    this.distance,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaceResult &&
          name == other.name &&
          lat == other.lat &&
          lng == other.lng;

  @override
  int get hashCode => Object.hash(name, lat, lng);
}

@immutable
class LocationPickerResult {
  final double lat;
  final double lng;
  final String? userSelectedPlaceName; // Firestore 저장
  final String? displayAddress;        // UI 표시용만, Firestore 저장 안 함

  const LocationPickerResult({
    required this.lat,
    required this.lng,
    this.userSelectedPlaceName,
    this.displayAddress,
  });
}
