import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget_model.dart';
import '../services/budget_service.dart';
import 'auth_provider.dart';
import 'expense_provider.dart';

final categoryBudgetsProvider =
    FutureProvider.autoDispose.family<List<BudgetModel>, DateTime>((ref, month) async {
  final userId = ref.watch(userIdProvider);
  return BudgetService().fetchByMonth(month.year, month.month, userId);
});

class BudgetNotifier extends AutoDisposeAsyncNotifier<List<BudgetModel>> {
  @override
  Future<List<BudgetModel>> build() async {
    final month = ref.watch(selectedMonthProvider);
    return ref.watch(categoryBudgetsProvider(month).future);
  }

  Future<void> save(String categoryId, double amount) async {
    final userId = ref.read(userIdProvider);
    final month = ref.read(selectedMonthProvider);
    final budget = BudgetModel(
      id: BudgetModel.docId(categoryId, month.year, month.month),
      categoryId: categoryId,
      userId: userId,
      year: month.year,
      month: month.month,
      amount: amount,
      updatedAt: DateTime.now(),
    );
    await BudgetService().save(budget);
    ref.invalidate(categoryBudgetsProvider(month));
  }

  Future<void> delete(String categoryId) async {
    final month = ref.read(selectedMonthProvider);
    await BudgetService().delete(categoryId, month.year, month.month);
    ref.invalidate(categoryBudgetsProvider(month));
  }
}

final budgetNotifierProvider =
    AsyncNotifierProvider.autoDispose<BudgetNotifier, List<BudgetModel>>(BudgetNotifier.new);
