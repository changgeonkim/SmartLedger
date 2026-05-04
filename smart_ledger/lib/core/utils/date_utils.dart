import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static String formatDate(DateTime date) =>
      DateFormat('yyyy.MM.dd').format(date);

  static String formatDateFull(DateTime date) =>
      DateFormat('yyyy년 MM월 dd일').format(date);

  static String formatMonth(DateTime date) =>
      DateFormat('yyyy년 MM월').format(date);

  static String formatDayOfWeek(DateTime date) =>
      DateFormat('E', 'ko_KR').format(date);

  static DateTime startOfMonth(DateTime date) =>
      DateTime(date.year, date.month, 1);

  static DateTime endOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0, 23, 59, 59);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;
}
