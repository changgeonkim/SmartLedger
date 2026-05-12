import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/ocr_service.dart';
import '../expense/expense_edit_screen.dart';

class ReceiptHandler {
  static final _picker = ImagePicker();
  static final _ocr = OcrService();

  static Future<void> fromCamera(BuildContext context) =>
      _pickAndProcess(context, ImageSource.camera);

  static Future<void> fromGallery(BuildContext context) =>
      _pickAndProcess(context, ImageSource.gallery);

  static Future<void> _pickAndProcess(
      BuildContext context, ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (picked == null || !context.mounted) return;
    await _process(context, File(picked.path));
  }

  static Future<void> _process(BuildContext context, File image) async {
    debugPrint('[OCR] 시작: ${image.path}');

    // 로딩 다이얼로그 표시. PopScope로 뒤로가기 차단.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    try {
      debugPrint('[OCR] recognizeReceipt 호출');
      final result = await _ocr.recognizeReceipt(image);
      debugPrint(
          '[OCR] 응답 수신: store="${result.storeName}", amount=${result.totalAmount}, items=${result.items.length}');

      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExpenseEditScreen(ocrResult: result),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('[OCR] 실패: $e');
      debugPrint('$st');
      if (!context.mounted) return;
      Navigator.pop(context); // 로딩 다이얼로그 닫기
      final messenger = ScaffoldMessenger.of(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ExpenseEditScreen()),
      );
      messenger.showSnackBar(
        SnackBar(content: Text('OCR 처리 실패: $e')),
      );
    }
  }
}
