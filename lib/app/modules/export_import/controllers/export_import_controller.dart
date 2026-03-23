import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/excel_service.dart';

class ExportImportController extends GetxController {
  final _service = ExcelService();

  final isLoading = false.obs;
  final loadingMessage = ''.obs;

  // ── Export ──────────────────────────────────────────────────────────────────

  Future<void> exportProducts() => _run('Mengekspor produk…', _service.exportProducts);
  Future<void> exportCategories() => _run('Mengekspor kategori…', _service.exportCategories);
  Future<void> exportCustomers() => _run('Mengekspor pelanggan…', _service.exportCustomers);
  Future<void> exportBahanBaku() => _run('Mengekspor bahan baku…', _service.exportBahanBaku);
  Future<void> exportTransactions() => _run('Mengekspor transaksi…', _service.exportTransactions);

  // ── Import ──────────────────────────────────────────────────────────────────

  Future<void> importProducts() async {
    final path = await _pickFile();
    if (path == null) return;
    isLoading.value = true;
    loadingMessage.value = 'Mengimpor produk…';
    try {
      final result = await _service.importProducts(path);
      _showResult(result, 'Produk');
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> importCategories() async {
    final path = await _pickFile();
    if (path == null) return;
    isLoading.value = true;
    loadingMessage.value = 'Mengimpor kategori…';
    try {
      final result = await _service.importCategories(path);
      _showResult(result, 'Kategori');
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> importCustomers() async {
    final path = await _pickFile();
    if (path == null) return;
    isLoading.value = true;
    loadingMessage.value = 'Mengimpor pelanggan…';
    try {
      final result = await _service.importCustomers(path);
      _showResult(result, 'Pelanggan');
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> importBahanBaku() async {
    final path = await _pickFile();
    if (path == null) return;
    isLoading.value = true;
    loadingMessage.value = 'Mengimpor bahan baku…';
    try {
      final result = await _service.importBahanBaku(path);
      _showResult(result, 'Bahan Baku');
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  // ── Template ────────────────────────────────────────────────────────────────

  Future<void> downloadTemplate(String entity) =>
      _run('Membuat template…', () => _service.downloadTemplate(entity));

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Future<String?> _pickFile() async {
    // FilePicker is called directly here so the picker dialog appears
    // before we set isLoading = true (better UX)
    return _service.pickFileForImport();
  }

  Future<void> _run(String message, Future<void> Function() fn) async {
    isLoading.value = true;
    loadingMessage.value = message;
    try {
      await fn();
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  void _showResult(ImportResult result, String entityName) {
    final ctx = Get.context;
    if (ctx == null) return;

    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              result.errors.isEmpty ? Icons.check_circle_rounded : Icons.warning_rounded,
              color: result.errors.isEmpty ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text('Impor $entityName'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _resultRow(Icons.add_circle_outline, 'Ditambahkan', result.added, Colors.green),
            _resultRow(Icons.edit_outlined, 'Diperbarui', result.updated, Colors.blue),
            _resultRow(Icons.skip_next_rounded, 'Dilewati', result.skipped, Colors.grey),
            if (result.errors.isNotEmpty) ...[
              const Divider(),
              Text(
                'Kesalahan (${result.errors.length}):',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: result.errors
                        .map((e) => Text(
                              '• $e',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.red),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: Get.back,
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(IconData icon, String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
          const Spacer(),
          Text(
            '$count',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showError(Object e) {
    Get.snackbar(
      'Error',
      e.toString(),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade900,
    );
  }
}
