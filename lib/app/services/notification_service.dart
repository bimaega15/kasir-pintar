import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import '../data/models/product_model.dart';

class NotificationService extends GetxService {
  static const _channelId = 'low_stock_channel';
  static const _channelName = 'Stok Hampir Habis';
  static const int lowStockId = 1001;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<NotificationService> init() async {
    if (!isSupported) return this;

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

    // Buat notification channel untuk Android
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

    // Minta izin notifikasi Android 13+ / iOS
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true);

    _initialized = true;
    return this;
  }

  Future<void> showLowStockNotification(List<ProductModel> products) async {
    if (!_initialized || products.isEmpty) return;

    final title = '⚠️ Stok Hampir Habis (${products.length} produk)';
    final body = products.length == 1
        ? '${products.first.emoji} ${products.first.name}  —  Stok: ${products.first.stock}'
        : products
            .take(3)
            .map((p) => '${p.emoji} ${p.name} (${p.stock})')
            .join(', ');

    await _plugin.show(
      lowStockId,
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

  /// Hapus notifikasi stok rendah (dipanggil saat stok sudah aman)
  Future<void> cancelLowStockNotification() async {
    if (!_initialized) return;
    await _plugin.cancel(lowStockId);
  }
}
