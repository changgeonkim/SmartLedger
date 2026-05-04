import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_model.dart';
import '../services/expense_service.dart';
import 'auth_provider.dart';
import 'category_provider.dart';

final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

// 내역 탭 카테고리 필터 — 외부(설정)에서 주입할 때 사용
final selectedCategoryFilterProvider = StateProvider<String?>((ref) => null);

final expenseListProvider = FutureProvider.autoDispose<List<ExpenseModel>>((ref) async {
  final month = ref.watch(selectedMonthProvider);
  final userId = ref.watch(userIdProvider);
  final categories = await ref.watch(categoryListProvider.future);
  final catMap = {for (final c in categories) c.id: c.name};

  final expenses = await ExpenseService().fetchByMonth(month, userId);
  return expenses
      .map((e) => e.copyWith(categoryName: catMap[e.categoryId] ?? ''))
      .toList();
});

final expenseTotalProvider = Provider.autoDispose<AsyncValue<double>>((ref) {
  return ref.watch(expenseListProvider).whenData(
        (list) => list
            .where((e) => e.paymentType == PaymentType.expense)
            .fold(0.0, (sum, e) => sum + e.amount),
      );
});

final incomeTotalProvider = Provider.autoDispose<AsyncValue<double>>((ref) {
  return ref.watch(expenseListProvider).whenData(
        (list) => list
            .where((e) => e.paymentType == PaymentType.income)
            .fold(0.0, (sum, e) => sum + e.amount),
      );
});
