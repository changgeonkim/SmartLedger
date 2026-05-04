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
import '../receipt/receipt_upload_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final expenseAsync = ref.watch(expenseListProvider);
    final totalAsync = ref.watch(expenseTotalProvider);
    final incomeAsync = ref.watch(incomeTotalProvider);
    final budgetsAsync = ref.watch(categoryBudgetsProvider(month));

    final totalBudget = budgetsAsync.valueOrNull
            ?.fold(0.0, (sum, b) => sum + b.amount) ??
        0.0;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _pickMonth(context, ref, month),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppDateUtils.formatMonth(month), style: AppTextStyles.heading2),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExpenseEditScreen()),
            ).then((_) => ref.invalidate(expenseListProvider)),
          ),
        ],
      ),
      body: Column(
        children: [
          _SummaryCard(totalAsync: totalAsync, incomeAsync: incomeAsync, totalBudget: totalBudget),
          Expanded(
            child: expenseAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Center(child: Text('이번 달 내역이 없어요'));
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
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          builder: (_) => const ReceiptUploadScreen(),
        ),
        icon: const Icon(Icons.document_scanner_outlined),
        label: const Text('영수증 스캔'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _pickMonth(BuildContext context, WidgetRef ref, DateTime current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) {
      ref.read(selectedMonthProvider.notifier).state =
          DateTime(picked.year, picked.month);
    }
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
                  const Text('이번 달 지출', style: TextStyle(color: Colors.white70, fontSize: 14)),
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
                  const Text('이번 달 수입', style: TextStyle(color: Colors.white70, fontSize: 14)),
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
