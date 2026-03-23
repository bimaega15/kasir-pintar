import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../data/models/bahan_baku_model.dart';
import '../data/models/category_model.dart';
import '../data/models/customer_model.dart';
import '../data/models/product_model.dart';
import '../data/repositories/bahan_baku_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/customer_repository.dart';
import '../data/repositories/product_repository.dart';
import '../data/repositories/transaction_repository.dart';

const _uuid = Uuid();

class ImportResult {
  final int added;
  final int updated;
  final int skipped;
  final List<String> errors;

  const ImportResult({
    this.added = 0,
    this.updated = 0,
    this.skipped = 0,
    this.errors = const [],
  });
}

class ExcelService {
  // ── Cell value helpers ──────────────────────────────────────────────────────

  String? _str(Data? cell) {
    if (cell?.value == null) return null;
    final v = cell!.value;
    String raw;
    if (v is TextCellValue) {
      raw = v.value.toString().trim();
    } else if (v is IntCellValue) {
      raw = v.value.toString();
    } else if (v is DoubleCellValue) {
      raw = v.value.toString();
    } else {
      raw = v.toString().trim();
    }
    return raw.isEmpty ? null : raw;
  }

  double _dbl(Data? cell, {double d = 0}) {
    if (cell?.value == null) return d;
    final v = cell!.value;
    if (v is DoubleCellValue) return v.value;
    if (v is IntCellValue) return v.value.toDouble();
    if (v is TextCellValue) return double.tryParse(v.value.toString()) ?? d;
    return d;
  }

  int _int(Data? cell, {int d = 0}) {
    if (cell?.value == null) return d;
    final v = cell!.value;
    if (v is IntCellValue) return v.value;
    if (v is DoubleCellValue) return v.value.toInt();
    if (v is TextCellValue) return int.tryParse(v.value.toString()) ?? d;
    return d;
  }

  Data? _col(List<Data?> row, int index) =>
      index < row.length ? row[index] : null;

  String _dateTag() => DateFormat('yyyyMMdd').format(DateTime.now());

  // ── File helpers ────────────────────────────────────────────────────────────

  Future<void> _shareFile(List<int> bytes, String filename) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    if (Platform.isAndroid || Platform.isIOS) {
      await Share.shareXFiles([XFile(file.path)], text: filename);
    } else {
      // Desktop: simpan ke documents dir dan beri tahu user
      final docsDir = await getApplicationDocumentsDirectory();
      final destFile = File('${docsDir.path}/$filename');
      await destFile.writeAsBytes(bytes);
      Get.snackbar(
        'File Tersimpan',
        'Disimpan di: ${destFile.path}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 8),
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
      );
    }
  }

  Future<String?> pickFileForImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: false,
    );
    return result?.files.single.path;
  }

  // ── Produk ──────────────────────────────────────────────────────────────────

  Future<void> exportProducts() async {
    final products = await Get.find<ProductRepository>().getAll();
    final excel = Excel.createExcel();
    final sheet = excel['Produk'];
    excel.delete('Sheet1');

    sheet.appendRow([
      TextCellValue('id'),
      TextCellValue('nama'),
      TextCellValue('kategori_id'),
      TextCellValue('harga'),
      TextCellValue('stok'),
      TextCellValue('deskripsi'),
      TextCellValue('emoji'),
    ]);

    for (final p in products) {
      sheet.appendRow([
        TextCellValue(p.id),
        TextCellValue(p.name),
        TextCellValue(p.categoryId),
        DoubleCellValue(p.price),
        IntCellValue(p.stock),
        TextCellValue(p.description),
        TextCellValue(p.emoji),
      ]);
    }

    await _shareFile(excel.save()!, 'Produk_${_dateTag()}.xlsx');
  }

  Future<ImportResult> importProducts(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables['Produk'] ?? excel.tables.values.firstOrNull;
    if (sheet == null) return const ImportResult(errors: ['Sheet "Produk" tidak ditemukan']);

    final repo = Get.find<ProductRepository>();
    final existing = {for (final p in await repo.getAll()) p.id: p};

    int added = 0, updated = 0, skipped = 0;
    final errors = <String>[];

    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      try {
        final name = _str(_col(row, 1));
        if (name == null) {
          skipped++;
          continue;
        }
        final id = _str(_col(row, 0)) ?? '';
        final existingProduct = existing[id];

        final product = ProductModel(
          id: id.isEmpty ? null : id,
          name: name,
          categoryId: _str(_col(row, 2)) ?? 'other',
          price: _dbl(_col(row, 3)),
          stock: _int(_col(row, 4)),
          description: _str(_col(row, 5)) ?? '',
          emoji: _str(_col(row, 6)) ?? '📦',
          createdAt: existingProduct?.createdAt,
        );

        if (existingProduct != null) {
          await repo.update(product);
          updated++;
        } else {
          await repo.add(product);
          added++;
        }
      } catch (e) {
        errors.add('Baris ${i + 1}: $e');
      }
    }
    return ImportResult(added: added, updated: updated, skipped: skipped, errors: errors);
  }

  // ── Kategori ────────────────────────────────────────────────────────────────

  Future<void> exportCategories() async {
    final cats = await Get.find<CategoryRepository>().getAll();
    final excel = Excel.createExcel();
    final sheet = excel['Kategori'];
    excel.delete('Sheet1');

    sheet.appendRow([
      TextCellValue('id'),
      TextCellValue('nama'),
      TextCellValue('ikon'),
    ]);

    for (final c in cats) {
      sheet.appendRow([
        TextCellValue(c.id),
        TextCellValue(c.name),
        TextCellValue(c.icon),
      ]);
    }

    await _shareFile(excel.save()!, 'Kategori_${_dateTag()}.xlsx');
  }

  Future<ImportResult> importCategories(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables['Kategori'] ?? excel.tables.values.firstOrNull;
    if (sheet == null) return const ImportResult(errors: ['Sheet "Kategori" tidak ditemukan']);

    final repo = Get.find<CategoryRepository>();
    final existing = {for (final c in await repo.getAll()) c.id: c};

    int added = 0, updated = 0, skipped = 0;
    final errors = <String>[];

    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      try {
        final name = _str(_col(row, 1));
        if (name == null) {
          skipped++;
          continue;
        }
        final id = _str(_col(row, 0)) ?? '';
        final icon = _str(_col(row, 2)) ?? '📦';

        final category = CategoryModel(
          id: id.isEmpty ? _uuid.v4() : id,
          name: name,
          icon: icon,
        );

        if (existing.containsKey(id) && id.isNotEmpty) {
          await repo.update(category);
          updated++;
        } else {
          await repo.add(category);
          added++;
        }
      } catch (e) {
        errors.add('Baris ${i + 1}: $e');
      }
    }
    return ImportResult(added: added, updated: updated, skipped: skipped, errors: errors);
  }

  // ── Pelanggan ───────────────────────────────────────────────────────────────

  Future<void> exportCustomers() async {
    final customers = await Get.find<CustomerRepository>().getAll();
    final excel = Excel.createExcel();
    final sheet = excel['Pelanggan'];
    excel.delete('Sheet1');

    sheet.appendRow([
      TextCellValue('id'),
      TextCellValue('nama'),
      TextCellValue('telepon'),
      TextCellValue('alamat'),
      TextCellValue('catatan'),
    ]);

    for (final c in customers) {
      sheet.appendRow([
        TextCellValue(c.id),
        TextCellValue(c.name),
        TextCellValue(c.phone),
        TextCellValue(c.address),
        TextCellValue(c.notes),
      ]);
    }

    await _shareFile(excel.save()!, 'Pelanggan_${_dateTag()}.xlsx');
  }

  Future<ImportResult> importCustomers(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables['Pelanggan'] ?? excel.tables.values.firstOrNull;
    if (sheet == null) return const ImportResult(errors: ['Sheet "Pelanggan" tidak ditemukan']);

    final repo = Get.find<CustomerRepository>();
    final existing = {for (final c in await repo.getAll()) c.id: c};

    int added = 0, updated = 0, skipped = 0;
    final errors = <String>[];

    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      try {
        final name = _str(_col(row, 1));
        if (name == null) {
          skipped++;
          continue;
        }
        final id = _str(_col(row, 0)) ?? '';
        final existingCustomer = existing[id];

        final customer = CustomerModel(
          id: id.isEmpty ? null : id,
          name: name,
          phone: _str(_col(row, 2)) ?? '',
          address: _str(_col(row, 3)) ?? '',
          notes: _str(_col(row, 4)) ?? '',
          createdAt: existingCustomer?.createdAt,
        );

        if (existingCustomer != null) {
          await repo.update(customer);
          updated++;
        } else {
          await repo.save(customer);
          added++;
        }
      } catch (e) {
        errors.add('Baris ${i + 1}: $e');
      }
    }
    return ImportResult(added: added, updated: updated, skipped: skipped, errors: errors);
  }

  // ── Bahan Baku ──────────────────────────────────────────────────────────────

  Future<void> exportBahanBaku() async {
    final items = await Get.find<BahanBakuRepository>().getAll();
    final excel = Excel.createExcel();
    final sheet = excel['BahanBaku'];
    excel.delete('Sheet1');

    sheet.appendRow([
      TextCellValue('id'),
      TextCellValue('nama'),
      TextCellValue('satuan'),
      TextCellValue('stok'),
      TextCellValue('stok_minimum'),
      TextCellValue('harga_per_unit'),
      TextCellValue('emoji'),
      TextCellValue('catatan'),
    ]);

    for (final bb in items) {
      sheet.appendRow([
        TextCellValue(bb.id),
        TextCellValue(bb.name),
        TextCellValue(bb.unit),
        DoubleCellValue(bb.stock),
        DoubleCellValue(bb.minStock),
        DoubleCellValue(bb.price),
        TextCellValue(bb.emoji),
        TextCellValue(bb.notes),
      ]);
    }

    await _shareFile(excel.save()!, 'BahanBaku_${_dateTag()}.xlsx');
  }

  Future<ImportResult> importBahanBaku(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables['BahanBaku'] ?? excel.tables.values.firstOrNull;
    if (sheet == null) return const ImportResult(errors: ['Sheet "BahanBaku" tidak ditemukan']);

    final repo = Get.find<BahanBakuRepository>();
    final existing = {for (final bb in await repo.getAll()) bb.id: bb};

    int added = 0, updated = 0, skipped = 0;
    final errors = <String>[];

    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      try {
        final name = _str(_col(row, 1));
        if (name == null) {
          skipped++;
          continue;
        }
        final id = _str(_col(row, 0)) ?? '';
        final existingItem = existing[id];

        final bb = BahanBakuModel(
          id: id.isEmpty ? null : id,
          name: name,
          unit: _str(_col(row, 2)) ?? 'pcs',
          stock: _dbl(_col(row, 3)),
          minStock: _dbl(_col(row, 4)),
          price: _dbl(_col(row, 5)),
          emoji: _str(_col(row, 6)) ?? '📦',
          notes: _str(_col(row, 7)) ?? '',
          createdAt: existingItem?.createdAt,
        );

        if (existingItem != null) {
          await repo.update(bb);
          updated++;
        } else {
          await repo.add(bb);
          added++;
        }
      } catch (e) {
        errors.add('Baris ${i + 1}: $e');
      }
    }
    return ImportResult(added: added, updated: updated, skipped: skipped, errors: errors);
  }

  // ── Transaksi (export only) ─────────────────────────────────────────────────

  Future<void> exportTransactions() async {
    final txns = await Get.find<TransactionRepository>().getAll();
    final excel = Excel.createExcel();
    final sheet = excel['Transaksi'];
    excel.delete('Sheet1');

    sheet.appendRow([
      TextCellValue('invoice'),
      TextCellValue('tanggal'),
      TextCellValue('kasir'),
      TextCellValue('pelanggan'),
      TextCellValue('item'),
      TextCellValue('subtotal'),
      TextCellValue('diskon'),
      TextCellValue('pajak'),
      TextCellValue('total'),
      TextCellValue('metode_bayar'),
      TextCellValue('dibayar'),
      TextCellValue('kembalian'),
    ]);

    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    for (final t in txns) {
      final itemsSummary = t.items
          .map((i) => '${i.quantity}x ${i.product.name}')
          .join(', ');
      sheet.appendRow([
        TextCellValue(t.invoiceNumber),
        TextCellValue(fmt.format(t.createdAt)),
        TextCellValue(t.cashierName),
        TextCellValue(t.customerName),
        TextCellValue(itemsSummary),
        DoubleCellValue(t.subtotal),
        DoubleCellValue(t.discount),
        DoubleCellValue(t.taxAmount),
        DoubleCellValue(t.total),
        TextCellValue(t.paymentMethod),
        DoubleCellValue(t.paymentAmount),
        DoubleCellValue(t.change),
      ]);
    }

    await _shareFile(excel.save()!, 'Transaksi_${_dateTag()}.xlsx');
  }

  // ── Template downloader ─────────────────────────────────────────────────────

  Future<void> downloadTemplate(String entity) async {
    final excel = Excel.createExcel();
    late Sheet sheet;
    late String filename;

    switch (entity) {
      case 'produk':
        sheet = excel['Produk'];
        excel.delete('Sheet1');
        sheet.appendRow([
          TextCellValue('id'),
          TextCellValue('nama'),
          TextCellValue('kategori_id'),
          TextCellValue('harga'),
          TextCellValue('stok'),
          TextCellValue('deskripsi'),
          TextCellValue('emoji'),
        ]);
        sheet.appendRow([
          TextCellValue('(kosongkan untuk baru)'),
          TextCellValue('Contoh Produk'),
          TextCellValue('food'),
          DoubleCellValue(10000),
          IntCellValue(50),
          TextCellValue('Deskripsi produk'),
          TextCellValue('🍽️'),
        ]);
        filename = 'Template_Produk.xlsx';
        break;
      case 'kategori':
        sheet = excel['Kategori'];
        excel.delete('Sheet1');
        sheet.appendRow([
          TextCellValue('id'),
          TextCellValue('nama'),
          TextCellValue('ikon'),
        ]);
        sheet.appendRow([
          TextCellValue('(kosongkan untuk baru)'),
          TextCellValue('Makanan'),
          TextCellValue('🍔'),
        ]);
        filename = 'Template_Kategori.xlsx';
        break;
      case 'pelanggan':
        sheet = excel['Pelanggan'];
        excel.delete('Sheet1');
        sheet.appendRow([
          TextCellValue('id'),
          TextCellValue('nama'),
          TextCellValue('telepon'),
          TextCellValue('alamat'),
          TextCellValue('catatan'),
        ]);
        sheet.appendRow([
          TextCellValue('(kosongkan untuk baru)'),
          TextCellValue('Nama Pelanggan'),
          TextCellValue('08123456789'),
          TextCellValue('Jl. Contoh No. 1'),
          TextCellValue(''),
        ]);
        filename = 'Template_Pelanggan.xlsx';
        break;
      case 'bahan_baku':
        sheet = excel['BahanBaku'];
        excel.delete('Sheet1');
        sheet.appendRow([
          TextCellValue('id'),
          TextCellValue('nama'),
          TextCellValue('satuan'),
          TextCellValue('stok'),
          TextCellValue('stok_minimum'),
          TextCellValue('harga_per_unit'),
          TextCellValue('emoji'),
          TextCellValue('catatan'),
        ]);
        sheet.appendRow([
          TextCellValue('(kosongkan untuk baru)'),
          TextCellValue('Tepung Terigu'),
          TextCellValue('kg'),
          DoubleCellValue(10),
          DoubleCellValue(2),
          DoubleCellValue(15000),
          TextCellValue('🌾'),
          TextCellValue(''),
        ]);
        filename = 'Template_BahanBaku.xlsx';
        break;
      default:
        return;
    }

    await _shareFile(excel.save()!, filename);
  }
}
