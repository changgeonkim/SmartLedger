import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json, String id) {
    final rawDate = json['paymentDate'] ?? json['date'];
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
    );
  }
}
