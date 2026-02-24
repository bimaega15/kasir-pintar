import 'package:get/get.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/pos/bindings/pos_binding.dart';
import '../modules/pos/views/pos_view.dart';
import '../modules/products/bindings/products_binding.dart';
import '../modules/products/views/products_view.dart';
import '../modules/products/views/add_edit_product_view.dart';
import '../modules/history/bindings/history_binding.dart';
import '../modules/history/views/history_view.dart';
import '../modules/history/views/transaction_detail_view.dart';
import '../modules/receipt/bindings/receipt_binding.dart';
import '../modules/receipt/views/receipt_view.dart';
import '../modules/printer/bindings/printer_binding.dart';
import '../modules/printer/views/printer_settings_view.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.pos,
      page: () => const PosView(),
      binding: PosBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.products,
      page: () => const ProductsView(),
      binding: ProductsBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.addEditProduct,
      page: () => const AddEditProductView(),
      transition: Transition.downToUp,
    ),
    GetPage(
      name: AppRoutes.history,
      page: () => const HistoryView(),
      binding: HistoryBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.transactionDetail,
      page: () => const TransactionDetailView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.receipt,
      page: () => const ReceiptView(),
      binding: ReceiptBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.printerSettings,
      page: () => const PrinterSettingsView(),
      binding: PrinterBinding(),
      transition: Transition.rightToLeft,
    ),
  ];
}
