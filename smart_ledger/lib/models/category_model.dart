import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class CategoryModel {
  final String id;
  final String userId;
  final String name;
  final bool isDefault;
  final int colorIndex;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CategoryModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.isDefault,
    required this.colorIndex,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  Color get color => AppColors.categoryColors[colorIndex % AppColors.categoryColors.length];

  factory CategoryModel.fromJson(Map<String, dynamic> json, String id) {
    final now = DateTime.now();
    return CategoryModel(
      id: id,
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      isDefault: json['isDefault'] as bool? ?? false,
      colorIndex: json['colorIndex'] as int? ?? 0,
      order: json['order'] as int? ?? 0,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? now,
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? now,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'name': name,
        'isDefault': isDefault,
        'colorIndex': colorIndex,
        'order': order,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  CategoryModel copyWith({
    String? id,
    String? userId,
    String? name,
    bool? isDefault,
    int? colorIndex,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      colorIndex: colorIndex ?? this.colorIndex,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static List<CategoryModel> getDefaults(String userId, DateTime now) => [
        CategoryModel(id: '', userId: userId, name: '식비', isDefault: true, colorIndex: 0, order: 0, createdAt: now, updatedAt: now),
        CategoryModel(id: '', userId: userId, name: '교통', isDefault: true, colorIndex: 1, order: 1, createdAt: now, updatedAt: now),
        CategoryModel(id: '', userId: userId, name: '쇼핑', isDefault: true, colorIndex: 2, order: 2, createdAt: now, updatedAt: now),
        CategoryModel(id: '', userId: userId, name: '의료', isDefault: true, colorIndex: 3, order: 3, createdAt: now, updatedAt: now),
        CategoryModel(id: '', userId: userId, name: '문화', isDefault: true, colorIndex: 4, order: 4, createdAt: now, updatedAt: now),
        CategoryModel(id: '', userId: userId, name: '급여', isDefault: true, colorIndex: 5, order: 5, createdAt: now, updatedAt: now),
        CategoryModel(id: '', userId: userId, name: '기타', isDefault: true, colorIndex: 6, order: 6, createdAt: now, updatedAt: now),
      ];
}
