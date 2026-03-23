import 'package:get/get.dart';
import '../../../data/providers/storage_provider.dart';
import '../../../services/printer_service.dart';

class QueueController extends GetxController {
  static const _queueNumberKey = 'queue_current_number';
  static const _queueDateKey = 'queue_last_reset_date';

  final currentNumber = 0.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadAndCheckReset();
  }

  Future<void> _loadAndCheckReset() async {
    isLoading.value = true;
    try {
      final db = Get.find<DatabaseProvider>();
      final savedDate = await db.getSetting(_queueDateKey);
      final todayStr = _todayString();

      if (savedDate != todayStr) {
        // Hari baru — reset otomatis
        await db.setSetting(_queueNumberKey, '0');
        await db.setSetting(_queueDateKey, todayStr);
        currentNumber.value = 0;
      } else {
        final saved = await db.getSetting(_queueNumberKey);
        currentNumber.value = int.tryParse(saved ?? '0') ?? 0;
      }
    } finally {
      isLoading.value = false;
    }
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> nextAndPrint() async {
    isLoading.value = true;
    try {
      final db = Get.find<DatabaseProvider>();
      final newNumber = currentNumber.value + 1;
      await db.setSetting(_queueNumberKey, newNumber.toString());
      await db.setSetting(_queueDateKey, _todayString());
      currentNumber.value = newNumber;

      final printerService = Get.find<PrinterService>();
      await printerService.printQueueNumber(newNumber);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetQueue() async {
    final db = Get.find<DatabaseProvider>();
    await db.setSetting(_queueNumberKey, '0');
    await db.setSetting(_queueDateKey, _todayString());
    currentNumber.value = 0;
    Get.snackbar(
      'Reset Berhasil',
      'Nomor antrian di-reset ke 0',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
