import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/order_item_model.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/table_model.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/table_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/helpers/currency_helper.dart';

class OrderController extends GetxController {
  final _orderRepo = Get.find<OrderRepository>();
  final _tableRepo = Get.find<TableRepository>();
  final _productRepo = Get.find<ProductRepository>();
  final _transactionRepo = Get.find<TransactionRepository>();
  final _categoryRepo = Get.find<CategoryRepository>();

  // ── Active order state ────────────────────────────────────────────────────
  final orderType = OrderType.dineIn.obs;
  final selectedTable = Rx<TableModel?>(null);
  final guestCount = 1.obs;
  final customerName = ''.obs;
  final customerNameController = TextEditingController();
  final cart = <OrderItemModel>[].obs;
  final discount = 0.0.obs;
  final discountController = TextEditingController();

  // ── Parked orders ─────────────────────────────────────────────────────────
  final parkedCount = 0.obs;

  // ── Product browsing ──────────────────────────────────────────────────────
  final categories = <CategoryModel>[].obs;
  final products = <ProductModel>[].obs;
  final selectedCategory = 'all'.obs;
  final searchQuery = ''.obs;
  final searchController = TextEditingController();

  // ── Discount mode: 'Rp' or '%' ───────────────────────────────────────────
  final discountMode = 'Rp'.obs;

  // ── Tax & service charge (from settings) ─────────────────────────────────
  final taxPercent = 0.0.obs;
  final serviceChargePercent = 0.0.obs;

  // ── Tables (for selection view) ───────────────────────────────────────────
  final tables = <TableModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
    loadCategories();
    loadTables();
    loadSettings();
    loadParkedCount();
    searchController.addListener(
      () => searchQuery.value = searchController.text,
    );
  }

  @override
  void onClose() {
    searchController.dispose();
    discountController.dispose();
    customerNameController.dispose();
    super.onClose();
  }

  // ── Load data ─────────────────────────────────────────────────────────────

  Future<void> loadProducts() async {
    final list = await _productRepo.getAll();
    products.assignAll(list);
  }

  Future<void> loadCategories() async {
    try {
      final list = await _categoryRepo.getAll();
      categories.assignAll([
        const CategoryModel(id: 'all', name: 'Semua', icon: '🏪'),
        ...list,
      ]);
    } catch (_) {
      categories.assignAll(CategoryModel.defaultCategories);
    }
  }

  Future<void> loadTables() async {
    final list = await _tableRepo.getAll();
    tables.assignAll(list);
  }

  Future<void> loadSettings() async {
    // Tax and service charge loaded in PaymentController; defaults here
    taxPercent.value = 0;
    serviceChargePercent.value = 0;
  }

  // ── Filtered products ─────────────────────────────────────────────────────

  List<ProductModel> get filteredProducts {
    var list = products.where((p) => p.stock > 0).toList();
    if (selectedCategory.value != 'all') {
      list = list.where((p) => p.categoryId == selectedCategory.value).toList();
    }
    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      list = list.where((p) => p.name.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  // ── Cart operations ───────────────────────────────────────────────────────

  void addToCart(ProductModel product) {
    final idx = cart.indexWhere((i) => i.productId == product.id);
    if (idx != -1) {
      if (cart[idx].quantity < product.stock) {
        cart[idx].quantity++;
        cart.refresh();
      } else {
        Get.snackbar(
          'Stok Habis',
          'Stok ${product.name} tidak mencukupi',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade900,
          duration: const Duration(seconds: 2),
        );
      }
    } else {
      cart.add(
        OrderItemModel(
          productId: product.id,
          productName: product.name,
          productPrice: product.price,
          productEmoji: product.emoji,
          quantity: 1,
        ),
      );
    }
  }

  void removeFromCart(String productId) {
    cart.removeWhere((i) => i.productId == productId);
  }

  void increaseQty(String productId) {
    final idx = cart.indexWhere((i) => i.productId == productId);
    if (idx != -1) {
      final product = products.firstWhereOrNull((p) => p.id == productId);
      final maxStock = product?.stock ?? 999;
      if (cart[idx].quantity < maxStock) {
        cart[idx].quantity++;
        cart.refresh();
      }
    }
  }

  void decreaseQty(String productId) {
    final idx = cart.indexWhere((i) => i.productId == productId);
    if (idx != -1) {
      if (cart[idx].quantity > 1) {
        cart[idx].quantity--;
        cart.refresh();
      } else {
        cart.removeAt(idx);
      }
    }
  }

  void setItemNote(String productId, String note) {
    final idx = cart.indexWhere((i) => i.productId == productId);
    if (idx != -1) {
      cart[idx].note = note;
      cart.refresh();
    }
  }

  void clearCart() {
    cart.clear();
    discountController.clear();
    discount.value = 0;
    discountMode.value = 'Rp';
    selectedTable.value = null;
    guestCount.value = 1;
    customerNameController.clear();
    customerName.value = '';
    searchController.clear();
    selectedCategory.value = 'all';
  }

  // ── Totals ────────────────────────────────────────────────────────────────

  double get subtotal => cart.fold(0.0, (s, i) => s + i.subtotal);

  double get discountedSubtotal =>
      (subtotal - discount.value).clamp(0, double.infinity);

  double get taxAmount => (taxPercent.value / 100) * discountedSubtotal;

  double get serviceChargeAmount =>
      (serviceChargePercent.value / 100) * discountedSubtotal;

  double get total => discountedSubtotal + taxAmount + serviceChargeAmount;

  int get totalItems => cart.fold(0, (s, i) => s + i.quantity);

  bool get isCartEmpty => cart.isEmpty;

  void updateDiscount(String value) {
    discount.value = CurrencyHelper.parseRupiah(value);
  }

  void applyPercentDiscount(double percent) {
    final flat = subtotal * (percent / 100);
    discount.value = flat.clamp(0, subtotal);
    discountController.text = flat.toStringAsFixed(0);
  }

  void updateDiscountFromInput(String value) {
    if (discountMode.value == '%') {
      final pct = double.tryParse(value) ?? 0;
      discount.value = (subtotal * pct / 100).clamp(0, subtotal);
    } else {
      discount.value = CurrencyHelper.parseRupiah(value).clamp(0, subtotal);
    }
  }

  void showTakeAwayCustomerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detail Pesanan Take Away',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: customerNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama Pemesan (opsional)',
                prefixIcon: Icon(Icons.person_rounded),
                hintText: 'Contoh: Budi',
              ),
              onChanged: (v) => customerName.value = v,
            ),
            const SizedBox(height: 16),
            Obx(() => Row(
                  children: [
                    const Text('Jumlah Pax:',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        if (guestCount.value > 1) guestCount.value--;
                      },
                    ),
                    Text('${guestCount.value}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => guestCount.value++,
                    ),
                  ],
                )),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Get.toNamed(AppRoutes.pos);
                    },
                    child: const Text('Lewati'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      customerName.value = customerNameController.text;
                      Navigator.pop(ctx);
                      Get.toNamed(AppRoutes.pos);
                    },
                    child: const Text('Lanjut'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ── Send to payment directly (Supermarket mode) ───────────────────────────

  Future<void> sendToPayment() async {
    if (cart.isEmpty) {
      Get.snackbar(
        'Keranjang Kosong',
        'Tambahkan produk terlebih dahulu',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final invoiceNumber = await _transactionRepo.generateInvoiceNumber();

    final order = OrderModel(
      invoiceNumber: invoiceNumber,
      orderType: OrderType.takeAway,
      tableId: null,
      tableNumber: null,
      guestCount: 1,
      customerName: customerName.value,
      items: List.from(cart),
      subtotal: subtotal,
      discount: discount.value,
      taxPercent: taxPercent.value,
      taxAmount: taxAmount,
      serviceChargePercent: serviceChargePercent.value,
      serviceChargeAmount: serviceChargeAmount,
      total: total,
    );

    await _orderRepo.save(order);

    clearCart();
    await loadProducts();

    Get.toNamed(AppRoutes.payment, arguments: order);
  }

  // ── Send to kitchen ───────────────────────────────────────────────────────

  Future<void> sendToKitchen() async {
    if (cart.isEmpty) {
      Get.snackbar(
        'Keranjang Kosong',
        'Tambahkan produk terlebih dahulu',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final invoiceNumber = await _transactionRepo.generateInvoiceNumber();

    final order = OrderModel(
      invoiceNumber: invoiceNumber,
      orderType: orderType.value,
      tableId: selectedTable.value?.id,
      tableNumber: selectedTable.value?.number,
      guestCount: guestCount.value,
      customerName: customerName.value,
      items: List.from(cart),
      subtotal: subtotal,
      discount: discount.value,
      taxPercent: taxPercent.value,
      taxAmount: taxAmount,
      serviceChargePercent: serviceChargePercent.value,
      serviceChargeAmount: serviceChargeAmount,
      total: total,
    );

    await _orderRepo.save(order);

    // Mark table as occupied
    if (selectedTable.value != null) {
      await _tableRepo.setOccupied(selectedTable.value!.id, order.id);
    }

    Get.snackbar(
      'Pesanan Dikirim',
      'Pesanan ${order.invoiceNumber} berhasil dikirim ke dapur',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade900,
      duration: const Duration(seconds: 3),
    );

    clearCart();
    await loadProducts();
    await loadTables();

    // Navigate back to main navigation wrapper to maintain bottom nav bar
    Get.offAllNamed(AppRoutes.main);
  }

  // ── Parked orders ─────────────────────────────────────────────────────────

  Future<List<OrderModel>> fetchParkedOrders() => _orderRepo.getParked();

  Future<void> loadParkedCount() async {
    final list = await _orderRepo.getParked();
    parkedCount.value = list.length;
  }

  Future<void> deleteParkedOrder(String id) async {
    await _orderRepo.delete(id);
    await loadParkedCount();
  }

  Future<void> parkOrder() async {
    if (cart.isEmpty) {
      Get.snackbar(
        'Keranjang Kosong',
        'Tambahkan produk terlebih dahulu',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final invoiceNumber = await _transactionRepo.generateInvoiceNumber();

    final order = OrderModel(
      invoiceNumber: invoiceNumber,
      orderType: orderType.value,
      tableId: selectedTable.value?.id,
      tableNumber: selectedTable.value?.number,
      guestCount: guestCount.value,
      customerName: customerName.value,
      items: List.from(cart),
      kitchenStatus: KitchenStatus.parked,
      subtotal: subtotal,
      discount: discount.value,
      taxPercent: taxPercent.value,
      taxAmount: taxAmount,
      serviceChargePercent: serviceChargePercent.value,
      serviceChargeAmount: serviceChargeAmount,
      total: total,
    );

    await _orderRepo.save(order);

    Get.snackbar(
      'Transaksi Ditunda',
      'Pesanan ${order.invoiceNumber} disimpan sebagai tertunda',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.amber.shade100,
      colorText: Colors.amber.shade900,
      duration: const Duration(seconds: 3),
    );

    clearCart();
    await loadParkedCount();

    Get.offAllNamed(AppRoutes.main);
  }

  Future<void> resumeParkedOrder(OrderModel order) async {
    // Restore cart state
    orderType.value = order.orderType;
    guestCount.value = order.guestCount;
    customerName.value = order.customerName;
    customerNameController.text = order.customerName;
    discount.value = order.discount;
    discountController.text = order.discount > 0
        ? order.discount.toStringAsFixed(0)
        : '';
    discountMode.value = 'Rp';

    // Restore table if dine-in
    if (order.tableId != null) {
      selectedTable.value = tables.firstWhereOrNull(
        (t) => t.id == order.tableId,
      );
    } else {
      selectedTable.value = null;
    }

    cart.assignAll(order.items);

    // Delete the parked record
    await _orderRepo.delete(order.id);
    await loadParkedCount();

    Get.toNamed(AppRoutes.orderConfirm);
  }
}
