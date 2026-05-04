import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/ocr_service.dart';
import '../expense/expense_edit_screen.dart';

class ReceiptHandler {
  static final _picker = ImagePicker();
  static final _ocr = OcrService();

  static Future<void> fromCamera(BuildContext context) async {
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked != null) await _process(context, File(picked.path));
  }

  static Future<void> fromGallery(BuildContext context) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) await _process(context, File(picked.path));
  }

  static Future<void> _process(BuildContext context, File image) async {
    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await _ocr.recognizeReceipt(image);
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExpenseEditScreen(ocrResult: result),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OCR 처리 실패: $e')),
        );
        // OCR 실패해도 수동 입력 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExpenseEditScreen()),
        );
      }
    }
  }
}
