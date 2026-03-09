import 'package:get/get.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/stock_movement_model.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/stock_repository.dart';

class StockController extends GetxController {
  final _productRepo = Get.find<ProductRepository>();
  final _stockRepo = Get.find<StockRepository>();

  final products = <ProductModel>[].obs;
  final movements = <StockMovementModel>[].obs;
  final selectedProductId = ''.obs;
  final opnames = <StockOpnameModel>[].obs;
  final activeOpname = Rx<StockOpnameModel?>(null);
  final opnameItems = <StockOpnameItemModel>[].obs;

  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    try {
      products.value = await _productRepo.getAll();
      movements.value = await _stockRepo.getMovements();
      opnames.value = await _stockRepo.getOpnames();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMovements({String? productId}) async {
    movements.value =
        await _stockRepo.getMovements(productId: productId, limit: 200);
  }

  Future<void> loadOpnames() async {
    opnames.value = await _stockRepo.getOpnames();
  }

  Future<void> loadOpnameItems(String opnameId) async {
    opnameItems.value = await _stockRepo.getOpnameItems(opnameId);
  }

  /// Adjust stock by delta (positive = add, negative = subtract).
  /// [type] must be one of StockMovementType constants.
  Future<void> adjustStock(
    ProductModel product,
    int delta,
    String type,
    String notes,
  ) async {
    final qtyBefore = product.stock;
    final qtyAfter = (qtyBefore + delta).clamp(0, 999999);
    await _productRepo.adjustStock(product.id, qtyAfter);
    await _stockRepo.addMovement(StockMovementModel(
      productId: product.id,
      productName: product.name,
      productEmoji: product.emoji,
      type: type,
      quantity: delta.abs(),
      qtyBefore: qtyBefore,
      qtyAfter: qtyAfter,
      notes: notes,
    ));
    await loadAll();
  }

  Future<void> createNewOpname(String notes) async {
    final prods = await _productRepo.getAll();
    final opname = StockOpnameModel(
      notes: notes,
      itemsCount: prods.length,
    );
    await _stockRepo.createOpname(opname);

    for (final p in prods) {
      final item = StockOpnameItemModel(
        opnameId: opname.id,
        productId: p.id,
        productName: p.name,
        productEmoji: p.emoji,
        systemQty: p.stock,
        actualQty: p.stock,
      );
      await _stockRepo.saveOpnameItem(item);
    }

    activeOpname.value = opname;
    opnameItems.value = await _stockRepo.getOpnameItems(opname.id);
    await loadOpnames();
  }

  Future<void> updateOpnameItemQty(
      StockOpnameItemModel item, int newActualQty) async {
    item.actualQty = newActualQty;
    await _stockRepo.saveOpnameItem(item);
    // Refresh list in-place
    final idx = opnameItems.indexWhere((i) => i.id == item.id);
    if (idx >= 0) {
      opnameItems[idx] = item;
      opnameItems.refresh();
    }
  }

  Future<void> finalizeOpname() async {
    final opname = activeOpname.value;
    if (opname == null) return;

    final items = opnameItems;
    for (final item in items) {
      if (item.difference == 0) continue;
      final qtyBefore = item.systemQty;
      final qtyAfter = item.actualQty;
      await _productRepo.adjustStock(item.productId, qtyAfter);
      await _stockRepo.addMovement(StockMovementModel(
        productId: item.productId,
        productName: item.productName,
        productEmoji: item.productEmoji,
        type: StockMovementType.opname,
        quantity: item.difference.abs(),
        qtyBefore: qtyBefore,
        qtyAfter: qtyAfter,
        referenceId: opname.id,
        notes: 'Stok Opname - ${opname.notes.isNotEmpty ? opname.notes : opname.id.substring(0, 8)}',
      ));
    }

    opname.status = 'completed';
    opname.completedAt = DateTime.now();
    await _stockRepo.updateOpname(opname);

    activeOpname.value = opname;
    await loadAll();
  }

  Future<void> deleteOpname(String id) async {
    await _stockRepo.deleteOpname(id);
    if (activeOpname.value?.id == id) activeOpname.value = null;
    await loadOpnames();
  }

  Future<void> openOpname(StockOpnameModel opname) async {
    activeOpname.value = opname;
    await loadOpnameItems(opname.id);
  }

  Future<List<StockMovementModel>> getMovementsForProduct(
          {String? productId, int limit = 200}) =>
      _stockRepo.getMovements(productId: productId, limit: limit);
}
