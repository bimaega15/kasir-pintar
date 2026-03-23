import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/bahan_baku_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/bahan_baku_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../services/check_version_service.dart';
import '../../../services/notification_service.dart';
import '../../../utils/helpers/currency_helper.dart';
import '../../shift/controllers/shift_controller.dart';
import '../../../services/user_session.dart';

class HomeController extends GetxController {
  final _productRepo = Get.find<ProductRepository>();
  final _transactionRepo = Get.find<TransactionRepository>();
  final _orderRepo = Get.find<OrderRepository>();

  ShiftController get shiftCtrl => Get.find<ShiftController>();
  bool get hasActiveShift => shiftCtrl.activeShift.value != null;

  final scrollController = ScrollController();
  final isAppBarCollapsed = false.obs;

  final totalProducts = 0.obs;
  final totalTransactionsToday = 0.obs;
  final todayRevenue = 0.0.obs;
  final totalTransactions = 0.obs;
  final activeOrderCount = 0.obs;
  final greeting = ''.obs;
  final isLoading = false.obs;
  final lowStockProducts = <ProductModel>[].obs;
  final lowStockBahanBaku = <BahanBakuModel>[].obs;

  static const int lowStockThreshold = 5;

  /// Timer untuk cek stok berkala (setiap 10 menit)
  Timer? _stockCheckTimer;

  @override
  void onInit() {
    super.onInit();
    _setGreeting();
    loadStats();
    scrollController.addListener(_onScroll);

    // Cek stok berkala setiap 10 menit
    _stockCheckTimer = Timer.periodic(
      const Duration(minutes: 10),
      (_) => _checkStockLevels(),
    );
  }

  @override
  void onReady() {
    super.onReady();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = Get.context;
      if (ctx != null) CheckVersionService.checkOnce(ctx);
    });
  }

  @override
  void onClose() {
    _stockCheckTimer?.cancel();
    scrollController.dispose();
    super.onClose();
  }

  void _onScroll() {
    isAppBarCollapsed.value = scrollController.offset > 40;
  }

  Future<void> loadStats() async {
    isLoading.value = true;
    try {
      final session = Get.find<UserSession>();
      final allProducts = await _productRepo.getAll();

      final List<TransactionModel> allTx;
      if (session.isKasir) {
        final shift = shiftCtrl.activeShift.value;
        allTx = await _transactionRepo.getFiltered(
          shiftStart: shift?.openedAt,
        );
      } else {
        allTx = await _transactionRepo.getAll();
      }

      final activeOrders = await _orderRepo.getActive();

      final now = DateTime.now();
      // For kasir: all shift-filtered tx count as "today"; for admin: filter by date
      final todayTx = session.isKasir
          ? allTx
          : allTx.where((t) =>
              t.createdAt.year == now.year &&
              t.createdAt.month == now.month &&
              t.createdAt.day == now.day).toList();

      totalProducts.value = allProducts.length;
      totalTransactions.value = allTx.length;
      totalTransactionsToday.value = todayTx.length;
      todayRevenue.value = todayTx.fold(0.0, (sum, t) => sum + t.total);
      activeOrderCount.value = activeOrders.length;

      // Deteksi stok rendah produk
      final lowStock = allProducts
          .where((p) => p.stock <= lowStockThreshold)
          .toList()
        ..sort((a, b) => a.stock.compareTo(b.stock));
      lowStockProducts.assignAll(lowStock);

      // Deteksi stok rendah bahan baku
      await _loadLowStockBahanBaku();

      // Kirim push notification
      _sendStockNotifications(lowStock);
    } finally {
      isLoading.value = false;
    }
  }

  /// Cek stok bahan baku yang menipis
  Future<void> _loadLowStockBahanBaku() async {
    if (!Get.isRegistered<BahanBakuRepository>()) return;
    try {
      final repo = Get.find<BahanBakuRepository>();
      final allBahanBaku = await repo.getAll();
      final lowBB = allBahanBaku
          .where((bb) => bb.isLowStock)
          .toList()
        ..sort((a, b) => (a.stock - a.minStock).compareTo(b.stock - b.minStock));
      lowStockBahanBaku.assignAll(lowBB);
    } catch (e) {
      print('[HomeController] Error loading bahan baku: $e');
    }
  }

  /// Kirim notifikasi push untuk semua stok rendah
  void _sendStockNotifications(List<ProductModel> lowStock) {
    if (!Get.isRegistered<NotificationService>()) return;
    final notifService = Get.find<NotificationService>();

    // Notifikasi produk
    if (lowStock.isNotEmpty) {
      notifService.showLowStockNotification(lowStock);
    } else {
      notifService.cancelLowStockNotification();
    }

    // Notifikasi bahan baku
    if (lowStockBahanBaku.isNotEmpty) {
      notifService.showLowStockBahanBakuNotification(lowStockBahanBaku);
    } else {
      notifService.cancelLowStockBahanBakuNotification();
    }
  }

  /// Periodic check — hanya kirim notifikasi tanpa reload UI penuh
  Future<void> _checkStockLevels() async {
    try {
      final allProducts = await _productRepo.getAll();
      final lowStock = allProducts
          .where((p) => p.stock <= lowStockThreshold)
          .toList()
        ..sort((a, b) => a.stock.compareTo(b.stock));
      lowStockProducts.assignAll(lowStock);

      await _loadLowStockBahanBaku();

      _sendStockNotifications(lowStock);
    } catch (_) {}
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
