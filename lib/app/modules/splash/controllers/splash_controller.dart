import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import '../../../data/providers/storage_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../services/user_session.dart';

class SplashController extends GetxController {
  final _db = Get.find<DatabaseProvider>();

  @override
  void onInit() {
    super.onInit();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));

    // 1. Cek sesi lokal aktif (login terakhir yang belum logout)
    final sessionUsername = await _db.getSetting('session_username') ?? '';
    final sessionRole = await _db.getSetting('session_role') ?? '';

    if (sessionUsername.isNotEmpty) {
      // Pulihkan UserSession agar hak akses langsung aktif
      Get.find<UserSession>().setSession(
        username: sessionUsername,
        role: sessionRole.isNotEmpty ? sessionRole : 'admin',
      );
      Get.offAllNamed(AppRoutes.main);
      return;
    }

    // 2. Cek apakah admin sudah pernah dibuat (setup pertama kali)
    final adminUsername = await _db.getSetting('app_username') ?? '';
    if (adminUsername.isEmpty) {
      // Belum ada akun admin → arahkan ke halaman setup
      Get.offAllNamed(AppRoutes.setup);
      return;
    }

    // 3. Cek sesi Firebase (Google login)
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          Get.find<UserSession>().setSession(
            username: currentUser.email ?? currentUser.displayName ?? '',
            role: 'admin',
          );
          await _db.setSetting('session_username', currentUser.uid);
          await _db.setSetting('session_role', 'admin');
          Get.offAllNamed(AppRoutes.main);
          return;
        }
      } catch (_) {
        // Firebase not initialized, skip
      }
    }

    // 4. Tidak ada sesi → ke halaman login
    Get.offAllNamed(AppRoutes.login);
  }
}
