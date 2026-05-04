import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/format_utils.dart';
import '../../models/expense_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import 'expense_detail_screen.dart';
import 'expense_edit_screen.dart';

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  String? _selectedCategoryId; // null = 전체

  @override
  Widget build(BuildContext context) {
    // 외부(설정)에서 카테고리 필터가 주입되면 즉시 반영
    ref.listen<String?>(selectedCategoryFilterProvider, (_, next) {
      if (next != null) {
        setState(() => _selectedCategoryId = next);
        ref.read(selectedCategoryFilterProvider.notifier).state = null;
      }
    });

    final month = ref.watch(selectedMonthProvider);
    final expenseAsync = ref.watch(expenseListProvider);
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppDateUtils.formatMonth(month)),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              ref.read(selectedMonthProvider.notifier).state =
                  DateTime(month.year, month.month - 1);
              setState(() => _selectedCategoryId = null);
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              ref.read(selectedMonthProvider.notifier).state =
                  DateTime(month.year, month.month + 1);
              setState(() => _selectedCategoryId = null);
            },
          ),
        ],
      ),
      body: expenseAsync.when(
        data: (allList) {
          final filtered = _selectedCategoryId == null
              ? allList
              : allList.where((e) => e.categoryId == _selectedCategoryId).toList();

          final expenseTotal = filtered
              .where((e) => e.paymentType == PaymentType.expense)
              .fold(0.0, (sum, e) => sum + e.amount);

          final grouped = <String, List<ExpenseModel>>{};
          for (final e in filtered) {
            grouped.putIfAbsent(AppDateUtils.formatDate(e.paymentDate), () => []).add(e);
          }
          final keys = grouped.keys.toList();

          return Column(
            children: [
              // 카테고리 필터 칩
              categoriesAsync.when(
                data: (categories) => SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    children: [
                      _FilterChip(
                        label: '전체',
                        selected: _selectedCategoryId == null,
                        onTap: () => setState(() => _selectedCategoryId = null),
                      ),
                      ...categories.map((cat) => _FilterChip(
                            label: cat.name,
                            selected: _selectedCategoryId == cat.id,
                            color: cat.color,
                            onTap: () => setState(() =>
                                _selectedCategoryId =
                                    _selectedCategoryId == cat.id ? null : cat.id),
                          )),
                    ],
                  ),
                ),
                loading: () => const SizedBox(height: 48),
                error: (_, _) => const SizedBox(height: 48),
              ),
              // 합계 바
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedCategoryId == null
                          ? '총 지출'
                          : '${categoriesAsync.valueOrNull?.firstWhere((c) => c.id == _selectedCategoryId, orElse: () => categoriesAsync.valueOrNull!.first).name} 지출',
                      style: AppTextStyles.bodySecondary,
                    ),
                    Text(FormatUtils.formatWon(expenseTotal), style: AppTextStyles.amount),
                  ],
                ),
              ),
              // 내역 리스트
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('내역이 없어요'))
                    : ListView.builder(
                        itemCount: keys.length,
                        itemBuilder: (_, i) {
                          final dateKey = keys[i];
                          final items = grouped[dateKey]!;
                          final dayTotal = items
                              .where((e) => e.paymentType == PaymentType.expense)
                              .fold(0.0, (sum, e) => sum + e.amount);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(dateKey, style: AppTextStyles.caption),
                                    Text(FormatUtils.formatWon(dayTotal),
                                        style: AppTextStyles.caption),
                                  ],
                                ),
                              ),
                              ...items.map((e) {
                                final isIncome = e.paymentType == PaymentType.income;
                                return ListTile(
                                  onTap: () => showDialog(
                                    context: context,
                                    builder: (_) => ExpenseDetailScreen(expense: e),
                                  ).then((_) => ref.invalidate(expenseListProvider)),
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primaryLight,
                                    child: Text(e.categoryName.isNotEmpty
                                        ? e.categoryName.substring(0, 1)
                                        : '?'),
                                  ),
                                  title: Text(
                                    e.storeName.isNotEmpty
                                        ? e.storeName
                                        : (e.memo.isNotEmpty ? e.memo : e.categoryName),
                                    style: AppTextStyles.body,
                                  ),
                                  subtitle:
                                      Text(e.categoryName, style: AppTextStyles.caption),
                                  trailing: Text(
                                    '${isIncome ? '+' : '-'}${FormatUtils.formatWon(e.amount)}',
                                    style: AppTextStyles.amount.copyWith(
                                      color: isIncome
                                          ? AppColors.income
                                          : AppColors.expense,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExpenseEditScreen()),
        ).then((_) => ref.invalidate(expenseListProvider)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? chipColor : Colors.transparent,
            border: Border.all(color: selected ? chipColor : AppColors.border),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
