import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_model.dart';
import '../services/expense_service.dart';
import 'auth_provider.dart';
import 'category_provider.dart';

final locationExpensesProvider = FutureProvider.autoDispose<List<ExpenseModel>>((ref) async {
  final userId = ref.watch(userIdProvider);
  final categories = await ref.watch(categoryListProvider.future);
  final catMap = {for (final c in categories) c.id: c.name};
  final expenses = await ExpenseService().fetchWithLocation(userId);
  return expenses
      .map((e) => e.copyWith(categoryName: catMap[e.categoryId] ?? ''))
      .toList();
});
