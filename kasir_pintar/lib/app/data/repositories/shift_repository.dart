import 'package:get/get.dart';
import '../models/shift_model.dart';
import '../providers/storage_provider.dart';

class ShiftRepository {
  final DatabaseProvider _db = Get.find<DatabaseProvider>();

  Future<ShiftModel?> getActive() => _db.getActiveShift();

  Future<void> open(ShiftModel shift) => _db.insertShift(shift);

  Future<void> close(
    String id,
    double closingBalance,
    double expectedCash,
    String notes,
  ) =>
      _db.updateShiftClose(id, closingBalance, expectedCash, notes);

  Future<List<ShiftModel>> getAll() => _db.getShifts();

  Future<double> getTunaiRevenueSince(DateTime since) =>
      _db.getTunaiRevenueSince(since);
}
