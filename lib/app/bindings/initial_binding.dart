import 'package:get/get.dart';
import '../services/user_session.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/customer_repository.dart';
import '../data/repositories/price_level_repository.dart';
import '../data/repositories/bahan_baku_repository.dart';
import '../data/repositories/debt_repository.dart';
import '../data/repositories/expense_repository.dart';
import '../data/repositories/employee_repository.dart';
import '../data/repositories/attendance_repository.dart';
import '../data/repositories/order_repository.dart';
import '../data/repositories/product_repository.dart';
import '../data/repositories/shift_repository.dart';
import '../data/repositories/stock_repository.dart';
import '../data/repositories/table_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../modules/debt/controllers/debt_controller.dart';
import '../modules/order/controllers/order_controller.dart';
import '../modules/shift/controllers/shift_controller.dart';
import '../modules/main_navigation/controllers/main_navigation_controller.dart';
import '../modules/home/controllers/home_controller.dart';
import '../modules/kitchen/controllers/kitchen_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserSession>(() => UserSession(), fenix: true);
    Get.lazyPut<CategoryRepository>(() => CategoryRepository(), fenix: true);
    Get.lazyPut<CustomerRepository>(() => CustomerRepository(), fenix: true);
    Get.lazyPut<PriceLevelRepository>(() => PriceLevelRepository(), fenix: true);
    Get.lazyPut<ProductRepository>(() => ProductRepository(), fenix: true);
    Get.lazyPut<TransactionRepository>(() => TransactionRepository(),
        fenix: true);
    Get.lazyPut<TableRepository>(() => TableRepository(), fenix: true);
    Get.lazyPut<OrderRepository>(() => OrderRepository(), fenix: true);
    Get.lazyPut<ShiftRepository>(() => ShiftRepository(), fenix: true);
    Get.lazyPut<StockRepository>(() => StockRepository(), fenix: true);
    Get.lazyPut<BahanBakuRepository>(() => BahanBakuRepository(), fenix: true);
    Get.lazyPut<DebtRepository>(() => DebtRepository(), fenix: true);
    Get.lazyPut<ExpenseRepository>(() => ExpenseRepository(), fenix: true);
    Get.lazyPut<EmployeeRepository>(() => EmployeeRepository(), fenix: true);
    Get.lazyPut<AttendanceRepository>(() => AttendanceRepository(), fenix: true);
    // Shared state across app
    Get.lazyPut<OrderController>(() => OrderController(), fenix: true);
    Get.lazyPut<ShiftController>(() => ShiftController(), fenix: true);
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
    Get.lazyPut<KitchenController>(() => KitchenController(), fenix: true);
    Get.lazyPut<DebtController>(() => DebtController(), fenix: true);
    // Main Navigation Controller - Always available globally
    Get.lazyPut<MainNavigationController>(
      () => MainNavigationController(),
      tag: MainNavigationController.TAG,
      fenix: true,
    );
  }
}
