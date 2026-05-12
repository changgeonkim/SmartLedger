import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
  static final _apiUrl = AppConfig.clovaOcrApiUrl;
  static final _secretKey = AppConfig.clovaOcrSecretKey;

  Future<OcrResult> recognizeReceipt(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    debugPrint('[OCR] 이미지 읽음: ${bytes.length} bytes');

    // image_picker가 imageQuality<100일 때 JPEG로 변환하므로 'jpg' 고정
    final body = await compute(
      _buildRequestBody,
      _OcrRequestParams(bytes: bytes, format: 'jpg'),
    );
    debugPrint('[OCR] 요청 본문 생성 완료: ${body.length} chars');
    debugPrint('[OCR] POST → $_apiUrl');

    final response = await http
        .post(
          Uri.parse(_apiUrl),
          headers: {
            'Content-Type': 'application/json',
            'X-OCR-SECRET': _secretKey,
          },
          body: body,
        )
        .timeout(const Duration(seconds: 30));
    debugPrint('[OCR] 응답 코드: ${response.statusCode}');

    if (response.statusCode != 200) {
      throw Exception(
        'OCR 요청 실패: ${response.statusCode} - ${response.body}',
      );
    }

    final decoded = await compute(_decodeJson, response.body);
    return _parseResponse(decoded);
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

  // text 우선, 없으면 formatted.value fallback
  String _readText(Map<String, dynamic>? node) {
    if (node == null) return '';
    final text = node['text'];
    if (text is String && text.isNotEmpty) return text;
    final formatted = node['formatted'];
    if (formatted is Map<String, dynamic>) {
      final value = formatted['value'];
      if (value is String) return value;
    }
    return '';
  }

  String _extractText(Map<String, dynamic> result, String key) {
    try {
      final field = result[key] as Map<String, dynamic>?;
      return _readText(field?['name'] as Map<String, dynamic>?);
    } catch (_) {
      return '';
    }
  }

  int _extractAmount(Map<String, dynamic> result, String key) {
    try {
      final field = result[key] as Map<String, dynamic>?;
      final text = _readText(field?['price'] as Map<String, dynamic>?);
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
        final itemList =
            (sub as Map<String, dynamic>)['items'] as List<dynamic>? ?? [];
        for (final item in itemList) {
          final m = item as Map<String, dynamic>;
          final name = _readText(m['name'] as Map<String, dynamic>?);

          // price.price.{text|formatted.value} 또는 price.{text|formatted.value}
          // 두 구조를 모두 허용
          final priceNode = m['price'] as Map<String, dynamic>?;
          var priceText = '';
          if (priceNode != null) {
            final inner = priceNode['price'];
            if (inner is Map<String, dynamic>) {
              priceText = _readText(inner);
            }
            if (priceText.isEmpty) {
              priceText = _readText(priceNode);
            }
          }
          final price = int.tryParse(
                  priceText.replaceAll(RegExp(r'[^0-9]'), '')) ??
              0;

          final count =
              int.tryParse(_readText(m['count'] as Map<String, dynamic>?)) ??
                  1;
          items.add(OcrItem(name: name, price: price, count: count));
        }
      }
      return items;
    } catch (_) {
      return [];
    }
  }
}

class _OcrRequestParams {
  final Uint8List bytes;
  final String format;
  const _OcrRequestParams({required this.bytes, required this.format});
}

Map<String, dynamic> _decodeJson(String body) =>
    jsonDecode(body) as Map<String, dynamic>;

String _buildRequestBody(_OcrRequestParams p) {
  return jsonEncode({
    'version': 'V2',
    'requestId': DateTime.now().millisecondsSinceEpoch.toString(),
    'timestamp': DateTime.now().millisecondsSinceEpoch,
    'images': [
      {
        'format': p.format,
        'name': 'receipt',
        'data': base64Encode(p.bytes),
      }
    ],
  });
}
