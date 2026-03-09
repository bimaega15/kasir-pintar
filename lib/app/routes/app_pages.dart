import 'package:get/get.dart';
import '../data/models/void_log_model.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/main_navigation/bindings/main_navigation_binding.dart';
import '../modules/main_navigation/views/main_navigation_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/master/bindings/master_binding.dart';
import '../modules/report/bindings/report_binding.dart';
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
import '../modules/order/views/parked_orders_view.dart';
import '../modules/kitchen/bindings/kitchen_binding.dart';
import '../modules/kitchen/views/kitchen_view.dart';
import '../modules/payment/bindings/payment_binding.dart';
import '../modules/payment/views/payment_view.dart';
import '../modules/settings/bindings/settings_binding.dart';
import '../modules/settings/views/settings_view.dart';
import '../modules/shift/bindings/shift_binding.dart';
import '../modules/shift/views/open_shift_view.dart';
import '../modules/shift/views/close_shift_view.dart';
import '../modules/shift/views/shift_report_view.dart';
import '../modules/debt/views/debt_list_view.dart';
import '../modules/void_log/views/void_log_view.dart';
import '../modules/void_log/views/void_log_detail_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/login/views/setup_view.dart';
import '../modules/categories/bindings/categories_binding.dart';
import '../modules/categories/views/categories_view.dart';
import '../modules/categories/views/add_edit_category_view.dart';
import '../modules/price_levels/bindings/price_levels_binding.dart';
import '../modules/price_levels/views/price_levels_view.dart';
import '../modules/price_levels/views/add_edit_price_level_view.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    // Main Navigation Container
    GetPage(
      name: AppRoutes.main,
      page: () => const MainNavigationView(),
      binding: MainNavigationBinding(),
      bindings: [
        HomeBinding(),
        SettingsBinding(),
        MasterBinding(),
        ReportBinding(),
      ],
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
      binding: ProductsBinding(),
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
      binding: TablesBinding(),
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
    GetPage(
      name: AppRoutes.parkedOrders,
      page: () => const ParkedOrdersView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.debtList,
      page: () => const DebtListView(),
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
    // ── v3: Shift Kasir ───────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.openShift,
      page: () => const OpenShiftView(),
      binding: ShiftBinding(),
      transition: Transition.downToUp,
    ),
    GetPage(
      name: AppRoutes.closeShift,
      page: () => const CloseShiftView(),
      binding: ShiftBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.shiftReport,
      page: () => const ShiftReportView(),
      binding: ShiftBinding(),
      transition: Transition.rightToLeft,
    ),
    // ── v4: Auth ──────────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: LoginBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.setup,
      page: () => const SetupView(),
      binding: LoginBinding(),
      transition: Transition.fadeIn,
    ),
    // ── Master Kategori ───────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.categories,
      page: () => const CategoriesView(),
      binding: CategoriesBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.addEditCategory,
      page: () => const AddEditCategoryView(),
      binding: CategoriesBinding(),
      transition: Transition.downToUp,
    ),
    // ── Level Harga ───────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.priceLevels,
      page: () => const PriceLevelsView(),
      binding: PriceLevelsBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.addEditPriceLevel,
      page: () => const AddEditPriceLevelView(),
      binding: PriceLevelsBinding(),
      transition: Transition.downToUp,
    ),
    // ── v3: Void Log ──────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.voidLog,
      page: () => const VoidLogView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.voidLogDetail,
      page: () {
        final log = Get.arguments as VoidLogModel;
        return VoidLogDetailView(log: log);
      },
      transition: Transition.rightToLeft,
    ),
  ];
}
