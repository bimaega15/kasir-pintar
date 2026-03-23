import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/order_item_model.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/table_model.dart';
import '../../../data/models/price_level_model.dart';
import '../../../data/providers/storage_provider.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/price_level_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/table_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../routes/app_routes.dart';
import '../../main_navigation/controllers/main_navigation_controller.dart';
import '../../../services/printer_service.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/helpers/currency_helper.dart';

class OrderController extends GetxController {
  final _orderRepo = Get.find<OrderRepository>();
  final _tableRepo = Get.find<TableRepository>();
  final _productRepo = Get.find<ProductRepository>();
  final _transactionRepo = Get.find<TransactionRepository>();
  final _categoryRepo = Get.find<CategoryRepository>();
  final _priceLevelRepo = Get.find<PriceLevelRepository>();

  // ── Active order state ────────────────────────────────────────────────────
  final orderType = OrderType.dineIn.obs;
  final selectedTable = Rx<TableModel?>(null);
  final guestCount = 1.obs;
  final customerName = ''.obs;
  final customerNameController = TextEditingController();
  final selectedCustomerId = ''.obs;
  final selectedCustomerName = ''.obs;

  // Autocomplete for customer name field
  final searchCustomerNameQuery = ''.obs;
  final suggestedCustomers = <CustomerModel>[].obs;
  final selectedCustomerModel = Rx<CustomerModel?>(null);

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

  // ── Price levels ──────────────────────────────────────────────────────────
  final priceLevels = <PriceLevelModel>[].obs;
  final activePriceLevelId = ''.obs;

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
    loadPriceLevels();
    loadAllCustomers();
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

  /// Dipanggil setelah scan QR. Format: `PRODUCT:<id>|<name>|<price>`
  void handleScannedQr(String rawValue) {
    if (!rawValue.startsWith('PRODUCT:')) {
      Get.snackbar(
        'Format Tidak Dikenal',
        'QR ini bukan kode produk Kasir Pintar',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade900,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    final parts = rawValue.substring(8).split('|');
    if (parts.isEmpty) return;
    final productId = parts[0];
    final product = products.firstWhereOrNull((p) => p.id == productId);
    if (product != null) {
      addToCart(product);
      Get.snackbar(
        'Produk Ditambahkan',
        '${product.emoji} ${product.name}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
        duration: const Duration(seconds: 2),
      );
    } else {
      Get.snackbar(
        'Produk Tidak Ditemukan',
        'ID produk tidak ada di katalog saat ini',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> loadPriceLevels() async {
    try {
      final levels = await _priceLevelRepo.getAll();
      priceLevels.assignAll(levels);
      final defaultLevel = levels.firstWhereOrNull((l) => l.isDefault);
      activePriceLevelId.value = defaultLevel?.id ?? (levels.isNotEmpty ? levels.first.id : '');
    } catch (e) {
      print('[loadPriceLevels] Error: $e');
    }
  }

  void setActivePriceLevel(String levelId) {
    if (activePriceLevelId.value == levelId) return;
    activePriceLevelId.value = levelId;
    // Re-price all items in cart
    for (int i = 0; i < cart.length; i++) {
      final product = products.firstWhereOrNull((p) => p.id == cart[i].productId);
      if (product != null) {
        final newPrice = product.getPriceForLevel(levelId);
        cart[i] = cart[i].copyWith(productPrice: newPrice);
      }
    }
    cart.refresh();
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
    try {
      final db = Get.find<DatabaseProvider>();
      final tax = await db.getSetting('tax_percent');
      final sc = await db.getSetting('service_charge_percent');
      taxPercent.value = double.tryParse(tax ?? '0') ?? 0;
      serviceChargePercent.value = double.tryParse(sc ?? '0') ?? 0;
    } catch (e) {
      taxPercent.value = 0;
      serviceChargePercent.value = 0;
    }
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
      final price = product.getPriceForLevel(
          activePriceLevelId.value.isEmpty ? null : activePriceLevelId.value);
      cart.add(
        OrderItemModel(
          productId: product.id,
          productName: product.name,
          productPrice: price,
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
    selectedCustomerId.value = '';
    selectedCustomerName.value = '';
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
    final customerRepo = Get.find<CustomerRepository>();
    customerNameController.clear();
    customerName.value = '';
    selectedCustomerId.value = '';
    selectedCustomerName.value = '';
    selectedCustomerModel.value = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        List<CustomerModel> suggestions = [];
        bool showSuggestions = false;
        CustomerModel? pickedCustomer;

        return StatefulBuilder(
          builder: (ctx, setState) {
            Future<void> onSearchChanged(String query) async {
              pickedCustomer = null;
              selectedCustomerId.value = '';
              if (query.trim().isEmpty) {
                setState(() { suggestions = []; showSuggestions = false; });
                return;
              }
              final all = await customerRepo.getAll();
              final q = query.toLowerCase();
              final filtered = all
                  .where((c) => c.name.toLowerCase().contains(q))
                  .take(6)
                  .toList();
              setState(() { suggestions = filtered; showSuggestions = true; });
            }

            Future<void> addNewCustomer() async {
              final name = customerNameController.text.trim();
              if (name.isEmpty) return;
              final newCust = CustomerModel(name: name);
              await customerRepo.save(newCust);
              pickedCustomer = newCust;
              selectedCustomerId.value = newCust.id;
              selectedCustomerName.value = newCust.name;
              selectedCustomerModel.value = newCust;
              setState(() { suggestions = []; showSuggestions = false; });
              Get.snackbar(
                'Pelanggan Ditambahkan',
                '"$name" berhasil disimpan ke data pelanggan',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green.shade100,
                colorText: Colors.green.shade900,
                duration: const Duration(seconds: 2),
              );
            }

            return Padding(
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
                    decoration: InputDecoration(
                      labelText: 'Nama Pemesan (opsional)',
                      prefixIcon: const Icon(Icons.person_rounded),
                      hintText: 'Ketik untuk cari pelanggan...',
                      suffixIcon: pickedCustomer != null
                          ? const Icon(Icons.check_circle_rounded,
                              color: Colors.green)
                          : customerNameController.text.trim().isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.person_add_rounded,
                                      color: Colors.green),
                                  tooltip: 'Tambah sebagai pelanggan baru',
                                  onPressed: addNewCustomer,
                                )
                              : null,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      customerName.value = v;
                      onSearchChanged(v);
                    },
                  ),
                  // Suggestions dropdown — only shown when there are matches
                  if (showSuggestions && suggestions.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 220),
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        children: suggestions.map((c) => ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.1),
                            child: Text(
                              c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          title: Text(c.name),
                          subtitle: c.phone.isNotEmpty
                              ? Text(c.phone,
                                  style: const TextStyle(fontSize: 11))
                              : null,
                          onTap: () {
                            customerNameController.text = c.name;
                            customerName.value = c.name;
                            pickedCustomer = c;
                            selectedCustomerId.value = c.id;
                            selectedCustomerName.value = c.name;
                            selectedCustomerModel.value = c;
                            setState(() { showSuggestions = false; });
                          },
                        )).toList(),
                      ),
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
                            final typedName = customerNameController.text.trim();
                            // If name is typed but not confirmed from list/added
                            if (typedName.isNotEmpty && pickedCustomer == null) {
                              Get.snackbar(
                                'Pilih Pelanggan',
                                'Pilih pelanggan dari daftar atau tambahkan sebagai pelanggan baru terlebih dahulu',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.orange.shade100,
                                colorText: Colors.orange.shade900,
                                duration: const Duration(seconds: 3),
                              );
                              return;
                            }
                            customerName.value = typedName;
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
            );
          },
        );
      },
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

    final effectiveCustomerName = selectedCustomerName.value.isNotEmpty
        ? selectedCustomerName.value
        : customerName.value;

    final order = OrderModel(
      invoiceNumber: invoiceNumber,
      orderType: OrderType.takeAway,
      tableId: null,
      tableNumber: null,
      guestCount: 1,
      customerName: effectiveCustomerName,
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

    final effectiveCustomerName = selectedCustomerName.value.isNotEmpty
        ? selectedCustomerName.value
        : customerName.value;

    final order = OrderModel(
      invoiceNumber: invoiceNumber,
      orderType: orderType.value,
      tableId: selectedTable.value?.id,
      tableNumber: selectedTable.value?.number,
      guestCount: guestCount.value,
      customerName: effectiveCustomerName,
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

    // Auto-cetak ke printer dapur (silent — tidak blokir jika printer tidak terhubung)
    if (Get.isRegistered<PrinterService>()) {
      Get.find<PrinterService>().printKitchenOrder(order, silent: true);
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

    _goToKasirTab();
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

    final effectiveCustomerNameForPark = selectedCustomerName.value.isNotEmpty
        ? selectedCustomerName.value
        : customerName.value;

    final order = OrderModel(
      invoiceNumber: invoiceNumber,
      orderType: orderType.value,
      tableId: selectedTable.value?.id,
      tableNumber: selectedTable.value?.number,
      guestCount: guestCount.value,
      customerName: effectiveCustomerNameForPark,
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

    _goToKasirTab();
  }

  void _goToKasirTab() {
    Get.offAllNamed(AppRoutes.main);
    // Set index after navigation completes so the fresh controller is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<MainNavigationController>(
          tag: MainNavigationController.TAG)) {
        Get.find<MainNavigationController>(tag: MainNavigationController.TAG)
            .changeIndex(4);
      }
    });
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

  // ── Customer picker ───────────────────────────────────────────────────────

  Future<void> showCustomerPicker(BuildContext context) async {
    final customerRepo = Get.find<CustomerRepository>();
    final allCustomers = await customerRepo.getAll();

    final searchCtrl = TextEditingController();
    final filtered = allCustomers.obs;

    searchCtrl.addListener(() {
      final q = searchCtrl.text.toLowerCase();
      if (q.isEmpty) {
        filtered.assignAll(allCustomers);
      } else {
        filtered.assignAll(allCustomers.where((c) =>
            c.name.toLowerCase().contains(q) || c.phone.contains(q)));
      }
    });

    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (_, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    'Pilih Pelanggan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: TextField(
                controller: searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Cari nama atau telepon...',
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                final list = filtered.toList();
                return ListView(
                  controller: scrollController,
                  children: [
                    // "Tanpa Pelanggan" option at top
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            AppColors.textSecondary.withValues(alpha: 0.15),
                        child: const Icon(Icons.person_off_rounded,
                            color: AppColors.textSecondary, size: 20),
                      ),
                      title: const Text('Tanpa Pelanggan'),
                      subtitle: const Text('Hapus pilihan pelanggan'),
                      onTap: () {
                        selectedCustomerId.value = '';
                        selectedCustomerName.value = '';
                        Navigator.pop(ctx);
                      },
                    ),
                    const Divider(height: 1),
                    if (list.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'Pelanggan tidak ditemukan',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      ...list.map((CustomerModel c) {
                        final initials = c.name
                            .trim()
                            .split(' ')
                            .map((w) => w.isNotEmpty ? w[0] : '')
                            .take(2)
                            .join()
                            .toUpperCase();
                        final isSelected =
                            selectedCustomerId.value == c.id;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? AppColors.primary
                                : AppColors.primary.withValues(alpha: 0.12),
                            child: Text(
                              initials,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          title: Text(
                            c.name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: c.phone.isNotEmpty
                              ? Text(c.phone,
                                  style: const TextStyle(fontSize: 12))
                              : null,
                          trailing: isSelected
                              ? const Icon(Icons.check_circle_rounded,
                                  color: AppColors.primary)
                              : null,
                          onTap: () {
                            selectedCustomerId.value = c.id;
                            selectedCustomerName.value = c.name;
                            Navigator.pop(ctx);
                          },
                        );
                      }),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );

    searchCtrl.dispose();
  }

  // ── Customer autocomplete ──────────────────────────────────────────────────

  Future<void> loadAllCustomers() async {
    final customerRepo = Get.find<CustomerRepository>();
    final allCustomers = await customerRepo.getAll();
    suggestedCustomers.assignAll(allCustomers);
  }

  void searchCustomersByName(String query) {
    searchCustomerNameQuery.value = query;
    if (query.isEmpty) {
      suggestedCustomers.clear();
      selectedCustomerModel.value = null;
      return;
    }

    final customerRepo = Get.find<CustomerRepository>();
    customerRepo.getAll().then((allCustomers) {
      final q = query.toLowerCase();
      final filtered = allCustomers
          .where((c) => c.name.toLowerCase().contains(q))
          .take(5)
          .toList();
      suggestedCustomers.value = filtered;
    });
  }

  void selectCustomerFromSuggestion(CustomerModel customer) {
    selectedCustomerModel.value = customer;
    customerNameController.text = customer.name;
    customerName.value = customer.name;
    selectedCustomerId.value = customer.id;
    selectedCustomerName.value = customer.name;
    searchCustomerNameQuery.value = customer.name;
    suggestedCustomers.clear();
  }

  // Reset customer name fields for fresh start on table select view
  void resetCustomerName() {
    customerNameController.clear();
    customerName.value = '';
    selectedCustomerId.value = '';
    selectedCustomerName.value = '';
    selectedCustomerModel.value = null;
    searchCustomerNameQuery.value = '';
    suggestedCustomers.clear();
  }

  void createNewCustomerFromSearch(String name) {
    selectedCustomerModel.value = null;
    customerNameController.text = name;
    customerName.value = name;
    selectedCustomerId.value = '';
    selectedCustomerName.value = '';
    suggestedCustomers.clear();
  }

  // Create and save new customer directly from table select view
  Future<void> createAndSaveNewCustomer(String name) async {
    if (name.trim().isEmpty) {
      Get.snackbar(
        'Gagal',
        'Nama pemesan tidak boleh kosong',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final customerRepo = Get.find<CustomerRepository>();

      // Check if name already exists
      final allCustomers = await customerRepo.getAll();
      final nameExists = allCustomers.any(
          (c) => c.name.toLowerCase() == name.trim().toLowerCase());

      if (nameExists) {
        Get.snackbar(
          'Gagal',
          'Nama pemesan "${name.trim()}" sudah terdaftar',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      final newCustomer = CustomerModel(
        name: name.trim(),
        phone: '',
        address: '',
        notes: '',
      );

      await customerRepo.save(newCustomer);

      // Update controller state
      customerNameController.text = newCustomer.name;
      customerName.value = newCustomer.name;
      selectedCustomerId.value = newCustomer.id;
      selectedCustomerName.value = newCustomer.name;
      selectedCustomerModel.value = newCustomer;
      suggestedCustomers.clear();

      // Reload customers list
      await loadAllCustomers();

      Get.snackbar(
        'Berhasil',
        'Pelanggan "${newCustomer.name}" berhasil ditambahkan',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menambahkan pelanggan: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
