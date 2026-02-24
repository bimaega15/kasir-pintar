import 'package:get/get.dart';
import '../data/repositories/order_repository.dart';
import '../data/repositories/product_repository.dart';
import '../data/repositories/table_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../modules/order/controllers/order_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProductRepository>(() => ProductRepository(), fenix: true);
    Get.lazyPut<TransactionRepository>(() => TransactionRepository(),
        fenix: true);
    Get.lazyPut<TableRepository>(() => TableRepository(), fenix: true);
    Get.lazyPut<OrderRepository>(() => OrderRepository(), fenix: true);
    // Shared cart state across order flow & POS
    Get.lazyPut<OrderController>(() => OrderController(), fenix: true);
  }
}
