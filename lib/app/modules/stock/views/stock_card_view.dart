import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/stock_movement_model.dart';
import '../../../utils/constants/app_colors.dart';
import '../controllers/stock_controller.dart';

class StockCardView extends StatefulWidget {
  const StockCardView({super.key});

  @override
  State<StockCardView> createState() => _StockCardViewState();
}

class _StockCardViewState extends State<StockCardView> {
  final _ctrl = Get.find<StockController>();
  final _dtFormatter = DateFormat('dd MMM yyyy HH:mm', 'id_ID');
  final _dateFormatter = DateFormat('dd MMM yyyy', 'id_ID');

  String? _productId;
  ProductModel? _product;
  DateTimeRange? _dateRange;
  final _allMovements = <StockMovementModel>[];
  final _movements = <StockMovementModel>[].obs;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _productId = Get.arguments as String?;
    if (_productId != null) {
      _product = _ctrl.products.firstWhereOrNull((p) => p.id == _productId);
    }
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _allMovements
      ..clear()
      ..addAll(await _ctrl.getMovementsForProduct(
          productId: _productId, limit: 500));
    _applyDateFilter();
    if (mounted) setState(() => _loading = false);
  }

  void _applyDateFilter() {
    if (_dateRange == null) {
      _movements.value = List.from(_allMovements);
    } else {
      final start = DateTime(
        _dateRange!.start.year,
        _dateRange!.start.month,
        _dateRange!.start.day,
      );
      final end = DateTime(
        _dateRange!.end.year,
        _dateRange!.end.month,
        _dateRange!.end.day,
        23,
        59,
        59,
      );
      _movements.value = _allMovements
          .where((m) =>
              m.createdAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
              m.createdAt.isBefore(end.add(const Duration(seconds: 1))))
          .toList();
    }
  }

  void _clearFilter() {
    setState(() {
      _productId = null;
      _product = null;
    });
    _load();
  }

  void _clearDateRange() {
    setState(() => _dateRange = null);
    _applyDateFilter();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _dateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _applyDateFilter();
    }
  }

  Future<void> _showProductPicker() async {
    final products = _ctrl.products;
    final searchCtrl = TextEditingController();
    String query = '';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final filtered = query.isEmpty
              ? products
              : products
                  .where((p) =>
                      p.name.toLowerCase().contains(query.toLowerCase()))
                  .toList();
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle
                const SizedBox(height: 8),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Pilih Produk',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                // Search
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Cari produk...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                searchCtrl.clear();
                                setModalState(() => query = '');
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (v) => setModalState(() => query = v),
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                // All option
                ListTile(
                  leading: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.list_alt_rounded,
                        color: AppColors.primary, size: 18),
                  ),
                  title: const Text('Semua Produk',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _clearFilter();
                  },
                ),
                const Divider(height: 1),
                // Product list
                Expanded(
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 56),
                    itemBuilder: (_, i) {
                      final p = filtered[i];
                      final isSelected = _productId == p.id;
                      return ListTile(
                        leading: Text(p.emoji,
                            style: const TextStyle(fontSize: 24)),
                        title: Text(p.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            )),
                        subtitle: Text('Stok: ${p.stock}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded,
                                color: AppColors.primary)
                            : null,
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _productId = p.id;
                            _product = p;
                          });
                          _load();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _product != null
        ? '${_product!.emoji} ${_product!.name}'
        : 'Semua Pergerakan Stok';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title,
            style: const TextStyle(fontSize: 16),
            overflow: TextOverflow.ellipsis),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Filter tanggal',
            onPressed: _pickDateRange,
            icon: const Icon(Icons.calendar_month_rounded),
          ),
          IconButton(
            tooltip: 'Filter produk',
            onPressed: _showProductPicker,
            icon: const Icon(Icons.filter_list_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          // Product info card
          if (_product != null)
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      Text(_product!.emoji,
                          style: const TextStyle(fontSize: 36)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_product!.name,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              'Stok saat ini: ${_product!.stock} unit',
                              style: TextStyle(
                                fontSize: 13,
                                color: _product!.stock < 5
                                    ? AppColors.error
                                    : Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: _clearFilter,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 13, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),

          // Date range filter banner
          if (_dateRange != null)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_dateFormatter.format(_dateRange!.start)}  –  ${_dateFormatter.format(_dateRange!.end)}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearDateRange,
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: AppColors.primary),
                  ),
                ],
              ),
            ),

          // Movement list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Obx(() {
                    if (_movements.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.swap_vert_rounded,
                                size: 64,
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.3)),
                            const SizedBox(height: 12),
                            const Text('Belum ada pergerakan stok',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14)),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                        itemCount: _movements.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 6),
                        itemBuilder: (_, i) =>
                            _MovementTile(
                              movement: _movements[i],
                              dtFormatter: _dtFormatter,
                              showProduct: _productId == null,
                            ),
                      ),
                    );
                  }),
          ),
        ],
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  final StockMovementModel movement;
  final DateFormat dtFormatter;
  final bool showProduct;

  const _MovementTile({
    required this.movement,
    required this.dtFormatter,
    required this.showProduct,
  });

  bool get _isInbound =>
      movement.type == StockMovementType.purchase ||
      movement.type == StockMovementType.adjustmentIn ||
      (movement.type == StockMovementType.opname &&
          movement.qtyAfter >= movement.qtyBefore);

  @override
  Widget build(BuildContext context) {
    final isIn = _isInbound;
    final color = isIn ? Colors.green.shade700 : AppColors.error;
    final icon =
        isIn ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
    final sign = isIn ? '+' : '-';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        StockMovementType.label(movement.type),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      if (showProduct) ...[
                        const SizedBox(width: 6),
                        Text(movement.productEmoji,
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            movement.productName,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dtFormatter.format(movement.createdAt),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                  if (movement.notes.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      movement.notes,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$sign${movement.quantity}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  'Sisa: ${movement.qtyAfter}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
