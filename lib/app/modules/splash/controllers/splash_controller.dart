import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import '../../../data/providers/storage_provider.dart';
import '../../../routes/app_routes.dart';

class SplashController extends GetxController {
  final _db = Get.find<DatabaseProvider>();

  @override
  void onInit() {
    super.onInit();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));

    // Check if user has existing credentials (local login)
    final savedUsername = await _db.getSetting('app_username') ?? '';
    final savedPassword = await _db.getSetting('app_password') ?? '';

    if (savedUsername.isNotEmpty && savedPassword.isNotEmpty) {
      // User has local credentials, go to main app
      Get.offAllNamed(AppRoutes.main);
      return;
    }

    // Check if user has Firebase session (Google login) — only on supported platforms
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          Get.offAllNamed(AppRoutes.main);
          return;
        }
      } catch (_) {
        // Firebase not initialized, skip
      }
    }

    // No session found, go to login
    Get.offAllNamed(AppRoutes.login);
  }
}
