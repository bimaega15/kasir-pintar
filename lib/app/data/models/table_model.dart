import 'package:uuid/uuid.dart';

enum TableStatus { available, occupied, reserved }

class TableModel {
  final String id;
  int number;
  int capacity;
  TableStatus status;
  String? currentOrderId;

  TableModel({
    String? id,
    required this.number,
    this.capacity = 4,
    this.status = TableStatus.available,
    this.currentOrderId,
  }) : id = id ?? const Uuid().v4();

  String get statusLabel {
    switch (status) {
      case TableStatus.available:
        return 'Tersedia';
      case TableStatus.occupied:
        return 'Terisi';
      case TableStatus.reserved:
        return 'Reservasi';
    }
  }

  static TableStatus statusFromString(String s) {
    switch (s) {
      case 'occupied':
        return TableStatus.occupied;
      case 'reserved':
        return TableStatus.reserved;
      default:
        return TableStatus.available;
    }
  }

  static String statusToString(TableStatus s) {
    switch (s) {
      case TableStatus.occupied:
        return 'occupied';
      case TableStatus.reserved:
        return 'reserved';
      case TableStatus.available:
        return 'available';
    }
  }

  static List<TableModel> defaultTables = List.generate(
    8,
    (i) => TableModel(number: i + 1, capacity: 4),
  );
}
