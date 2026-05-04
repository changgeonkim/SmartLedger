import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../models/expense_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import '../../services/expense_service.dart';
import '../../services/ocr_service.dart';

class ExpenseEditScreen extends ConsumerStatefulWidget {
  final ExpenseModel? existing;
  final OcrResult? ocrResult;

  const ExpenseEditScreen({super.key, this.existing, this.ocrResult});

  @override
  ConsumerState<ExpenseEditScreen> createState() => _ExpenseEditScreenState();
}

class _ExpenseEditScreenState extends ConsumerState<ExpenseEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _storeNameCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();

  DateTime _date = DateTime.now();
  String? _categoryId;
  PaymentType _paymentType = PaymentType.expense;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _amountCtrl.text = e.amount.toInt().toString();
      _storeNameCtrl.text = e.storeName;
      _memoCtrl.text = e.memo;
      _date = e.paymentDate;
      _categoryId = e.categoryId;
      _paymentType = e.paymentType;
    } else if (widget.ocrResult != null) {
      final ocr = widget.ocrResult!;
      _amountCtrl.text = ocr.totalAmount.toString();
      _storeNameCtrl.text = ocr.storeName;
      if (ocr.date != null) _date = ocr.date!;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _storeNameCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? '내역 추가' : '내역 수정'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 지출 / 수입 토글
            Row(
              children: [
                Expanded(child: _typeButton(PaymentType.expense)),
                const SizedBox(width: 8),
                Expanded(child: _typeButton(PaymentType.income)),
              ],
            ),
            const SizedBox(height: 20),
            _label('날짜'),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(),
                child: Text(AppDateUtils.formatDateFull(_date)),
              ),
            ),
            const SizedBox(height: 16),
            _label('금액'),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(suffixText: '원'),
              validator: (v) {
                if (v == null || v.isEmpty) return '금액을 입력해주세요';
                if (double.tryParse(v) == null) return '숫자만 입력해주세요';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _label('카테고리'),
            categoriesAsync.when(
              data: (categories) => DropdownButtonFormField<String>(
                initialValue: _categoryId,
                hint: const Text('카테고리 선택'),
                items: categories
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (id) => setState(() => _categoryId = id),
                validator: (v) => v == null ? '카테고리를 선택해주세요' : null,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (err, st) => const Text('카테고리 불러오기 실패'),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showAddCategoryDialog(context, ref),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('카테고리 추가', style: TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _label('상호명'),
            TextFormField(
              controller: _storeNameCtrl,
              decoration: const InputDecoration(hintText: '상호명을 입력하세요'),
            ),
            const SizedBox(height: 16),
            _label('메모'),
            TextFormField(
              controller: _memoCtrl,
              decoration: const InputDecoration(hintText: '메모를 입력하세요 (선택사항)'),
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(widget.existing == null ? '저장' : '수정'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeButton(PaymentType type) {
    final selected = _paymentType == type;
    final color = type == PaymentType.expense ? AppColors.expense : AppColors.income;
    return OutlinedButton(
      onPressed: () => setState(() => _paymentType = type),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? color : Colors.transparent,
        foregroundColor: selected ? Colors.white : AppColors.textSecondary,
        side: BorderSide(color: selected ? color : AppColors.border),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(type.label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      );

  Future<void> _showAddCategoryDialog(BuildContext context, WidgetRef ref) async {
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final userId = ref.read(userIdProvider);
    final expense = ExpenseModel(
      id: widget.existing?.id ?? '',
      categoryId: _categoryId!,
      userId: userId,
      paymentDate: _date,
      paymentType: _paymentType,
      amount: double.parse(_amountCtrl.text),
      storeName: _storeNameCtrl.text.trim(),
      memo: _memoCtrl.text.trim(),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    try {
      if (widget.existing == null) {
        await ExpenseService().add(expense);
      } else {
        await ExpenseService().update(expense);
      }
      ref.invalidate(expenseListProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('저장 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
