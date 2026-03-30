import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:get/get.dart';
import '../data/providers/storage_provider.dart';

enum LicenseStatus { unknown, trial, licensed, expired }

class LicenseService extends GetxService {
  // Obfuscated secret key — do NOT change after release
  static final _sk = String.fromCharCodes(
      [75, 80, 77, 95, 76, 73, 67, 95, 50, 48, 50, 53, 95, 77, 66, 95, 83, 69, 67]);

  final _db = Get.find<DatabaseProvider>();

  final status = LicenseStatus.unknown.obs;
  final expiresAt = Rxn<DateTime>();
  final daysLeft = 0.obs;

  bool get isActive =>
      status.value == LicenseStatus.trial ||
      status.value == LicenseStatus.licensed;

  Future<LicenseService> init() async {
    await refresh();
    return this;
  }

  Future<void> refresh() async {
    // Record install date on first run
    String? installStr = await _db.getSetting('install_date');
    if (installStr == null) {
      installStr = DateTime.now().toIso8601String();
      await _db.setSetting('install_date', installStr);
    }

    // Check saved license
    final savedUntil = await _db.getSetting('licensed_until') ?? '';
    if (savedUntil.isNotEmpty) {
      final until = DateTime.tryParse(savedUntil);
      if (until != null && until.isAfter(DateTime.now())) {
        status.value = LicenseStatus.licensed;
        expiresAt.value = until;
        daysLeft.value = until.difference(DateTime.now()).inDays + 1;
        return;
      }
    }

    // Check trial (7 days from install)
    final installDate = DateTime.tryParse(installStr) ?? DateTime.now();
    final trialEnd = installDate.add(const Duration(days: 7));
    final now = DateTime.now();

    if (now.isBefore(trialEnd)) {
      status.value = LicenseStatus.trial;
      expiresAt.value = trialEnd;
      daysLeft.value = trialEnd.difference(now).inDays + 1;
    } else {
      status.value = LicenseStatus.expired;
      expiresAt.value = null;
      daysLeft.value = 0;
    }
  }

  /// Returns null on success, or error message on failure.
  Future<String?> activate(String key) async {
    final clean = key.trim().toUpperCase().replaceAll(RegExp(r'[^0-9A-F]'), '');
    if (clean.length != 20) return 'Format kunci tidak valid';

    final payload = clean.substring(0, 8);
    final givenMac = clean.substring(8);
    final expectedMac = _computeMac(payload);

    if (givenMac != expectedMac) return 'Kunci lisensi tidak valid';

    final sec = int.tryParse(payload, radix: 16);
    if (sec == null) return 'Kunci lisensi tidak valid';

    final expiry = DateTime.fromMillisecondsSinceEpoch(sec * 1000);
    if (expiry.isBefore(DateTime.now())) return 'Kunci lisensi sudah kadaluarsa';

    await _db.setSetting('licensed_until', expiry.toIso8601String());
    await refresh();
    return null; // success
  }

  static String _computeMac(String payload) {
    final hmac = Hmac(sha256, utf8.encode(_sk));
    return hmac.convert(utf8.encode(payload)).toString().toUpperCase().substring(0, 12);
  }

  /// Generate a license key valid for [days] days from now.
  /// Only used in the developer generator tool.
  static String generateKey(int days) {
    final expiry = DateTime.now().add(Duration(days: days));
    final sec = expiry.millisecondsSinceEpoch ~/ 1000;
    final payload = sec.toRadixString(16).toUpperCase().padLeft(8, '0');
    final mac = _computeMac(payload);
    final raw = payload + mac; // 20 chars
    return '${raw.substring(0, 5)}-${raw.substring(5, 10)}'
        '-${raw.substring(10, 15)}-${raw.substring(15, 20)}';
  }

  /// Parse expiry date from a generated key (for preview in generator).
  static DateTime? expiryFromKey(String key) {
    final clean = key.trim().toUpperCase().replaceAll(RegExp(r'[^0-9A-F]'), '');
    if (clean.length != 20) return null;
    final sec = int.tryParse(clean.substring(0, 8), radix: 16);
    if (sec == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(sec * 1000);
  }
}
