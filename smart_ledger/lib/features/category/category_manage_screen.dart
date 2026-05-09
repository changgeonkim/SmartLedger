import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/category_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/navigation_provider.dart';

class CategoryManageScreen extends ConsumerWidget {
  const CategoryManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('카테고리 관리')),
      body: categoriesAsync.when(
        data: (categories) => ListView.builder(
          itemCount: categories.length,
          itemBuilder: (_, i) {
            final cat = categories[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: cat.color.withValues(alpha: 0.15),
                child: Icon(Icons.label, color: cat.color, size: 18),
              ),
              title: Text(cat.name, style: AppTextStyles.body),
              trailing: cat.isDefault
                  ? const Chip(
                      label: Text('기본', style: TextStyle(fontSize: 11)),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    )
                  : IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.expense),
                      onPressed: () => _confirmDelete(context, ref, cat),
                    ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    int selectedColor = 0;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('카테고리 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '카테고리 이름',
                  hintText: '예: 커피, 헬스장',
                ),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('색상 선택', style: AppTextStyles.caption),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(
                  AppColors.categoryColors.length,
                  (i) => GestureDetector(
                    onTap: () => setS(() => selectedColor = i),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.categoryColors[i],
                      child: selectedColor == i
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                await ref.read(categoryNotifierProvider.notifier).add(name, selectedColor);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, CategoryModel cat) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('카테고리 삭제'),
        content: const Text(
          '이 카테고리를 삭제하면 포함된 모든 기록이 함께 삭제됩니다.\n'
          '다른 카테고리로 이동하시겠습니까, 아니면 그대로 삭제하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'move'),
            child: const Text('카테고리 이동'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'delete'),
            child: const Text('삭제', style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );

    if (result == 'delete') {
      await ref.read(categoryNotifierProvider.notifier).deleteWithExpenses(cat.id);
    } else if (result == 'move') {
      ref.read(selectedCategoryFilterProvider.notifier).state = cat.id;
      ref.read(selectedTabIndexProvider.notifier).state = 1;
      if (context.mounted) Navigator.popUntil(context, (route) => route.isFirst);
    }
  }
}
