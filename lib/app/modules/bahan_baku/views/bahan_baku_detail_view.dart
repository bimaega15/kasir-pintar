import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/bahan_baku_model.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/helpers/currency_helper.dart';
import '../controllers/bahan_baku_controller.dart';
import '../../../utils/responsive/responsive_helper.dart';

class BahanBakuDetailView extends StatefulWidget {
  const BahanBakuDetailView({super.key});

  @override
  State<BahanBakuDetailView> createState() => _BahanBakuDetailViewState();
}

class _BahanBakuDetailViewState extends State<BahanBakuDetailView> {
  late BahanBakuModel item;
  final ctrl = Get.find<BahanBakuController>();
  final _dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

  @override
  void initState() {
    super.initState();
    item = Get.arguments as BahanBakuModel;
    ctrl.loadMovements(bahanBakuId: item.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(item.name),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        // Refresh item data from the list
        final updated = ctrl.bahanBakuList.firstWhereOrNull((b) => b.id == item.id);
        if (updated != null) item = updated;

        return SingleChildScrollView(
          padding: Res.padding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              _buildInfoCard(),
              const SizedBox(height: 16),

              // Quick Actions
              _buildQuickActions(context),
              const SizedBox(height: 24),

              // Movement History
              const Text(
                'Riwayat Pergerakan Stok',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildMovementList(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(item.emoji, style: const TextStyle(fontSize: 36)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    if (item.notes.isNotEmpty)
                      Text(item.notes,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _InfoTile(
                label: 'Stok',
                value: '${_fmtQty(item.stock)} ${item.unit}',
                color: item.isLowStock ? AppColors.error : AppColors.success,
              ),
              _InfoTile(
                label: 'Min. Stok',
                value: '${_fmtQty(item.minStock)} ${item.unit}',
                color: AppColors.warning,
              ),
              _InfoTile(
                label: 'Harga',
                value: CurrencyHelper.formatRupiah(item.price),
                color: AppColors.primary,
              ),
            ],
          ),
          if (item.isLowStock) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_rounded, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Stok menipis! Segera lakukan pembelian.',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.error,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionBtn(
            icon: Icons.add_circle_outline,
            label: 'Stok Masuk',
            color: AppColors.success,
            onTap: () => _showStockDialog(BahanBakuMovementType.purchase),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionBtn(
            icon: Icons.remove_circle_outline,
            label: 'Pemakaian',
            color: AppColors.error,
            onTap: () => _showStockDialog(BahanBakuMovementType.usage),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionBtn(
            icon: Icons.tune_rounded,
            label: 'Koreksi',
            color: Colors.orange.shade700,
            onTap: () => _showAdjustmentDialog(),
          ),
        ),
      ],
    );
  }

  Widget _buildMovementList() {
    final movs = ctrl.movements;
    if (movs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.history_rounded, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text(
              'Belum ada riwayat pergerakan stok',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: movs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final m = movs[i];
        final isIn = BahanBakuMovementType.isInbound(m.type);
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (isIn ? AppColors.success : AppColors.error)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(
                  isIn
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  size: 18,
                  color: isIn ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      BahanBakuMovementType.label(m.type),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _dateFormat.format(m.createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                    if (m.notes.isNotEmpty)
                      Text(
                        m.notes,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIn ? '+' : '-'}${_fmtQty(m.quantity)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isIn ? AppColors.success : AppColors.error,
                    ),
                  ),
                  Text(
                    '${_fmtQty(m.qtyBefore)} \u2192 ${_fmtQty(m.qtyAfter)}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                  if (m.totalCost != null && m.totalCost! > 0)
                    Text(
                      CurrencyHelper.formatRupiah(m.totalCost!),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showStockDialog(String type) {
    ctrl.clearMovementForm();
    final isPurchase = type == BahanBakuMovementType.purchase;

    Get.dialog(
      AlertDialog(
        title: Text(isPurchase ? 'Stok Masuk' : 'Pemakaian'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Stok saat ini: ${_fmtQty(item.stock)} ${item.unit}',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl.movementQtyController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: InputDecoration(
                labelText: 'Jumlah (${item.unit})',
                border: const OutlineInputBorder(),
              ),
            ),
            if (isPurchase) ...[
              const SizedBox(height: 12),
              TextField(
                controller: ctrl.movementCostController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                decoration: const InputDecoration(
                  labelText: 'Total Biaya (Rp) - opsional',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: ctrl.movementNotesController,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final qty =
                  double.tryParse(ctrl.movementQtyController.text) ?? 0;
              if (qty <= 0) {
                Get.snackbar('Peringatan', 'Jumlah harus lebih dari 0',
                    snackPosition: SnackPosition.BOTTOM);
                return;
              }
              final cost = double.tryParse(ctrl.movementCostController.text);
              Get.back();
              ctrl.adjustStock(item, qty, type,
                  ctrl.movementNotesController.text.trim(),
                  totalCost: isPurchase ? cost : null);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isPurchase ? AppColors.success : AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(isPurchase ? 'Tambah Stok' : 'Kurangi Stok'),
          ),
        ],
      ),
    );
  }

  void _showAdjustmentDialog() {
    ctrl.clearMovementForm();
    final adjustType = BahanBakuMovementType.adjustmentIn.obs;

    Get.dialog(
      AlertDialog(
        title: const Text('Koreksi Stok'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Stok saat ini: ${_fmtQty(item.stock)} ${item.unit}',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            Obx(() => Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => adjustType.value =
                            BahanBakuMovementType.adjustmentIn,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: adjustType.value ==
                                    BahanBakuMovementType.adjustmentIn
                                ? AppColors.success.withValues(alpha: 0.15)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: adjustType.value ==
                                      BahanBakuMovementType.adjustmentIn
                                  ? AppColors.success
                                  : Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Tambah',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: adjustType.value ==
                                      BahanBakuMovementType.adjustmentIn
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => adjustType.value =
                            BahanBakuMovementType.adjustmentOut,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: adjustType.value ==
                                    BahanBakuMovementType.adjustmentOut
                                ? AppColors.error.withValues(alpha: 0.15)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: adjustType.value ==
                                      BahanBakuMovementType.adjustmentOut
                                  ? AppColors.error
                                  : Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Kurang',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: adjustType.value ==
                                      BahanBakuMovementType.adjustmentOut
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl.movementQtyController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: InputDecoration(
                labelText: 'Jumlah (${item.unit})',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl.movementNotesController,
              decoration: const InputDecoration(
                labelText: 'Alasan koreksi',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final qty =
                  double.tryParse(ctrl.movementQtyController.text) ?? 0;
              if (qty <= 0) {
                Get.snackbar('Peringatan', 'Jumlah harus lebih dari 0',
                    snackPosition: SnackPosition.BOTTOM);
                return;
              }
              Get.back();
              ctrl.adjustStock(item, qty, adjustType.value,
                  ctrl.movementNotesController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Koreksi'),
          ),
        ],
      ),
    );
  }

  String _fmtQty(double qty) {
    return qty == qty.truncateToDouble()
        ? qty.toInt().toString()
        : qty.toStringAsFixed(1);
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
