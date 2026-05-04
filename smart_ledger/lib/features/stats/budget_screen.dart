import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/format_utils.dart';
import '../../models/budget_model.dart';
import '../../models/expense_model.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final categoriesAsync = ref.watch(categoryListProvider);
    final budgetsAsync = ref.watch(categoryBudgetsProvider(month));
    final expenseAsync = ref.watch(expenseListProvider);

    return categoriesAsync.when(
      data: (categories) => budgetsAsync.when(
        data: (budgets) => expenseAsync.when(
          data: (expenses) {
            final budgetMap = {for (final b in budgets) b.categoryId: b};
            final spentMap = <String, double>{};
            for (final e in expenses.where((e) => e.paymentType == PaymentType.expense)) {
              spentMap[e.categoryId] = (spentMap[e.categoryId] ?? 0) + e.amount;
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              itemBuilder: (_, i) {
                final cat = categories[i];
                final budget = budgetMap[cat.id];
                final spent = spentMap[cat.id] ?? 0;
                return _BudgetCard(
                  categoryId: cat.id,
                  categoryName: cat.name,
                  budget: budget,
                  spent: spent,
                  onSave: (amount) => ref
                      .read(budgetNotifierProvider.notifier)
                      .save(cat.id, amount),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('오류: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final String categoryId;
  final String categoryName;
  final BudgetModel? budget;
  final double spent;
  final Future<void> Function(double) onSave;

  const _BudgetCard({
    required this.categoryId,
    required this.categoryName,
    required this.budget,
    required this.spent,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final hasBudget = budget != null && budget!.amount > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: hasBudget ? _withBudget(context) : _noBudget(context),
      ),
    );
  }

  Widget _withBudget(BuildContext context) {
    final amount = budget!.amount;
    final remaining = amount - spent;
    final ratio = (spent / amount).clamp(0.0, 1.0);
    final over = spent > amount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(categoryName, style: AppTextStyles.body),
            TextButton(
              onPressed: () => _showDialog(context),
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: const Text('수정', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _StatRow(label: '예산', value: FormatUtils.formatWon(amount)),
        _StatRow(
          label: '사용',
          value: FormatUtils.formatWon(spent),
          valueColor: AppColors.expense,
        ),
        _StatRow(
          label: '남은 금액',
          value: FormatUtils.formatWon(remaining.abs()),
          valueColor: over ? AppColors.expense : AppColors.income,
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(over ? AppColors.expense : AppColors.income),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${(ratio * 100).toStringAsFixed(1)}%',
            style: AppTextStyles.caption,
          ),
        ),
      ],
    );
  }

  Widget _noBudget(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(categoryName, style: AppTextStyles.body),
            const SizedBox(height: 2),
            const Text('예산이 설정되지 않았습니다', style: AppTextStyles.caption),
          ],
        ),
        ElevatedButton(
          onPressed: () => _showDialog(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('설정하기'),
        ),
      ],
    );
  }

  Future<void> _showDialog(BuildContext context) async {
    final ctrl = TextEditingController(
      text: budget != null && budget!.amount > 0
          ? budget!.amount.toInt().toString()
          : '',
    );
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$categoryName 예산 설정'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '예산 금액', suffixText: '원'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(ctrl.text) ?? 0;
              if (amount > 0) await onSave(amount);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySecondary),
          Text(value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              )),
        ],
      ),
    );
  }
}
