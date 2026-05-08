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
    final month = ref.watch(selectedMonthDateProvider);
    final categoriesAsync = ref.watch(categoryListProvider);
    final budgetsAsync = ref.watch(categoryBudgetsProvider(month));
    final expenseAsync = ref.watch(expenseListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('예산'),
      ),
      body: categoriesAsync.when(
        data: (categories) => budgetsAsync.when(
          data: (budgets) => expenseAsync.when(
            data: (expenses) {
              final budgetMap = {for (final b in budgets) b.categoryId: b};
              final spentMap = <String, double>{};
              for (final e in expenses.where((e) => e.paymentType == PaymentType.expense)) {
                spentMap[e.categoryId] = (spentMap[e.categoryId] ?? 0) + e.amount;
              }
              final totalBudget = budgets.fold(0.0, (sum, b) => sum + b.amount);
              final totalSpent = spentMap.values.fold(0.0, (sum, s) => sum + s);

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: categories.length + 1,
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return _BudgetSummaryCard(
                      totalBudget: totalBudget,
                      totalSpent: totalSpent,
                      month: month,
                    );
                  }
                  final cat = categories[i - 1];
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
      ),
    );
  }
}

// ── 총 예산 요약 카드 ──────────────────────────────────────────────────────

class _BudgetSummaryCard extends StatelessWidget {
  final double totalBudget;
  final double totalSpent;
  final DateTime month;

  const _BudgetSummaryCard({
    required this.totalBudget,
    required this.totalSpent,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    final isPastMonth = month.year < now.year ||
        (month.year == now.year && month.month < now.month);

    final daysElapsed = isCurrentMonth
        ? now.day
        : isPastMonth
            ? daysInMonth
            : 0;

    final hasBudget = totalBudget > 0;
    final ratio = hasBudget ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;
    final remaining = totalBudget - totalSpent;
    final isOver = totalSpent > totalBudget;

    final dailyAverage = daysElapsed > 0 ? totalSpent / daysElapsed : 0.0;
    final projectedSpend = daysElapsed > 0 ? dailyAverage * daysInMonth : 0.0;
    final willExceed = hasBudget && daysElapsed > 0 && projectedSpend > totalBudget;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${month.year}년 ${month.month}월 소비 현황',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),

            // ── 총 예산 진행바 ────────────────────────────────────
            if (hasBudget) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('총 예산', style: AppTextStyles.bodySecondary),
                  Text(
                    FormatUtils.formatWon(totalBudget),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(
                    isOver ? AppColors.expense : AppColors.income,
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '사용 ${FormatUtils.formatWon(totalSpent)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.expense),
                  ),
                  Text(
                    remaining >= 0
                        ? '남은 ${FormatUtils.formatWon(remaining)}'
                        : '초과 ${FormatUtils.formatWon(remaining.abs())}',
                    style: TextStyle(
                      fontSize: 12,
                      color: remaining >= 0 ? AppColors.income : AppColors.expense,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('총 지출', style: AppTextStyles.bodySecondary),
                  Text(
                    FormatUtils.formatWon(totalSpent),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.expense,
                    ),
                  ),
                ],
              ),
            ],

            const Divider(height: 24),

            // ── 하루 평균 / 월말 예상 ────────────────────────────
            if (daysElapsed > 0) ...[
              _StatRow(
                label: '하루 평균 소비',
                value: FormatUtils.formatWon(dailyAverage.round()),
              ),
              if (isCurrentMonth) ...[
                const SizedBox(height: 6),
                _StatRow(
                  label: '현재 속도 기준 월말 예상',
                  value: FormatUtils.formatWon(projectedSpend.round()),
                  valueColor: willExceed ? AppColors.expense : null,
                ),
              ],
              const SizedBox(height: 12),
            ] else ...[
              Text(
                '아직 소비 데이터가 없습니다.',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 12),
            ],

            // ── 예산 초과 예상 여부 배지 ─────────────────────────
            if (hasBudget && daysElapsed > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: willExceed
                      ? AppColors.expense.withValues(alpha: 0.08)
                      : AppColors.income.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      willExceed
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                      size: 16,
                      color: willExceed ? AppColors.expense : AppColors.income,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage(
                          willExceed: willExceed,
                          isCurrentMonth: isCurrentMonth,
                          projectedSpend: projectedSpend,
                          totalBudget: totalBudget,
                          totalSpent: totalSpent,
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: willExceed ? AppColors.expense : AppColors.income,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusMessage({
    required bool willExceed,
    required bool isCurrentMonth,
    required double projectedSpend,
    required double totalBudget,
    required double totalSpent,
  }) {
    if (isCurrentMonth) {
      return willExceed
          ? '현재 속도 유지 시 ${FormatUtils.formatWon((projectedSpend - totalBudget).round())} 초과 예상'
          : '현재 속도 유지 시 예산 내 소비 예상';
    } else {
      return willExceed
          ? '예산을 ${FormatUtils.formatWon((totalSpent - totalBudget).round())} 초과했습니다'
          : '예산 내에서 소비를 완료했습니다';
    }
  }
}

// ── 카테고리별 예산 카드 ───────────────────────────────────────────────────

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
