// check_version_service.dart
//
// Auto-check update satu kali per sesi dari HomeController.onReady().
// Manual check dari SettingsView.
//
// ─── Format JSON endpoint ─────────────────────────────────────────────────────
// GET _versionCheckUrl harus mengembalikan:
// {
//   "version": "1.0.2",
//   "needUpdate": true,
//   "changelog": "- Fitur baru A\n- Perbaikan bug B"
// }
//
// ─── AndroidManifest.xml ─────────────────────────────────────────────────────
// Sudah ditambahkan: INTERNET, POST_NOTIFICATIONS, REQUEST_INSTALL_PACKAGES,
// dan FileProvider (lihat file_paths.xml).
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

// ─── Konfigurasi — ganti sesuai server Anda ──────────────────────────────────

/// URL endpoint JSON info versi.
/// Contoh response: {"version":"1.0.2","needUpdate":true,"changelog":"..."}
const _versionCheckUrl =
    'https://your-server.com/api/kasir-pintar/version.json';

/// URL download file APK terbaru.
const _apkDownloadUrl =
    'https://your-server.com/releases/kasir_pintar_latest.apk';

// ─── Konstanta notifikasi ─────────────────────────────────────────────────────

const _channelId = 'kasirUpdateChannel';
const _channelName = 'Unduh Update';
const _progressNotifId = 3001;
const _errorNotifId = 3002;

// ─── Model ────────────────────────────────────────────────────────────────────

class AppVersionInfo {
  final bool needUpdate;
  final String latestVersion;
  final String changelog;

  const AppVersionInfo({
    required this.needUpdate,
    required this.latestVersion,
    required this.changelog,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      needUpdate: json['needUpdate'] as bool? ?? false,
      latestVersion: json['version'] as String? ?? '',
      changelog: json['changelog'] as String? ?? '',
    );
  }
}

// ─── Service ──────────────────────────────────────────────────────────────────

class CheckVersionService {
  CheckVersionService._();

  /// Flag sesi — reset otomatis saat proses app mati.
  static bool _checkedThisSession = false;

  static final _notif = FlutterLocalNotificationsPlugin();
  static bool _notifInitialized = false;

  // ─── Public API ─────────────────────────────────────────────────────────────

  /// Auto-check sekali per sesi. Panggil dari HomeController.onReady().
  /// Diam-diam jika tidak ada update atau server tidak terjangkau.
  static Future<void> checkOnce(BuildContext context) async {
    if (_checkedThisSession) return;
    _checkedThisSession = true;
    await _doCheck(context, silent: true);
  }

  /// Manual check dari Settings. Selalu beri feedback ke user.
  static Future<void> checkManual(BuildContext context) async {
    await _doCheck(context, silent: false);
  }

  // ─── Private helpers ────────────────────────────────────────────────────────

  static Future<void> _doCheck(
    BuildContext context, {
    required bool silent,
  }) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final versionInfo = await _fetchVersionInfo();

      if (versionInfo == null) {
        if (!silent && context.mounted) {
          _showSnackbar(
            context,
            'Tidak dapat memeriksa update. Periksa koneksi internet.',
            isError: true,
          );
        }
        return;
      }

      if (!versionInfo.needUpdate) {
        if (!silent && context.mounted) {
          _showSnackbar(
            context,
            'Aplikasi sudah versi terbaru (v$currentVersion)',
            isError: false,
          );
        }
        return;
      }

      if (!context.mounted) return;

      final proceed = await showDialog<bool>(
        context: context,
        barrierDismissible: !silent,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.system_update_rounded, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Update Tersedia v${versionInfo.latestVersion}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Versi saat ini: v$currentVersion'),
              Text('Versi terbaru: v${versionInfo.latestVersion}'),
              if (versionInfo.changelog.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Yang Baru:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  versionInfo.changelog,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Nanti'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Update Sekarang'),
            ),
          ],
        ),
      );

      if (proceed != true || !context.mounted) return;
      if (!Platform.isAndroid) return;

      // Android 8+ — izin install unknown apps
      if (!await Permission.requestInstallPackages.isGranted) {
        await Permission.requestInstallPackages.request();
        if (!await Permission.requestInstallPackages.isGranted) {
          if (context.mounted) {
            _showSnackbar(
              context,
              'Aktifkan "Install from Unknown Sources" di Settings untuk melanjutkan.',
              isError: true,
              duration: const Duration(seconds: 5),
            );
          }
          return;
        }
      }

      // Android 13+ — izin notifikasi
      if (!await Permission.notification.isGranted) {
        await Permission.notification.request();
      }

      await _initNotifications();
      // Tidak di-await → download di background, tidak memblok UI
      _downloadAndInstallApk(_apkDownloadUrl);
    } catch (e) {
      debugPrint('[CheckVersionService] error: $e');
    }
  }

  static Future<AppVersionInfo?> _fetchVersionInfo() async {
    try {
      final response = await Dio().get<dynamic>(
        _versionCheckUrl,
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
          responseType: ResponseType.json,
        ),
      );
      
      if (response.statusCode == 200 && response.data != null) {
        dynamic data = response.data;

        // Server returned raw String (wrong Content-Type) — try to parse
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (_) {
            // Not valid JSON (e.g. server returned "OK" or plain text)
            return null;
          }
        }

        if (data is! Map<String, dynamic>) {
          return null;
        }

        if (data.isEmpty) return null;
        return AppVersionInfo.fromJson(data);
      }
    } catch (e) {
      debugPrint('[CheckVersionService] fetchVersionInfo error: $e');
    }
    return null;
  }

  static Future<void> _downloadAndInstallApk(String url) async {
    try {
      final dir = await getTemporaryDirectory();
      final apkPath = '${dir.path}/kasir_pintar_update.apk';
      final apkFile = File(apkPath);
      if (await apkFile.exists()) await apkFile.delete();

      await _showProgressNotification('Mempersiapkan unduhan...', 0, true);

      int lastProgress = -1;
      await Dio().download(
        url,
        apkPath,
        onReceiveProgress: (received, total) {
          if (total <= 0) return;
          final progress = ((received / total) * 100).toInt();
          if (progress != lastProgress) {
            lastProgress = progress;
            _showProgressNotification(
              '${_formatBytes(received)} / ${_formatBytes(total)}',
              progress,
              false,
            );
          }
        },
        options: Options(receiveTimeout: const Duration(minutes: 15)),
      );

      await _notif.cancel(_progressNotifId);
      await OpenFilex.open(
        apkPath,
        type: 'application/vnd.android.package-archive',
      );
    } catch (e) {
      debugPrint('[CheckVersionService] download error: $e');
      await _notif.cancel(_progressNotifId);
      await _showErrorNotification('Unduhan gagal: ${e.toString()}');
    }
  }

  static Future<void> _initNotifications() async {
    if (_notifInitialized) return;
    _notifInitialized = true;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _notif.initialize(settings);

    final androidPlugin = _notif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        importance: Importance.low,
        enableVibration: false,
        playSound: false,
      ),
    );
  }

  static Future<void> _showProgressNotification(
    String text,
    int progress,
    bool indeterminate,
  ) async {
    await _notif.show(
      _progressNotifId,
      'Mengunduh Update Kasir Pintar',
      text,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.low,
          priority: Priority.low,
          onlyAlertOnce: true,
          showProgress: true,
          maxProgress: 100,
          progress: progress,
          indeterminate: indeterminate,
          ongoing: true,
          autoCancel: false,
          enableVibration: false,
          playSound: false,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  static Future<void> _showErrorNotification(String message) async {
    await _notif.show(
      _errorNotifId,
      'Unduhan Gagal',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.low,
          priority: Priority.low,
          enableVibration: false,
          playSound: false,
          autoCancel: true,
        ),
      ),
    );
  }

  static void _showSnackbar(
    BuildContext context,
    String message, {
    required bool isError,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor:
            isError ? Colors.red.shade600 : Colors.green.shade600,
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
