import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  final String id;
  final String categoryId;
  final String userId;
  final int year;
  final int month;
  final double amount;
  final DateTime updatedAt;

  const BudgetModel({
    required this.id,
    required this.categoryId,
    required this.userId,
    required this.year,
    required this.month,
    required this.amount,
    required this.updatedAt,
  });

  static String docId(String categoryId, int year, int month) =>
      '${categoryId}_${year}_${month.toString().padLeft(2, '0')}';

  factory BudgetModel.fromJson(Map<String, dynamic> json, String id) {
    return BudgetModel(
      id: id,
      categoryId: json['categoryId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      year: json['year'] as int? ?? 0,
      month: json['month'] as int? ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'userId': userId,
        'year': year,
        'month': month,
        'amount': amount,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}
