import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/void_log_model.dart';
import '../../../data/providers/storage_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/helpers/currency_helper.dart';

class VoidLogView extends StatefulWidget {
  const VoidLogView({super.key});

  @override
  State<VoidLogView> createState() => _VoidLogViewState();
}

class _VoidLogViewState extends State<VoidLogView> {
  final _db = Get.find<DatabaseProvider>();
  final _logs = <VoidLogModel>[].obs;
  final _isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _isLoading.value = true;
    try {
      final list = await _db.getVoidLogs();
      _logs.assignAll(list);
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Log Pembatalan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Obx(() {
        if (_isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_logs.isEmpty) {
          return const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.check_circle_outline_rounded,
                  size: 64, color: AppColors.textSecondary),
              SizedBox(height: 12),
              Text('Tidak ada pesanan yang dibatalkan',
                  style: TextStyle(color: AppColors.textSecondary)),
            ]),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _logs.length,
          itemBuilder: (_, i) => _buildCard(_logs[i]),
        );
      }),
    );
  }

  void _showDetail(VoidLogModel log) {
    Get.toNamed(AppRoutes.voidLogDetail, arguments: log);
  }

  Widget _buildCard(VoidLogModel log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showDetail(log),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.cancel_rounded,
                color: AppColors.error, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.invoiceNumber,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'Alasan: ${log.reason}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                Text(
                  'Oleh: ${log.voidedBy} · ${CurrencyHelper.formatDateTime(log.voidedAt)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            CurrencyHelper.formatRupiah(log.orderTotal),
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.error,
                fontSize: 13),
          ),
        ],
      ),
    ),
    ),
    ),
    );
  }
}
