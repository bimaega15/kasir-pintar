import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/bahan_baku_model.dart';
import '../../../data/repositories/bahan_baku_repository.dart';

class BahanBakuController extends GetxController {
  final _repo = Get.find<BahanBakuRepository>();

  // ── Observable state ────────────────────────────────────────────────────
  final bahanBakuList = <BahanBakuModel>[].obs;
  final movements = <BahanBakuMovementModel>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;

  // ── Form controllers ───────────────────────────────────────────────────
  final nameController = TextEditingController();
  final unitController = TextEditingController();
  final stockController = TextEditingController();
  final minStockController = TextEditingController();
  final priceController = TextEditingController();
  final notesController = TextEditingController();
  final selectedEmoji = '\u{1F4E6}'.obs;
  final selectedUnit = 'kg'.obs;

  // ── Movement form controllers ──────────────────────────────────────────
  final movementQtyController = TextEditingController();
  final movementNotesController = TextEditingController();
  final movementCostController = TextEditingController();

  BahanBakuModel? _editingItem;
  bool get isEditing => _editingItem != null;

  List<BahanBakuModel> get filteredList {
    if (searchQuery.value.isEmpty) return bahanBakuList;
    final q = searchQuery.value.toLowerCase();
    return bahanBakuList.where((bb) => bb.name.toLowerCase().contains(q)).toList();
  }

  List<BahanBakuModel> get lowStockItems =>
      bahanBakuList.where((bb) => bb.isLowStock).toList();

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  @override
  void onClose() {
    nameController.dispose();
    unitController.dispose();
    stockController.dispose();
    minStockController.dispose();
    priceController.dispose();
    notesController.dispose();
    movementQtyController.dispose();
    movementNotesController.dispose();
    movementCostController.dispose();
    super.onClose();
  }

  // ── Data Loading ───────────────────────────────────────────────────────

  Future<void> loadAll() async {
    isLoading.value = true;
    try {
      bahanBakuList.value = await _repo.getAll();
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data bahan baku: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMovements({String? bahanBakuId}) async {
    try {
      movements.value =
          await _repo.getMovements(bahanBakuId: bahanBakuId, limit: 200);
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat riwayat: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // ── Form Preparation ──────────────────────────────────────────────────

  void prepareAdd() {
    _editingItem = null;
    nameController.clear();
    unitController.text = 'kg';
    stockController.text = '0';
    minStockController.text = '0';
    priceController.text = '0';
    notesController.clear();
    selectedEmoji.value = '\u{1F4E6}';
    selectedUnit.value = 'kg';
  }

  void prepareEdit(BahanBakuModel item) {
    _editingItem = item;
    nameController.text = item.name;
    unitController.text = item.unit;
    stockController.text = item.stock.toString();
    minStockController.text = item.minStock.toString();
    priceController.text = item.price.toString();
    notesController.text = item.notes;
    selectedEmoji.value = item.emoji;
    selectedUnit.value = item.unit;
  }

  // ── CRUD Operations ───────────────────────────────────────────────────

  /// Returns the success message on success, or throws a [String] error message.
  Future<String> saveBahanBaku() async {
    final name = nameController.text.trim();
    final unit = unitController.text.trim();
    if (name.isEmpty) throw 'Nama bahan baku tidak boleh kosong';
    if (unit.isEmpty) throw 'Satuan tidak boleh kosong';

    final stock = double.tryParse(stockController.text) ?? 0;
    final minStock = double.tryParse(minStockController.text) ?? 0;
    final price = double.tryParse(priceController.text) ?? 0;

    if (isEditing) {
      final updated = _editingItem!.copyWith(
        name: name,
        unit: unit,
        stock: stock,
        minStock: minStock,
        price: price,
        emoji: selectedEmoji.value,
        notes: notesController.text.trim(),
      );
      await _repo.update(updated);
      await loadAll();
      return 'Bahan baku "$name" berhasil diperbarui';
    } else {
      final bb = BahanBakuModel(
        name: name,
        unit: unit,
        stock: stock,
        minStock: minStock,
        price: price,
        emoji: selectedEmoji.value,
        notes: notesController.text.trim(),
      );
      await _repo.add(bb);
      await loadAll();
      return 'Bahan baku "$name" berhasil ditambahkan';
    }
  }

  Future<void> deleteBahanBaku(BahanBakuModel item) async {
    try {
      await _repo.delete(item.id);
      Get.snackbar('Berhasil', '"${item.name}" berhasil dihapus',
          snackPosition: SnackPosition.BOTTOM);
      await loadAll();
    } catch (e) {
      Get.snackbar('Error', 'Gagal menghapus: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // ── Stock Adjustment ──────────────────────────────────────────────────

  Future<void> adjustStock(
    BahanBakuModel item,
    double qty,
    String type,
    String notes, {
    double? totalCost,
  }) async {
    final qtyBefore = item.stock;
    final isIn = BahanBakuMovementType.isInbound(type);
    final qtyAfter = isIn ? qtyBefore + qty : qtyBefore - qty;

    if (qtyAfter < 0) {
      Get.snackbar('Peringatan', 'Stok tidak boleh kurang dari 0',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      await _repo.updateStock(item.id, qtyAfter);
      await _repo.addMovement(BahanBakuMovementModel(
        bahanBakuId: item.id,
        bahanBakuName: item.name,
        bahanBakuEmoji: item.emoji,
        type: type,
        quantity: qty,
        qtyBefore: qtyBefore,
        qtyAfter: qtyAfter,
        totalCost: totalCost,
        notes: notes,
      ));
      await loadAll();
      await loadMovements(bahanBakuId: item.id);
      Get.snackbar(
        'Berhasil',
        '${BahanBakuMovementType.label(type)}: ${item.name} '
            '${isIn ? '+' : '-'}$qty ${item.unit}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', 'Gagal update stok: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // ── Movement form helpers ─────────────────────────────────────────────

  void clearMovementForm() {
    movementQtyController.clear();
    movementNotesController.clear();
    movementCostController.clear();
  }
}
