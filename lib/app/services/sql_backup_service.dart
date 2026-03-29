import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/providers/storage_provider.dart';

class SqlBackupService {
  final _db = Get.find<DatabaseProvider>();

  /// Export seluruh database ke file .sql dan share via dialog.
  Future<void> exportSql() async {
    final sql = await _db.exportToSql();

    final dir = await getTemporaryDirectory();
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
        '_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final fileName = 'kasir_pintar_backup_$stamp.sql';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(sql, flush: true);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Backup Database Kasir Pintar Sasbim',
      text: 'Backup database Kasir Pintar Sasbim — $stamp',
    );
  }

  /// Pilih file .sql dari storage.
  Future<String?> pickSqlFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['sql'],
      allowMultiple: false,
    );
    return result?.files.single.path;
  }

  /// Import (restore) database dari file .sql yang dipilih.
  Future<void> importSql(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) throw Exception('File tidak ditemukan: $filePath');
    final sql = await file.readAsString();
    if (sql.trim().isEmpty) throw Exception('File SQL kosong');
    await _db.importFromSql(sql);
  }

  /// Tampilkan dialog konfirmasi sebelum import.
  Future<bool> confirmImport(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Database SQL'),
        content: const Text(
          'Seluruh data yang ada di aplikasi akan diganti dengan data dari file SQL.\n\n'
          'Pastikan file SQL berasal dari backup Kasir Pintar Sasbim.\n\n'
          'Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ya, Import Sekarang'),
          ),
        ],
      ),
    );
    return result == true;
  }
}
