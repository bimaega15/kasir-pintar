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
// v2 modules
import '../modules/tables/bindings/tables_binding.dart';
import '../modules/tables/views/tables_view.dart';
import '../modules/tables/views/add_edit_table_view.dart';
import '../modules/order/bindings/order_binding.dart';
import '../modules/order/views/order_type_view.dart';
import '../modules/order/views/table_select_view.dart';
import '../modules/order/views/order_confirm_view.dart';
import '../modules/order/views/active_orders_view.dart';
import '../modules/kitchen/bindings/kitchen_binding.dart';
import '../modules/kitchen/views/kitchen_view.dart';
import '../modules/payment/bindings/payment_binding.dart';
import '../modules/payment/views/payment_view.dart';
import '../modules/settings/bindings/settings_binding.dart';
import '../modules/settings/views/settings_view.dart';
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
    // ── v2: Tables ────────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.tables,
      page: () => const TablesView(),
      binding: TablesBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.addEditTable,
      page: () => const AddEditTableView(),
      transition: Transition.downToUp,
    ),
    // ── v2: Order flow ────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.orderType,
      page: () => const OrderTypeView(),
      binding: OrderBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.tableSelect,
      page: () => const TableSelectView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.orderConfirm,
      page: () => const OrderConfirmView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.activeOrders,
      page: () => const ActiveOrdersView(),
      transition: Transition.rightToLeft,
    ),
    // ── v2: Kitchen ───────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.kitchen,
      page: () => const KitchenView(),
      binding: KitchenBinding(),
      transition: Transition.rightToLeft,
    ),
    // ── v2: Payment ───────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.payment,
      page: () => const PaymentView(),
      binding: PaymentBinding(),
      transition: Transition.rightToLeft,
    ),
    // ── v2: Settings ──────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.appSettings,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
      transition: Transition.rightToLeft,
    ),
  ];
}
