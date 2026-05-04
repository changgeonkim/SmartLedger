import 'package:intl/intl.dart';

class FormatUtils {
  FormatUtils._();

  static final _won = NumberFormat('#,###', 'ko_KR');

  static String formatWon(num amount) => '${_won.format(amount.toInt())}원';

  static String formatWonCompact(num amount) {
    final a = amount.toInt();
    if (a >= 10000) {
      final man = a ~/ 10000;
      final rem = a % 10000;
      if (rem == 0) return '$man만원';
      return '$man만 ${_won.format(rem)}원';
    }
    return formatWon(a);
  }

  static int parseWon(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }
}
