import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/geo_utils.dart';
import '../models/expense_model.dart';
import 'firebase_service.dart';

class ExpenseService {
  final _col = FirebaseService.instance.expenses;

  Future<List<ExpenseModel>> fetchByMonth(DateTime month, String userId) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    return fetchByDateRange(start, end, userId);
  }

  Future<List<ExpenseModel>> fetchByDateRange(
      DateTime start, DateTime end, String userId) async {
    final snap = await _col
        .where('paymentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('paymentDate', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('paymentDate', descending: true)
        .get();

    return snap.docs
        .map((doc) => ExpenseModel.fromJson(doc.data(), doc.id))
        .where((e) => e.userId == userId)
        .toList();
  }

  Future<String> add(ExpenseModel expense) async {
    final doc = await _col.add(_withGeohash(expense).toJson());
    return doc.id;
  }

  Future<void> update(ExpenseModel expense) async {
    await _col.doc(expense.id).update(_withGeohash(expense).toJson());
  }

  // lat/lng가 있으면 geohash를 자동 계산해 덮어씀
  // 스크린에서 직접 계산하지 않아도 저장 경로 어디서든 보장됨
  ExpenseModel _withGeohash(ExpenseModel e) {
    if (e.lat == null || e.lng == null) return e;
    return e.copyWith(
      geohash7: GeoUtils.encodeGeohash(e.lat!, e.lng!, precision: 7),
      geohash8: GeoUtils.encodeGeohash(e.lat!, e.lng!, precision: 8),
    );
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  Future<List<ExpenseModel>> fetchWithLocation(String userId) async {
    // lat > -91 로 null/미존재 문서를 서버에서 제외
    final snap = await _col
        .where('lat', isGreaterThan: -91)
        .get();
    return snap.docs
        .map((doc) => ExpenseModel.fromJson(doc.data(), doc.id))
        .where((e) => e.userId == userId)
        .toList();
  }

  Future<void> deleteByCategory(String categoryId) async {
    final snap = await _col.where('categoryId', isEqualTo: categoryId).get();
    final batch = _col.firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
