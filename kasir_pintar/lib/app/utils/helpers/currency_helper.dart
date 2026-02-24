import 'package:intl/intl.dart';

class CurrencyHelper {
  static final _rupiahFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final _dateFormatter = DateFormat('dd MMM yyyy', 'id_ID');
  static final _dateTimeFormatter = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  static final _timeFormatter = DateFormat('HH:mm', 'id_ID');

  static String formatRupiah(double amount) {
    return _rupiahFormatter.format(amount);
  }

  static String formatDate(DateTime date) {
    return _dateFormatter.format(date);
  }

  static String formatDateTime(DateTime date) {
    return _dateTimeFormatter.format(date);
  }

  static String formatTime(DateTime date) {
    return _timeFormatter.format(date);
  }

  static double parseRupiah(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(cleaned) ?? 0;
  }
}
