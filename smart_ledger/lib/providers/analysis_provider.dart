import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_model.dart';
import '../services/expense_service.dart';
import 'auth_provider.dart';
import 'category_provider.dart';
import 'expense_provider.dart';

class CategoryStat {
  final String categoryId;
  final String categoryName;
  final double total;
  final double ratio;

  const CategoryStat({
    required this.categoryId,
    required this.categoryName,
    required this.total,
    required this.ratio,
  });
}

final categoryStatsProvider = Provider.autoDispose<AsyncValue<List<CategoryStat>>>((ref) {
  return ref.watch(expenseListProvider).whenData((list) {
    final onlyExpense = list.where((e) => e.paymentType == PaymentType.expense);
    final totals = <String, double>{};
    final names = <String, String>{};

    for (final e in onlyExpense) {
      totals[e.categoryId] = (totals[e.categoryId] ?? 0) + e.amount;
      names[e.categoryId] = e.categoryName;
    }

    final grandTotal = totals.values.fold(0.0, (a, b) => a + b);
    if (grandTotal == 0) return [];

    return totals.entries.map((entry) {
      return CategoryStat(
        categoryId: entry.key,
        categoryName: names[entry.key] ?? '',
        total: entry.value,
        ratio: entry.value / grandTotal,
      );
    }).toList()
      ..sort((a, b) => b.total.compareTo(a.total));
  });
});

/// ViewMode에 따라 집계 키가 달라지는 소비 흐름 데이터
/// - year  → key = 월(1-12)
/// - month → key = 일(1-31)
/// - day   → key = 일(단일 포인트, 차트에서 미사용)
final dailyStatsProvider = Provider.autoDispose<AsyncValue<Map<int, double>>>((ref) {
  final mode = ref.watch(selectedViewModeProvider);
  return ref.watch(expenseListProvider).whenData((list) {
    final map = <int, double>{};
    for (final e in list.where((e) => e.paymentType == PaymentType.expense)) {
      final key = switch (mode) {
        ViewMode.year => e.paymentDate.month,
        ViewMode.month || ViewMode.day => e.paymentDate.day,
      };
      map[key] = (map[key] ?? 0) + e.amount;
    }
    return map;
  });
});

class CategoryDelta {
  final String categoryName;
  final double delta;

  const CategoryDelta({required this.categoryName, required this.delta});
}

/// 현재 월 대비 전월 카테고리 지출 증가분 상위 3개
final topIncreasedCategoriesProvider =
    FutureProvider.autoDispose<List<CategoryDelta>>((ref) async {
  final year = ref.watch(selectedYearProvider);
  final month = ref.watch(selectedMonthProvider);
  final userId = ref.watch(userIdProvider);
  final categories = await ref.watch(categoryListProvider.future);
  final catMap = {for (final c in categories) c.id: c.name};

  final service = ExpenseService();

  final currStart = DateTime(year, month, 1);
  final currEnd = DateTime(year, month + 1, 0, 23, 59, 59);

  // DateTime(year, 0) → 자동으로 전년도 12월로 처리됨
  final prevDate = DateTime(year, month - 1);
  final prevStart = DateTime(prevDate.year, prevDate.month, 1);
  final prevEnd = DateTime(prevDate.year, prevDate.month + 1, 0, 23, 59, 59);

  final currExpenses = await service.fetchByDateRange(currStart, currEnd, userId);
  final prevExpenses = await service.fetchByDateRange(prevStart, prevEnd, userId);

  Map<String, double> toTotals(List<ExpenseModel> expenses) {
    final map = <String, double>{};
    for (final e in expenses.where((e) => e.paymentType == PaymentType.expense)) {
      map[e.categoryId] = (map[e.categoryId] ?? 0) + e.amount;
    }
    return map;
  }

  final currTotals = toTotals(currExpenses);
  final prevTotals = toTotals(prevExpenses);

  final deltas = currTotals.entries
      .map((e) => CategoryDelta(
            categoryName: catMap[e.key] ?? '',
            delta: e.value - (prevTotals[e.key] ?? 0),
          ))
      .where((d) => d.delta > 0)
      .toList()
    ..sort((a, b) => b.delta.compareTo(a.delta));

  return deltas.take(3).toList();
});
