import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/stock_movement_model.dart';
import '../../../utils/constants/app_colors.dart';
import '../controllers/stock_controller.dart';

class StockOpnameDetailView extends StatefulWidget {
  const StockOpnameDetailView({super.key});

  @override
  State<StockOpnameDetailView> createState() => _StockOpnameDetailViewState();
}

class _StockOpnameDetailViewState extends State<StockOpnameDetailView> {
  late final StockController _ctrl;
  late final StockOpnameModel _opname;
  final _dtFormatter = DateFormat('dd MMM yyyy HH:mm', 'id_ID');
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _finalizing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<StockController>();
    _opname = Get.arguments as StockOpnameModel;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _isDraft => _opname.status == 'draft';

  int get _itemsWithDiff =>
      _ctrl.opnameItems.where((i) => i.difference != 0).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isDraft ? 'Input Stok Opname' : 'Hasil Opname',
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header info
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _dtFormatter.format(_opname.createdAt),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      if (_opname.notes.isNotEmpty)
                        Text(_opname.notes,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isDraft
                        ? Colors.orange.withValues(alpha: 0.12)
                        : Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _isDraft ? 'Draft' : 'Selesai',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _isDraft
                          ? Colors.orange.shade700
                          : Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // Items list
          Expanded(
            child: Obx(() {
              final allItems = _ctrl.opnameItems;
              final items = _searchQuery.isEmpty
                  ? allItems
                  : allItems
                      .where((i) => i.productName
                          .toLowerCase()
                          .contains(_searchQuery))
                      .toList();
              if (allItems.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (items.isEmpty) {
                return const Center(
                  child: Text('Produk tidak ditemukan',
                      style: TextStyle(color: AppColors.textSecondary)),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 100),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (ctx, i) {
                  final item = items[i];
                  return _OpnameItemRow(
                    key: ValueKey(item.id),
                    item: item,
                    isDraft: _isDraft,
                    onQtyChanged: (newQty) {
                      _ctrl.updateOpnameItemQty(item, newQty);
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
      // Bottom summary + finalize button
      bottomNavigationBar: Obx(() {
        final total = _ctrl.opnameItems.length;
        final withDiff = _itemsWithDiff;
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
                top: BorderSide(color: AppColors.divider)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total produk: $total',
                      style: const TextStyle(fontSize: 13)),
                  Text(
                    'Selisih: $withDiff item',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: withDiff > 0
                          ? AppColors.error
                          : Colors.green.shade700,
                    ),
                  ),
                ],
              ),
              if (_isDraft) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _finalizing ? null : _confirmFinalize,
                    child: _finalizing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Selesaikan Opname',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  void _confirmFinalize() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Selesaikan Opname'),
        content: Text(
          _itemsWithDiff > 0
              ? 'Terdapat $_itemsWithDiff item dengan selisih. '
                  'Stok sistem akan diperbarui sesuai hasil hitung fisik. Lanjutkan?'
              : 'Tidak ada selisih stok. Opname akan ditandai selesai.',
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                foregroundColor: Colors.white),
            onPressed: () async {
              Get.back();
              setState(() => _finalizing = true);
              await _ctrl.finalizeOpname();
              setState(() => _finalizing = false);
              Get.back();
              Get.snackbar(
                'Opname Selesai',
                'Stok telah diperbarui berdasarkan hasil opname',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.teal.shade600,
                colorText: Colors.white,
              );
            },
            child: const Text('Selesaikan'),
          ),
        ],
      ),
    );
  }
}

class _OpnameItemRow extends StatefulWidget {
  final StockOpnameItemModel item;
  final bool isDraft;
  final ValueChanged<int> onQtyChanged;

  const _OpnameItemRow({
    super.key,
    required this.item,
    required this.isDraft,
    required this.onQtyChanged,
  });

  @override
  State<_OpnameItemRow> createState() => _OpnameItemRowState();
}

class _OpnameItemRowState extends State<_OpnameItemRow> {
  late final TextEditingController _ctrl;
  late final FocusNode _focusNode;
  late int _localActualQty;

  @override
  void initState() {
    super.initState();
    _localActualQty = widget.item.actualQty;
    _ctrl = TextEditingController(text: _localActualQty.toString());
    _focusNode = FocusNode();
    // Auto-commit saat focus hilang (scroll away, tap field lain)
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) _commit();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  int get _localDiff => _localActualQty - widget.item.systemQty;

  void _onChanged(String v) {
    final parsed = int.tryParse(v);
    if (parsed != null && parsed != _localActualQty) {
      setState(() => _localActualQty = parsed);
    }
  }

  void _commit() {
    final qty = int.tryParse(_ctrl.text) ?? widget.item.actualQty;
    setState(() => _localActualQty = qty);
    widget.onQtyChanged(qty);
  }

  @override
  Widget build(BuildContext context) {
    final diff = _localDiff;
    final diffColor = diff > 0
        ? Colors.green.shade700
        : diff < 0
            ? AppColors.error
            : AppColors.textSecondary;
    final diffText = diff > 0 ? '+$diff' : '$diff';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: diff != 0
              ? (diff > 0
                  ? Colors.green.withValues(alpha: 0.3)
                  : AppColors.error.withValues(alpha: 0.3))
              : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Text(widget.item.productEmoji,
              style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.productName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Sistem: ${widget.item.systemQty} unit',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Actual qty input
          if (widget.isDraft)
            SizedBox(
              width: 72,
              child: TextField(
                controller: _ctrl,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
                onChanged: _onChanged,
                onSubmitted: (_) => _commit(),
                onEditingComplete: _commit,
              ),
            )
          else
            Text(
              '${widget.item.actualQty}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15),
            ),
          const SizedBox(width: 10),
          // Difference chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: diffColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              diff == 0 ? '±0' : diffText,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: diffColor),
            ),
          ),
        ],
      ),
    );
  }
}
