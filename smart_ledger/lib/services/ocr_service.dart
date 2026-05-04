import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';

class OcrResult {
  final String storeName;
  final int totalAmount;
  final DateTime? date;
  final List<OcrItem> items;

  const OcrResult({
    required this.storeName,
    required this.totalAmount,
    this.date,
    required this.items,
  });
}

class OcrItem {
  final String name;
  final int price;
  final int count;

  const OcrItem({required this.name, required this.price, required this.count});
}

class OcrService {
  static const _apiUrl = AppConfig.clovaOcrApiUrl;
  static const _secretKey = AppConfig.clovaOcrSecretKey;

  Future<OcrResult> recognizeReceipt(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final body = jsonEncode({
      'version': 'V2',
      'requestId': DateTime.now().millisecondsSinceEpoch.toString(),
      'timestamp': 0,
      'images': [
        {
          'format': 'jpg',
          'name': 'receipt',
          'data': base64Image,
        }
      ],
    });

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'X-OCR-SECRET': _secretKey,
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('OCR 요청 실패: ${response.statusCode}');
    }

    return _parseResponse(jsonDecode(response.body));
  }

  OcrResult _parseResponse(Map<String, dynamic> json) {
    final images = json['images'] as List<dynamic>;
    if (images.isEmpty) {
      return const OcrResult(storeName: '', totalAmount: 0, items: []);
    }

    final receipt = images.first['receipt'] as Map<String, dynamic>?;
    if (receipt == null) {
      return const OcrResult(storeName: '', totalAmount: 0, items: []);
    }

    final result = receipt['result'] as Map<String, dynamic>? ?? {};
    final storeName = _extractText(result, 'storeInfo');
    final totalAmount = _extractAmount(result, 'totalPrice');
    final date = _extractDate(result);
    final items = _extractItems(result);

    return OcrResult(
      storeName: storeName,
      totalAmount: totalAmount,
      date: date,
      items: items,
    );
  }

  String _extractText(Map<String, dynamic> result, String key) {
    try {
      final field = result[key] as Map<String, dynamic>?;
      return field?['name']?['text'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }

  int _extractAmount(Map<String, dynamic> result, String key) {
    try {
      final field = result[key] as Map<String, dynamic>?;
      final text = field?['price']?['formatted']?['value'] as String? ?? '0';
      return int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  DateTime? _extractDate(Map<String, dynamic> result) {
    try {
      final paymentInfo = result['paymentInfo'] as Map<String, dynamic>?;
      final dateText = paymentInfo?['date']?['formatted'] as Map<String, dynamic>?;
      if (dateText == null) return null;
      final year = int.tryParse(dateText['year']?.toString() ?? '');
      final month = int.tryParse(dateText['month']?.toString() ?? '');
      final day = int.tryParse(dateText['day']?.toString() ?? '');
      if (year == null || month == null || day == null) return null;
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  List<OcrItem> _extractItems(Map<String, dynamic> result) {
    try {
      final subResults = result['subResults'] as List<dynamic>? ?? [];
      final items = <OcrItem>[];
      for (final sub in subResults) {
        final itemList = (sub as Map<String, dynamic>)['items'] as List<dynamic>? ?? [];
        for (final item in itemList) {
          final m = item as Map<String, dynamic>;
          final name = m['name']?['text'] as String? ?? '';
          final price = int.tryParse(
                  m['price']?['price']?['formatted']?['value']
                          ?.toString()
                          .replaceAll(RegExp(r'[^0-9]'), '') ??
                      '0') ??
              0;
          final count = int.tryParse(m['count']?['text']?.toString() ?? '1') ?? 1;
          items.add(OcrItem(name: name, price: price, count: count));
        }
      }
      return items;
    } catch (_) {
      return [];
    }
  }
}
