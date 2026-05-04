import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../services/expense_service.dart';
import '../services/firebase_service.dart';
import 'auth_provider.dart';
import 'expense_provider.dart';

final categoryListProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final userId = ref.watch(userIdProvider);
  final col = FirebaseService.instance.categories;

  var snap = await col.where('userId', isEqualTo: userId).get();

  if (snap.docs.isEmpty) {
    final now = DateTime.now();
    final batch = FirebaseFirestore.instance.batch();
    for (final cat in CategoryModel.getDefaults(userId, now)) {
      batch.set(col.doc(), cat.toJson());
    }
    await batch.commit();
    snap = await col.where('userId', isEqualTo: userId).get();
  }

  final list = snap.docs
      .map((doc) => CategoryModel.fromJson(doc.data(), doc.id))
      .toList()
    ..sort((a, b) => a.order.compareTo(b.order));
  return list;
});

class CategoryNotifier extends AsyncNotifier<List<CategoryModel>> {
  @override
  Future<List<CategoryModel>> build() async {
    return ref.watch(categoryListProvider.future);
  }

  Future<void> add(String name, int colorIndex) async {
    final userId = ref.read(userIdProvider);
    final current = state.valueOrNull ?? [];
    final now = DateTime.now();
    final doc = FirebaseService.instance.categories.doc();
    final category = CategoryModel(
      id: doc.id,
      userId: userId,
      name: name,
      isDefault: false,
      colorIndex: colorIndex,
      order: current.length,
      createdAt: now,
      updatedAt: now,
    );
    await doc.set(category.toJson());
    ref.invalidate(categoryListProvider);
  }

  Future<void> delete(String id) async {
    await FirebaseService.instance.categories.doc(id).delete();
    ref.invalidate(categoryListProvider);
  }

  Future<void> deleteWithExpenses(String id) async {
    await ExpenseService().deleteByCategory(id);
    await FirebaseService.instance.categories.doc(id).delete();
    ref.invalidate(categoryListProvider);
    ref.invalidate(expenseListProvider);
  }
}

final categoryNotifierProvider =
    AsyncNotifierProvider<CategoryNotifier, List<CategoryModel>>(CategoryNotifier.new);
