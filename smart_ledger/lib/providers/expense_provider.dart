import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_model.dart';
import '../services/expense_service.dart';
import 'auth_provider.dart';
import 'category_provider.dart';

enum ViewMode { year, month, day }

// --- 날짜 선택 상태 ---
final selectedYearProvider = StateProvider<int>((ref) => DateTime.now().year);
final selectedMonthProvider = StateProvider<int>((ref) => DateTime.now().month);
final selectedDateProvider = StateProvider<int>((ref) => DateTime.now().day);
final selectedViewModeProvider = StateProvider<ViewMode>((ref) => ViewMode.month);

// 브릿지 Provider (budget / expense_list 호환용)
final selectedMonthDateProvider = Provider<DateTime>((ref) {
  return DateTime(
    ref.watch(selectedYearProvider),
    ref.watch(selectedMonthProvider),
  );
});

// 내역 탭 카테고리 필터 — 외부(설정)에서 주입할 때 사용
final selectedCategoryFilterProvider = StateProvider<String?>((ref) => null);

/// ViewMode에 따라 Firestore 쿼리 범위(start, end)를 반환
(DateTime, DateTime) buildDateRange(int year, int month, int day, ViewMode mode) {
  return switch (mode) {
    ViewMode.year => (DateTime(year, 1, 1), DateTime(year, 12, 31, 23, 59, 59)),
    ViewMode.month => (DateTime(year, month, 1), DateTime(year, month + 1, 0, 23, 59, 59)),
    ViewMode.day => (DateTime(year, month, day), DateTime(year, month, day, 23, 59, 59)),
  };
}

final expenseListProvider = FutureProvider.autoDispose<List<ExpenseModel>>((ref) async {
  final year = ref.watch(selectedYearProvider);
  final month = ref.watch(selectedMonthProvider);
  final day = ref.watch(selectedDateProvider);
  final mode = ref.watch(selectedViewModeProvider);
  final userId = ref.watch(userIdProvider);
  final categories = await ref.watch(categoryListProvider.future);
  final catMap = {for (final c in categories) c.id: c.name};

  final (start, end) = buildDateRange(year, month, day, mode);
  final expenses = await ExpenseService().fetchByDateRange(start, end, userId);
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
