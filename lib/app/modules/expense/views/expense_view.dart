import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/expense_controller.dart';
import '../../../data/models/expense_model.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/helpers/currency_helper.dart';

class ExpenseView extends GetView<ExpenseController> {
  const ExpenseView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengeluaran Operasional'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Tambah Pengeluaran',
            onPressed: controller.openAddForm,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPeriodFilter(),
          _buildSummaryCard(),
          Expanded(child: _buildExpenseList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.openAddForm,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Obx(() => Row(
            children: ['Hari Ini', 'Minggu Ini', 'Bulan Ini']
                .map((period) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(period),
                        selected: controller.selectedPeriod.value == period,
                        onSelected: (_) => controller.setPeriod(period),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: controller.selectedPeriod.value == period
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ))
                .toList(),
          )),
    );
  }

  Widget _buildSummaryCard() {
    return Obx(() {
      final cats = controller.categoryTotals;
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.money_off_rounded,
                      color: Colors.red.shade700, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Pengeluaran',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                      Text(
                        CurrencyHelper.formatRupiah(controller.totalExpense.value),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${controller.expenses.length} item',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade600,
                  ),
                ),
              ],
            ),
            if (cats.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: cats.entries.map((e) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Text(
                    '${e.key}: ${CurrencyHelper.formatRupiah(e.value)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )).toList(),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildExpenseList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.expenses.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_rounded,
                  size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              const Text(
                'Belum ada pengeluaran',
                style: TextStyle(
                    fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Catat pengeluaran operasional bisnis Anda',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: controller.loadExpenses,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          itemCount: controller.expenses.length,
          itemBuilder: (_, i) => _buildExpenseCard(controller.expenses[i]),
        ),
      );
    });
  }

  Widget _buildExpenseCard(ExpenseModel expense) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 6,
              offset: Offset(0, 2))
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_categoryIcon(expense.category),
              color: Colors.red.shade600, size: 22),
        ),
        title: Text(
          expense.description.isNotEmpty
              ? expense.description
              : expense.category,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.textPrimary),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    expense.category,
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  expense.paymentMethod,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              CurrencyHelper.formatDate(expense.date),
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyHelper.formatRupiah(expense.amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => controller.openEditForm(expense),
                  child: const Icon(Icons.edit_rounded,
                      size: 18, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => controller.deleteExpense(expense),
                  child: Icon(Icons.delete_outline_rounded,
                      size: 18, color: Colors.red.shade400),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Gaji Karyawan':
        return Icons.people_rounded;
      case 'Sewa Tempat':
        return Icons.home_work_rounded;
      case 'Listrik & Air':
        return Icons.bolt_rounded;
      case 'Bahan Bakar':
        return Icons.local_gas_station_rounded;
      case 'Transportasi':
        return Icons.directions_car_rounded;
      case 'Perlengkapan':
        return Icons.shopping_bag_rounded;
      case 'Pemasaran & Iklan':
        return Icons.campaign_rounded;
      case 'Pemeliharaan':
        return Icons.build_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }
}
