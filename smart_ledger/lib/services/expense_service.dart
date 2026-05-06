import 'package:cloud_firestore/cloud_firestore.dart';
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
    final doc = await _col.add(expense.toJson());
    return doc.id;
  }

  Future<void> update(ExpenseModel expense) async {
    await _col.doc(expense.id).update(expense.toJson());
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
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
