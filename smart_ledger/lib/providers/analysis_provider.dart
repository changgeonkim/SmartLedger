import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_model.dart';
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

final dailyStatsProvider = Provider.autoDispose<AsyncValue<Map<int, double>>>((ref) {
  return ref.watch(expenseListProvider).whenData((list) {
    final dailyMap = <int, double>{};
    for (final e in list.where((e) => e.paymentType == PaymentType.expense)) {
      final day = e.paymentDate.day;
      dailyMap[day] = (dailyMap[day] ?? 0) + e.amount;
    }
    return dailyMap;
  });
});
