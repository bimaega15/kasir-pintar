/// Helper untuk memformat struk untuk printer thermal (80mm)
///
/// Format thermal printer standar:
/// - 80mm width = ~32 karakter per baris (monospace)
/// - 58mm width = ~24 karakter per baris
///
/// Penggunaan:
/// ```dart
/// final formatter = ThermalReceiptFormatter(paperWidth: PaperWidth.mm80);
/// final lines = formatter.generateReceipt(transaction);
/// ```

enum PaperWidth {
  mm58(24), // Thermal 58mm
  mm80(32); // Thermal 80mm (default)

  final int charPerLine;
  const PaperWidth(this.charPerLine);
}

class ThermalReceiptFormatter {
  final PaperWidth paperWidth;

  ThermalReceiptFormatter({this.paperWidth = PaperWidth.mm80});

  int get maxChar => paperWidth.charPerLine;

  /// Membuat garis separator
  String line({String char = '='}) => char * maxChar;

  /// Center text dengan padding
  String center(String text) {
    if (text.length >= maxChar) return text.substring(0, maxChar);
    final padding = (maxChar - text.length) ~/ 2;
    return ' ' * padding + text;
  }

  /// Left-right alignment untuk 2 kolom
  String leftRight(String left, String right) {
    if (left.length + right.length >= maxChar) {
      return left
              .substring(0, maxChar - right.length - 1)
              .padRight(maxChar - right.length) +
          right;
    }
    final space = maxChar - left.length - right.length;
    return left + (' ' * space) + right;
  }

  /// Format item dengan quantity dan harga
  String itemRow(String name, int qty, String price, String subtotal) {
    final qtyPrice = '$qty x $price';
    final line1 = leftRight(name, subtotal);
    final line2 = '  $qtyPrice';
    return '$line1\n$line2';
  }

  /// Wrap text untuk multi-line
  List<String> wrapText(String text, {int width = 0}) {
    final w = width > 0 ? width : maxChar;
    if (text.length <= w) return [text];

    final lines = <String>[];
    var remaining = text;

    while (remaining.length > w) {
      lines.add(remaining.substring(0, w));
      remaining = remaining.substring(w);
    }
    if (remaining.isNotEmpty) lines.add(remaining);

    return lines;
  }
}
