import 'package:get/get.dart';
import '../data/repositories/order_repository.dart';
import '../data/repositories/product_repository.dart';
import '../data/repositories/shift_repository.dart';
import '../data/repositories/table_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../modules/order/controllers/order_controller.dart';
import '../modules/shift/controllers/shift_controller.dart';
import '../modules/main_navigation/controllers/main_navigation_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProductRepository>(() => ProductRepository(), fenix: true);
    Get.lazyPut<TransactionRepository>(() => TransactionRepository(),
        fenix: true);
    Get.lazyPut<TableRepository>(() => TableRepository(), fenix: true);
    Get.lazyPut<OrderRepository>(() => OrderRepository(), fenix: true);
    Get.lazyPut<ShiftRepository>(() => ShiftRepository(), fenix: true);
    // Shared state across app
    Get.lazyPut<OrderController>(() => OrderController(), fenix: true);
    Get.lazyPut<ShiftController>(() => ShiftController(), fenix: true);
    // Main Navigation Controller - Always available globally
    Get.lazyPut<MainNavigationController>(
      () => MainNavigationController(),
      tag: MainNavigationController.TAG,
      fenix: true,
    );
  }
}
