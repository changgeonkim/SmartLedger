import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/format_utils.dart';
import '../../core/utils/date_utils.dart';
import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';
import '../../providers/budget_provider.dart';
import '../expense/expense_edit_screen.dart';
import '../expense/expense_detail_screen.dart';
import '../receipt/receipt_handler.dart';
import '../receipt/receipt_upload_screen.dart';
import '../settings/settings_screen.dart';
import '../../core/widgets/animated_content_switcher.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(selectedYearProvider);
    final month = ref.watch(selectedMonthProvider);
    final day = ref.watch(selectedDateProvider);
    final mode = ref.watch(selectedViewModeProvider);
    final expenseAsync = ref.watch(expenseListProvider);
    final totalAsync = ref.watch(expenseTotalProvider);
    final incomeAsync = ref.watch(incomeTotalProvider);
    final budgetsAsync = ref.watch(categoryBudgetsProvider(ref.watch(selectedMonthDateProvider)));

    final totalBudget = budgetsAsync.valueOrNull
            ?.fold(0.0, (sum, b) => sum + b.amount) ??
        0.0;

    final viewKey = switch (mode) {
      ViewMode.year => 'y_$year',
      ViewMode.month => 'm_${year}_$month',
      ViewMode.day => 'd_${year}_${month}_$day',
    };

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _pickDate(context, ref, year, month, day),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_formatDateLabel(year, month, day, mode), style: AppTextStyles.heading2),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const _ViewModeToggle(),
          _SummaryCard(totalAsync: totalAsync, incomeAsync: incomeAsync, totalBudget: totalBudget),
          Expanded(
            child: AnimatedContentSwitcher(
              viewKey: viewKey,
              child: expenseAsync.when(
                data: (list) {
                  if (list.isEmpty) {
                    return const Center(child: Text('해당 기간 내역이 없어요'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _ExpenseItem(
                      expense: list[i],
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => ExpenseDetailScreen(expense: list[i]),
                      ).then((_) => ref.invalidate(expenseListProvider)),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('오류: $e')),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_fab',
        onPressed: () => showModalBottomSheet(
          context: context,
          builder: (_) => ReceiptUploadScreen(
            onCamera: () => ReceiptHandler.fromCamera(context),
            onGallery: () => ReceiptHandler.fromGallery(context),
            onManualEntry: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExpenseEditScreen()),
            ).then((_) => ref.invalidate(expenseListProvider)),
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDateLabel(int year, int month, int day, ViewMode mode) {
    return switch (mode) {
      ViewMode.year => '$year년',
      ViewMode.month => '$year년 ${month.toString().padLeft(2, '0')}월',
      ViewMode.day =>
        '$year년 ${month.toString().padLeft(2, '0')}월 ${day.toString().padLeft(2, '0')}일',
    };
  }

  Future<void> _pickDate(
      BuildContext context, WidgetRef ref, int year, int month, int day) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(year, month, day),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked == null) return;

    ref.read(selectedYearProvider.notifier).state = picked.year;
    ref.read(selectedMonthProvider.notifier).state = picked.month;
    ref.read(selectedDateProvider.notifier).state = picked.day;
  }
}

class _ViewModeToggle extends ConsumerWidget {
  const _ViewModeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(selectedViewModeProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: ViewMode.values.map((m) {
          final label = switch (m) {
            ViewMode.year => '연도별',
            ViewMode.month => '월별',
            ViewMode.day => '일별',
          };
          final selected = mode == m;
          return Expanded(
            child: GestureDetector(
              onTap: () => ref.read(selectedViewModeProvider.notifier).state = m,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final AsyncValue<double> totalAsync;
  final AsyncValue<double> incomeAsync;
  final double totalBudget;

  const _SummaryCard({
    required this.totalAsync,
    required this.incomeAsync,
    required this.totalBudget,
  });

  @override
  Widget build(BuildContext context) {
    final total = totalAsync.valueOrNull ?? 0.0;
    final income = incomeAsync.valueOrNull ?? 0.0;
    final ratio = totalBudget > 0 ? (total / totalBudget).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('지출', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    FormatUtils.formatWon(total),
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('수입', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    FormatUtils.formatWon(income),
                    style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          if (totalBudget > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation(
                  ratio >= 1.0 ? AppColors.expense : Colors.white,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '예산 ${FormatUtils.formatWon(totalBudget)} 중 ${(ratio * 100).toStringAsFixed(0)}% 사용',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExpenseItem extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback onTap;

  const _ExpenseItem({required this.expense, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isIncome = expense.paymentType == PaymentType.income;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryLight,
        child: Text(expense.categoryName.isNotEmpty
            ? expense.categoryName.substring(0, 1)
            : '?'),
      ),
      title: Text(
        expense.storeName.isNotEmpty
            ? expense.storeName
            : (expense.memo.isNotEmpty ? expense.memo : expense.categoryName),
        style: AppTextStyles.body,
      ),
      subtitle: Text(AppDateUtils.formatDate(expense.paymentDate), style: AppTextStyles.caption),
      trailing: Text(
        '${isIncome ? '+' : ''}${FormatUtils.formatWon(expense.amount)}',
        style: AppTextStyles.amount.copyWith(
          color: isIncome ? AppColors.income : AppColors.expense,
        ),
      ),
    );
  }
}
