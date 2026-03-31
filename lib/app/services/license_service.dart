import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
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
  final deviceIdDisplay = ''.obs; // Format: XXXX-XXXX-XXXX-XXXX

  String? _cachedDeviceId; // 16-char hex, used in HMAC

  bool get isActive =>
      status.value == LicenseStatus.trial ||
      status.value == LicenseStatus.licensed;

  Future<LicenseService> init() async {
    await _getDeviceId();
    await refresh();
    return this;
  }

  // ─── Device ID ───────────────────────────────────────────────────────────
  Future<String> _getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    final plugin = DeviceInfoPlugin();
    String raw;
    try {
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        raw = info.id;
      } else if (Platform.isWindows) {
        final info = await plugin.windowsInfo;
        raw = info.deviceId;
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        raw = info.identifierForVendor ?? info.name;
      } else {
        raw = 'generic-device';
      }
    } catch (_) {
      raw = 'fallback-device';
    }

    final hash = sha256.convert(utf8.encode(raw)).toString().toUpperCase();
    _cachedDeviceId = hash.substring(0, 16);

    deviceIdDisplay.value =
        '${_cachedDeviceId!.substring(0, 4)}-'
        '${_cachedDeviceId!.substring(4, 8)}-'
        '${_cachedDeviceId!.substring(8, 12)}-'
        '${_cachedDeviceId!.substring(12, 16)}';

    return _cachedDeviceId!;
  }

  // ─── Refresh status ───────────────────────────────────────────────────────
  Future<void> refresh() async {
    // DEBUG ONLY — hapus setelah testing
    await _db.setSetting('licensed_until', '');
    await _db.setSetting('used_license_keys', '');
    await _db.setSetting('install_date', DateTime.now().subtract(const Duration(days: 8)).toIso8601String());

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

  // ─── Activate ─────────────────────────────────────────────────────────────
  /// Returns null on success, or error message on failure.
  Future<String?> activate(String key) async {
    final clean = key.trim().toUpperCase().replaceAll(RegExp(r'[^0-9A-F]'), '');
    if (clean.length != 20) return 'Format kunci tidak valid';

    // Cek apakah key sudah pernah digunakan
    final usedRaw = await _db.getSetting('used_license_keys') ?? '';
    final usedKeys = usedRaw.isEmpty ? <String>[] : usedRaw.split(',');
    if (usedKeys.contains(clean)) return 'Kunci lisensi sudah pernah digunakan';

    final payload = clean.substring(0, 8);
    final givenMac = clean.substring(8);

    // Verifikasi HMAC dengan device ID perangkat ini
    final deviceId = await _getDeviceId();
    final expectedMac = _computeMac(payload, deviceId);

    if (givenMac != expectedMac) {
      return 'Kunci tidak valid atau bukan untuk perangkat ini';
    }

    final sec = int.tryParse(payload, radix: 16);
    if (sec == null) return 'Kunci lisensi tidak valid';

    final expiry = DateTime.fromMillisecondsSinceEpoch(sec * 1000);
    if (expiry.isBefore(DateTime.now())) return 'Kunci lisensi sudah kadaluarsa';

    // Simpan ke daftar yang sudah digunakan
    usedKeys.add(clean);
    await _db.setSetting('used_license_keys', usedKeys.join(','));

    await _db.setSetting('licensed_until', expiry.toIso8601String());
    await refresh();
    return null; // success
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  static String _computeMac(String payload, String deviceId) {
    final hmac = Hmac(sha256, utf8.encode(_sk));
    return hmac
        .convert(utf8.encode('$payload:$deviceId'))
        .toString()
        .toUpperCase()
        .substring(0, 12);
  }

  /// Generate key for [days] days, bound to [deviceId] (16-char hex, no dashes).
  static String generateKey(int days, String deviceId) {
    final expiry = DateTime.now().add(Duration(days: days));
    final sec = expiry.millisecondsSinceEpoch ~/ 1000;
    final payload = sec.toRadixString(16).toUpperCase().padLeft(8, '0');
    final mac = _computeMac(payload, deviceId);
    final raw = payload + mac;
    return '${raw.substring(0, 5)}-${raw.substring(5, 10)}'
        '-${raw.substring(10, 15)}-${raw.substring(15, 20)}';
  }

  /// Parse expiry date from key (for display in generator).
  static DateTime? expiryFromKey(String key) {
    final clean = key.trim().toUpperCase().replaceAll(RegExp(r'[^0-9A-F]'), '');
    if (clean.length != 20) return null;
    final sec = int.tryParse(clean.substring(0, 8), radix: 16);
    if (sec == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(sec * 1000);
  }
}
