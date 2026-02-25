import 'package:get/get.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../utils/helpers/currency_helper.dart';
import '../../shift/controllers/shift_controller.dart';

class HomeController extends GetxController {
  final _productRepo = Get.find<ProductRepository>();
  final _transactionRepo = Get.find<TransactionRepository>();
  final _orderRepo = Get.find<OrderRepository>();

  ShiftController get shiftCtrl => Get.find<ShiftController>();
  bool get hasActiveShift => shiftCtrl.activeShift.value != null;

  final totalProducts = 0.obs;
  final totalTransactionsToday = 0.obs;
  final todayRevenue = 0.0.obs;
  final totalTransactions = 0.obs;
  final activeOrderCount = 0.obs;
  final greeting = ''.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _setGreeting();
    loadStats();
  }

  Future<void> loadStats() async {
    isLoading.value = true;
    try {
      final allProducts = await _productRepo.getAll();
      final allTx = await _transactionRepo.getAll();
      final activeOrders = await _orderRepo.getActive();

      final now = DateTime.now();
      final todayTx = allTx.where((t) =>
          t.createdAt.year == now.year &&
          t.createdAt.month == now.month &&
          t.createdAt.day == now.day).toList();

      totalProducts.value = allProducts.length;
      totalTransactions.value = allTx.length;
      totalTransactionsToday.value = todayTx.length;
      todayRevenue.value = todayTx.fold(0.0, (sum, t) => sum + t.total);
      activeOrderCount.value = activeOrders.length;
    } finally {
      isLoading.value = false;
    }
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      greeting.value = 'Selamat Pagi 🌤️';
    } else if (hour < 15) {
      greeting.value = 'Selamat Siang ☀️';
    } else if (hour < 18) {
      greeting.value = 'Selamat Sore 🌇';
    } else {
      greeting.value = 'Selamat Malam 🌙';
    }
  }

  String get formattedRevenue => CurrencyHelper.formatRupiah(todayRevenue.value);
}
