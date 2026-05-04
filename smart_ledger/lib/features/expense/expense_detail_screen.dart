import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/format_utils.dart';
import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';
import '../../services/expense_service.dart';
import 'expense_edit_screen.dart';

class ExpenseDetailScreen extends ConsumerWidget {
  final ExpenseModel expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncome = expense.paymentType == PaymentType.income;
    final amountColor = isIncome ? AppColors.income : AppColors.expense;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            child: Text(expense.categoryName.isNotEmpty
                ? expense.categoryName.substring(0, 1)
                : '?'),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(expense.categoryName),
              Text(expense.paymentType.label,
                  style: TextStyle(fontSize: 12, color: amountColor)),
            ],
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Row(
            label: '금액',
            value: FormatUtils.formatWon(expense.amount),
            valueColor: amountColor,
          ),
          _Row(label: '날짜', value: AppDateUtils.formatDateFull(expense.paymentDate)),
          if (expense.storeName.isNotEmpty)
            _Row(label: '상호명', value: expense.storeName),
          if (expense.memo.isNotEmpty) _Row(label: '메모', value: expense.memo),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _delete(context, ref),
          child: const Text('삭제', style: TextStyle(color: AppColors.expense)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ExpenseEditScreen(existing: expense),
              ),
            );
          },
          child: const Text('수정'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('이 내역을 삭제할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제', style: TextStyle(color: AppColors.expense))),
        ],
      ),
    );
    if (confirmed == true) {
      await ExpenseService().delete(expense.id);
      ref.invalidate(expenseListProvider);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _Row({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(label,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
                style: TextStyle(color: valueColor)),
          ),
        ],
      ),
    );
  }
}
