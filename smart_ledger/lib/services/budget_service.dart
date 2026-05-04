import '../models/budget_model.dart';
import 'firebase_service.dart';

class BudgetService {
  final _col = FirebaseService.instance.budgets;

  Future<List<BudgetModel>> fetchByMonth(int year, int month, String userId) async {
    final snap = await _col.where('userId', isEqualTo: userId).get();
    return snap.docs
        .map((doc) => BudgetModel.fromJson(doc.data(), doc.id))
        .where((b) => b.year == year && b.month == month)
        .toList();
  }

  Future<void> save(BudgetModel budget) async {
    final id = BudgetModel.docId(budget.categoryId, budget.year, budget.month);
    await _col.doc(id).set(budget.toJson());
  }

  Future<void> delete(String categoryId, int year, int month) async {
    final id = BudgetModel.docId(categoryId, year, month);
    await _col.doc(id).delete();
  }
}
