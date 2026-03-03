import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/cart_item_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/helpers/currency_helper.dart';

class PosController extends GetxController {
  final _productRepo = Get.find<ProductRepository>();
  final _transactionRepo = Get.find<TransactionRepository>();

  final products = <ProductModel>[].obs;
  final cart = <CartItemModel>[].obs;
  final selectedCategory = 'all'.obs;
  final searchQuery = ''.obs;
  final discountAmount = 0.0.obs;
  final paymentMethod = 'Tunai'.obs;
  final cashAmount = 0.0.obs;

  final searchController = TextEditingController();
  final discountController = TextEditingController();
  final cashController = TextEditingController();

  final categories = CategoryModel.defaultCategories;
  final paymentMethods = ['Tunai', 'Transfer', 'Kartu Debit', 'QRIS'];

  @override
  void onInit() {
    super.onInit();
    loadProducts();
    searchController.addListener(() {
      searchQuery.value = searchController.text;
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    discountController.dispose();
    cashController.dispose();
    super.onClose();
  }

  Future<void> loadProducts() async {
    final list = await _productRepo.getAll();
    products.assignAll(list);
  }

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

  // ── Cart Operations ───────────────────────────────────────────────────────

  void addToCart(ProductModel product) {
    final idx = cart.indexWhere((c) => c.product.id == product.id);
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
      cart.add(CartItemModel(product: product, quantity: 1));
    }
  }

  void removeFromCart(String productId) {
    cart.removeWhere((c) => c.product.id == productId);
  }

  void increaseQty(String productId) {
    final idx = cart.indexWhere((c) => c.product.id == productId);
    if (idx != -1) {
      if (cart[idx].quantity < cart[idx].product.stock) {
        cart[idx].quantity++;
        cart.refresh();
      }
    }
  }

  void decreaseQty(String productId) {
    final idx = cart.indexWhere((c) => c.product.id == productId);
    if (idx != -1) {
      if (cart[idx].quantity > 1) {
        cart[idx].quantity--;
        cart.refresh();
      } else {
        cart.removeAt(idx);
      }
    }
  }

  void clearCart() {
    cart.clear();
    discountController.clear();
    discountAmount.value = 0;
    cashController.clear();
    cashAmount.value = 0;
  }

  void updateCashAmount(String value) {
    cashAmount.value = CurrencyHelper.parseRupiah(value);
  }

  // ── Totals ────────────────────────────────────────────────────────────────

  double get subtotal => cart.fold(0.0, (sum, item) => sum + item.subtotal);

  double get total =>
      (subtotal - discountAmount.value).clamp(0, double.infinity);

  int get totalItems => cart.fold(0, (sum, item) => sum + item.quantity);

  bool get isCartEmpty => cart.isEmpty;

  void updateDiscount(String value) {
    discountAmount.value = CurrencyHelper.parseRupiah(value);
  }

  // ── Payment ───────────────────────────────────────────────────────────────

  bool validatePayment() {
    if (cart.isEmpty) {
      Get.snackbar(
          'Keranjang Kosong', 'Tambahkan produk ke keranjang terlebih dahulu');
      return false;
    }
    if (paymentMethod.value == 'Tunai') {
      final cash = CurrencyHelper.parseRupiah(cashController.text);
      if (cash < total) {
        Get.snackbar('Pembayaran Kurang', 'Jumlah uang tidak mencukupi');
        return false;
      }
    }
    return true;
  }

  Future<void> processPayment() async {
    if (!validatePayment()) return;

    final paymentAmt = paymentMethod.value == 'Tunai'
        ? CurrencyHelper.parseRupiah(cashController.text)
        : total;

    // generateInvoiceNumber sekarang async
    final invoiceNumber = await _transactionRepo.generateInvoiceNumber();

    final transaction = TransactionModel(
      invoiceNumber: invoiceNumber,
      items: List.from(cart),
      subtotal: subtotal,
      discount: discountAmount.value,
      total: total,
      paymentAmount: paymentAmt,
      change: paymentAmt - total,
      paymentMethod: paymentMethod.value,
    );

    await _transactionRepo.save(transaction);

    // Kurangi stok produk di database
    for (final item in cart) {
      item.product.stock -= item.quantity;
      await _productRepo.update(item.product);
    }

    clearCart();
    await loadProducts();

    Get.back(); // tutup dialog pembayaran
    Get.toNamed(AppRoutes.receipt, arguments: transaction);
  }
}
