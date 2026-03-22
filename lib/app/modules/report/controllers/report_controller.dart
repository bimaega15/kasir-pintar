import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/bahan_baku_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/providers/storage_provider.dart';
import '../../../data/repositories/bahan_baku_repository.dart';
import '../../../data/repositories/transaction_repository.dart';

class ReportController extends GetxController {
  final _transactionRepo = Get.find<TransactionRepository>();
  final _db = Get.find<DatabaseProvider>();

  final totalTransactions = 0.obs;
  final totalCancelled = 0.obs;
  final isLoading = false.obs;

  // ── Date range filter ─────────────────────────────────────────────────
  final dateRange = Rxn<DateTimeRange>();
  final selectedPeriod = 'today'.obs; // today, week, month, custom

  // ── All transactions (cached) ─────────────────────────────────────────
  final allTransactions = <TransactionModel>[].obs;

  // ── Sales report data ─────────────────────────────────────────────────
  final filteredTransactions = <TransactionModel>[].obs;
  final totalSalesAmount = 0.0.obs;
  final totalItemsSold = 0.obs;
  final avgTransactionValue = 0.0.obs;
  final productSales = <ProductSalesEntry>[].obs;
  final paymentMethodBreakdown = <PaymentMethodEntry>[].obs;

  // ── Revenue report data ───────────────────────────────────────────────
  final dailyRevenue = <DailyRevenueEntry>[].obs;
  final totalRevenue = 0.0.obs;
  final totalDiscount = 0.0.obs;
  final totalTax = 0.0.obs;
  final totalServiceCharge = 0.0.obs;
  final netRevenue = 0.0.obs;

  // ── Profit & Loss data ────────────────────────────────────────────────
  final totalCOGS = 0.0.obs; // Cost of Goods Sold (bahan baku)
  final grossProfit = 0.0.obs;
  final profitMargin = 0.0.obs;
  final bahanBakuPurchases = 0.0.obs;
  final bahanBakuUsageCost = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _setDefaultPeriod();
    loadStats();
  }

  void _setDefaultPeriod() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    dateRange.value = DateTimeRange(start: todayStart, end: todayEnd);
    selectedPeriod.value = 'today';
  }

  // ── Period Selection ──────────────────────────────────────────────────

  void setPeriod(String period) {
    final now = DateTime.now();
    selectedPeriod.value = period;

    switch (period) {
      case 'today':
        dateRange.value = DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
        break;
      case 'week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        dateRange.value = DateTimeRange(
          start: DateTime(weekStart.year, weekStart.month, weekStart.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
        break;
      case 'month':
        dateRange.value = DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
        break;
      case 'custom':
        return; // handled by date picker
    }
    _recalculate();
  }

  void setCustomRange(DateTimeRange range) {
    selectedPeriod.value = 'custom';
    dateRange.value = DateTimeRange(
      start: DateTime(range.start.year, range.start.month, range.start.day),
      end: DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59),
    );
    _recalculate();
  }

  // ── Data Loading ──────────────────────────────────────────────────────

  Future<void> loadStats() async {
    isLoading.value = true;
    try {
      allTransactions.value = await _transactionRepo.getAll();
      totalTransactions.value = allTransactions.length;

      final voidLogs = await _db.getVoidLogs();
      totalCancelled.value = voidLogs.length;

      _recalculate();
    } finally {
      isLoading.value = false;
    }
  }

  void _recalculate() {
    _filterTransactions();
    _calculateSalesReport();
    _calculateRevenueReport();
    _calculateProfitLoss();
  }

  // ── Filter Transactions by Date Range ─────────────────────────────────

  void _filterTransactions() {
    final range = dateRange.value;
    if (range == null) {
      filteredTransactions.value = allTransactions;
      return;
    }
    filteredTransactions.value = allTransactions.where((t) {
      return !t.createdAt.isBefore(range.start) &&
          !t.createdAt.isAfter(range.end);
    }).toList();
  }

  // ── Sales Report Calculations ─────────────────────────────────────────

  void _calculateSalesReport() {
    final txList = filteredTransactions;

    totalSalesAmount.value = txList.fold(0.0, (sum, t) => sum + t.total);
    totalItemsSold.value = txList.fold(0, (sum, t) => sum + t.totalItems);
    avgTransactionValue.value =
        txList.isEmpty ? 0 : totalSalesAmount.value / txList.length;

    // Product-level breakdown
    final productMap = <String, ProductSalesEntry>{};
    for (final tx in txList) {
      for (final item in tx.items) {
        final key = item.product.id;
        if (productMap.containsKey(key)) {
          productMap[key]!.quantity += item.quantity;
          productMap[key]!.totalAmount += item.subtotal;
        } else {
          productMap[key] = ProductSalesEntry(
            productName: item.product.name,
            productEmoji: item.product.emoji,
            quantity: item.quantity,
            totalAmount: item.subtotal,
            unitPrice: item.product.price,
          );
        }
      }
    }
    final sortedProducts = productMap.values.toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    productSales.assignAll(sortedProducts);

    // Payment method breakdown
    final methodMap = <String, double>{};
    for (final tx in txList) {
      methodMap[tx.paymentMethod] =
          (methodMap[tx.paymentMethod] ?? 0) + tx.total;
    }
    paymentMethodBreakdown.assignAll(
      methodMap.entries
          .map((e) => PaymentMethodEntry(method: e.key, amount: e.value))
          .toList()
        ..sort((a, b) => b.amount.compareTo(a.amount)),
    );
  }

  // ── Revenue Report Calculations ───────────────────────────────────────

  void _calculateRevenueReport() {
    final txList = filteredTransactions;

    totalRevenue.value = txList.fold(0.0, (sum, t) => sum + t.total);
    totalDiscount.value = txList.fold(0.0, (sum, t) => sum + t.discount);
    totalTax.value = txList.fold(0.0, (sum, t) => sum + t.taxAmount);
    totalServiceCharge.value =
        txList.fold(0.0, (sum, t) => sum + t.serviceChargeAmount);
    netRevenue.value =
        totalRevenue.value - totalDiscount.value;

    // Daily breakdown
    final dailyMap = <String, DailyRevenueEntry>{};
    final dayFmt = DateFormat('yyyy-MM-dd');
    for (final tx in txList) {
      final key = dayFmt.format(tx.createdAt);
      if (dailyMap.containsKey(key)) {
        dailyMap[key]!.amount += tx.total;
        dailyMap[key]!.transactionCount += 1;
      } else {
        dailyMap[key] = DailyRevenueEntry(
          date: DateTime(tx.createdAt.year, tx.createdAt.month, tx.createdAt.day),
          amount: tx.total,
          transactionCount: 1,
        );
      }
    }
    final sortedDaily = dailyMap.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    dailyRevenue.assignAll(sortedDaily);
  }

  // ── Profit & Loss Calculations ────────────────────────────────────────

  Future<void> _calculateProfitLoss() async {
    final range = dateRange.value;
    if (range == null) return;

    double purchases = 0;
    double usageCost = 0;

    if (Get.isRegistered<BahanBakuRepository>()) {
      try {
        final repo = Get.find<BahanBakuRepository>();
        final movements = await repo.getMovements(limit: 10000);

        for (final m in movements) {
          if (m.createdAt.isBefore(range.start) ||
              m.createdAt.isAfter(range.end)) {
            continue;
          }
          if (m.type == BahanBakuMovementType.purchase) {
            purchases += m.totalCost ?? 0;
          } else if (m.type == BahanBakuMovementType.usage) {
            // Estimasi biaya pemakaian: qty × harga per unit bahan baku
            // Jika totalCost tersedia, gunakan itu
            usageCost += m.totalCost ?? 0;
          }
        }
      } catch (_) {}
    }

    bahanBakuPurchases.value = purchases;
    bahanBakuUsageCost.value = usageCost;
    totalCOGS.value = purchases > 0 ? purchases : usageCost;
    grossProfit.value = totalRevenue.value - totalCOGS.value;
    profitMargin.value = totalRevenue.value > 0
        ? (grossProfit.value / totalRevenue.value) * 100
        : 0;
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  String get periodLabel {
    final range = dateRange.value;
    if (range == null) return '-';
    final fmt = DateFormat('dd MMM yyyy', 'id_ID');
    if (selectedPeriod.value == 'today') return 'Hari Ini';
    if (range.start.year == range.end.year &&
        range.start.month == range.end.month &&
        range.start.day == range.end.day) {
      return fmt.format(range.start);
    }
    return '${fmt.format(range.start)} - ${fmt.format(range.end)}';
  }
}

// ── Data classes ──────────────────────────────────────────────────────────

class ProductSalesEntry {
  final String productName;
  final String productEmoji;
  int quantity;
  double totalAmount;
  final double unitPrice;

  ProductSalesEntry({
    required this.productName,
    required this.productEmoji,
    required this.quantity,
    required this.totalAmount,
    required this.unitPrice,
  });
}

class PaymentMethodEntry {
  final String method;
  final double amount;

  PaymentMethodEntry({required this.method, required this.amount});
}

class DailyRevenueEntry {
  final DateTime date;
  double amount;
  int transactionCount;

  DailyRevenueEntry({
    required this.date,
    required this.amount,
    required this.transactionCount,
  });
}
