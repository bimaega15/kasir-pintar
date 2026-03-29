import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:local_notifier/local_notifier.dart';
import '../data/models/bahan_baku_model.dart';
import '../data/models/product_model.dart';

class NotificationService extends GetxService {
  static const _channelId = 'low_stock_channel';
  static const _channelName = 'Stok Hampir Habis';
  static const int lowStockProductId = 1001;
  static const int lowStockBahanBakuId = 1002;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _desktopNotificationsSupported = false;

  static bool get _isMobile =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  static bool get isSupported => _isMobile || _isDesktop;

  Future<NotificationService> init() async {
    if (!isSupported) return this;

    try {
      if (_isMobile) {
        await _initMobile();
        _initialized = true;
      } else if (_isDesktop) {
        await _initDesktop();
        _initialized = true;
      }
    } catch (e) {
      debugPrint('❌ NotificationService initialization failed: $e');
      _initialized = false;
    }
    return this;
  }

  // ── Mobile init (Android / iOS) ───────────────────────────────────────

  Future<void> _initMobile() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Peringatan produk dengan stok hampir habis',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true);
  }

  // ── Desktop init (Windows / macOS / Linux) ────────────────────────────

  Future<void> _initDesktop() async {
    try {
      await localNotifier.setup(appName: 'Kasir Pintar Sasbim');
      _desktopNotificationsSupported = true;
      debugPrint('✓ Desktop notifications initialized successfully');
    } catch (e) {
      debugPrint('⚠️ Desktop notifications not available: $e');
      _desktopNotificationsSupported = false;
    }
  }

  // ── Produk low stock notification ─────────────────────────────────────

  Future<void> showLowStockNotification(List<ProductModel> products) async {
    if (!_initialized || products.isEmpty) return;

    final title = 'Stok Hampir Habis (${products.length} produk)';
    final body = products.length == 1
        ? '${products.first.emoji} ${products.first.name}  —  Stok: ${products.first.stock}'
        : products
            .take(3)
            .map((p) => '${p.emoji} ${p.name} (${p.stock})')
            .join(', ');

    if (_isMobile) {
      await _showMobile(lowStockProductId, title, body);
    } else if (_isDesktop) {
      _showDesktop(title, body);
    }
  }

  Future<void> cancelLowStockNotification() async {
    if (!_initialized) return;
    if (_isMobile) {
      await _plugin.cancel(lowStockProductId);
    }
  }

  // ── Bahan baku low stock notification ─────────────────────────────────

  Future<void> showLowStockBahanBakuNotification(
      List<BahanBakuModel> items) async {
    if (!_initialized || items.isEmpty) return;

    final title = 'Bahan Baku Menipis (${items.length} item)';
    final body = items.length == 1
        ? '${items.first.emoji} ${items.first.name}  —  '
            'Stok: ${_fmtQty(items.first.stock)} ${items.first.unit} '
            '(min: ${_fmtQty(items.first.minStock)})'
        : items
            .take(3)
            .map((b) =>
                '${b.emoji} ${b.name} (${_fmtQty(b.stock)} ${b.unit})')
            .join(', ');

    if (_isMobile) {
      await _showMobile(lowStockBahanBakuId, title, body);
    } else if (_isDesktop) {
      _showDesktop(title, body);
    }
  }

  Future<void> cancelLowStockBahanBakuNotification() async {
    if (!_initialized) return;
    if (_isMobile) {
      await _plugin.cancel(lowStockBahanBakuId);
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────

  Future<void> _showMobile(int id, String title, String body) async {
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: const AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Peringatan produk dengan stok hampir habis',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: false,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: false,
        ),
      ),
    );
  }

  void _showDesktop(String title, String body) {
    if (!_desktopNotificationsSupported) {
      debugPrint('ℹ️ Desktop notifications not available on this platform');
      return;
    }

    try {
      final notification = LocalNotification(
        title: title,
        body: body,
      );
      notification.show();
    } catch (e) {
      debugPrint('⚠️ Failed to show desktop notification: $e');
    }
  }

  String _fmtQty(double qty) =>
      qty == qty.truncateToDouble() ? qty.toInt().toString() : qty.toStringAsFixed(1);
}
