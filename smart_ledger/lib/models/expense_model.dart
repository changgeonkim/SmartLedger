import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/geo_utils.dart';

enum PaymentType {
  expense('지출'),
  income('수입');

  const PaymentType(this.label);
  final String label;

  static PaymentType fromString(String s) =>
      s == '수입' ? income : expense;
}

class ExpenseModel {
  final String id;
  final String categoryId;
  final String categoryName; // 저장 안 함 — provider에서 join
  final String userId;
  final DateTime createdAt;
  final DateTime paymentDate;
  final PaymentType paymentType;
  final double amount;
  final String storeName;
  final String memo;

  // 위치 정보 (모두 nullable — 선택적 첨부)
  final double? lat;
  final double? lng;
  final String? geohash7; // ~153m, 생활권/hotspot 분석용
  final String? geohash8; // ~38m,  지도 클러스터 표시용
  final String? userSelectedPlaceName; // 사용자가 선택한 장소명 (optional)

  const ExpenseModel({
    required this.id,
    required this.categoryId,
    this.categoryName = '',
    required this.userId,
    required this.createdAt,
    required this.paymentDate,
    required this.paymentType,
    required this.amount,
    this.storeName = '',
    this.memo = '',
    this.lat,
    this.lng,
    this.geohash7,
    this.geohash8,
    this.userSelectedPlaceName,
  });

  bool get hasLocation => lat != null && lng != null;

  factory ExpenseModel.fromJson(Map<String, dynamic> json, String id) {
    final rawDate = json['paymentDate'] ?? json['date'];
    final lat = (json['lat'] as num?)?.toDouble();
    final lng = (json['lng'] as num?)?.toDouble();

    // 기존 문서에 geohash가 없는 경우 lat/lng로 재계산 (하위 호환)
    final geohash7 = json['geohash7'] as String? ??
        (lat != null && lng != null
            ? GeoUtils.encodeGeohash(lat, lng, precision: 7)
            : null);
    final geohash8 = json['geohash8'] as String? ??
        (lat != null && lng != null
            ? GeoUtils.encodeGeohash(lat, lng, precision: 8)
            : null);

    return ExpenseModel(
      id: id,
      categoryId: json['categoryId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paymentDate: rawDate is Timestamp ? rawDate.toDate() : DateTime.now(),
      paymentType: PaymentType.fromString(json['paymentType'] as String? ?? '지출'),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      storeName: json['storeName'] as String? ?? '',
      memo: json['memo'] as String? ?? '',
      lat: lat,
      lng: lng,
      geohash7: geohash7,
      geohash8: geohash8,
      userSelectedPlaceName: json['userSelectedPlaceName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'userId': userId,
        'createdAt': Timestamp.fromDate(createdAt),
        'paymentDate': Timestamp.fromDate(paymentDate),
        'paymentType': paymentType.label,
        'amount': amount,
        'storeName': storeName,
        'memo': memo,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (geohash7 != null) 'geohash7': geohash7,
        if (geohash8 != null) 'geohash8': geohash8,
        if (userSelectedPlaceName != null)
          'userSelectedPlaceName': userSelectedPlaceName,
      };

  ExpenseModel copyWith({
    String? id,
    String? categoryId,
    String? categoryName,
    String? userId,
    DateTime? createdAt,
    DateTime? paymentDate,
    PaymentType? paymentType,
    double? amount,
    String? storeName,
    String? memo,
    double? lat,
    double? lng,
    String? geohash7,
    String? geohash8,
    String? userSelectedPlaceName,
    bool clearLocation = false,
    bool clearPlaceName = false,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentType: paymentType ?? this.paymentType,
      amount: amount ?? this.amount,
      storeName: storeName ?? this.storeName,
      memo: memo ?? this.memo,
      lat: clearLocation ? null : (lat ?? this.lat),
      lng: clearLocation ? null : (lng ?? this.lng),
      geohash7: clearLocation ? null : (geohash7 ?? this.geohash7),
      geohash8: clearLocation ? null : (geohash8 ?? this.geohash8),
      userSelectedPlaceName: (clearLocation || clearPlaceName)
          ? null
          : (userSelectedPlaceName ?? this.userSelectedPlaceName),
    );
  }
}
