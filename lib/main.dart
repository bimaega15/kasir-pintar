import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'app/bindings/initial_binding.dart';
import 'app/data/providers/storage_provider.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/services/notification_service.dart';
import 'app/services/printer_service.dart';
import 'app/utils/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase (hanya pada platform yang didukung)
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      print('Error initializing Firebase: $e');
    }
  }

  // Suppress known Flutter errors
  // See: https://github.com/flutter/flutter/issues/93283
  FlutterError.onError = (details) {
    final msg = details.exceptionAsString();
    
    // Known Flutter Windows keyboard tracking bug — safe to ignore
    if (msg.contains('_pressedKeys.containsKey') ||
        msg.contains('KeyDownEvent is dispatched') ||
        msg.contains('KeyUpEvent is dispatched') ||
        msg.contains('_keysPressed.isNotEmpty') ||
        msg.contains('no keys are in keysPressed')) {
      return;
    }
    
    // Native channel empty response — safe to ignore
    if (msg.contains('Unable to parse JSON message') ||
        msg.contains('The document is empty')) {
      return;
    }
    
    FlutterError.presentError(details);
  };

  // Inisialisasi sqflite untuk platform desktop (Windows, Linux, macOS)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Inisialisasi locale Indonesia untuk formatting tanggal
  await initializeDateFormatting('id_ID');

  // Inisialisasi SQLite database
  await Get.putAsync<DatabaseProvider>(() => DatabaseProvider().init());

  // Inisialisasi PrinterService (Android only, non-blocking)
  Get.put<PrinterService>(PrinterService());

  // Inisialisasi NotificationService (Android & iOS)
  await Get.putAsync<NotificationService>(() => NotificationService().init());

  runApp(const KasirPintarApp());
}

class KasirPintarApp extends StatelessWidget {
  const KasirPintarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Kasir Pintar',
      theme: AppTheme.lightTheme,
      initialBinding: InitialBinding(),
      initialRoute: AppRoutes.splash,
      home: null,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
      locale: const Locale('id', 'ID'),
    );
  }
}
