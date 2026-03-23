import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../data/providers/storage_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../services/user_session.dart';
import '../../../utils/constants/app_colors.dart';

/// True only on platforms where google_sign_in has native support.
bool get _googleSignInSupported =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);

class LoginController extends GetxController {
  final _db = Get.find<DatabaseProvider>();

  // ── Login fields ─────────────────────────────────────────────────────────
  final isLoginPasswordVisible = false.obs;
  final isLoginLoading = false.obs;

  // ── Setup fields ──────────────────────────────────────────────────────────
  final isSetupPasswordVisible = false.obs;
  final isSetupConfirmVisible = false.obs;
  final isSetupLoading = false.obs;

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<void> login({required String username, required String password}) async {
    var trimmedUsername = username.trim();

    if (trimmedUsername.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Perhatian',
        'Username dan password wajib diisi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    isLoginLoading.value = true;
    try {
      // 1. Cek akun admin (disimpan di settings)
      final adminUsername = await _db.getSetting('app_username') ?? '';
      final adminPassword = await _db.getSetting('app_password') ?? '';

      if (trimmedUsername == adminUsername && password == adminPassword) {
        await _db.setSetting('session_username', trimmedUsername);
        await _db.setSetting('session_role', 'admin');
        Get.find<UserSession>().setSession(username: trimmedUsername, role: 'admin');
        Get.offAllNamed(AppRoutes.main);
        return;
      }

      // 2. Cek akun kasir (disimpan di tabel app_users)
      final kasirUser = await _db.getAppUserByUsername(trimmedUsername);
      if (kasirUser != null && kasirUser['password'] == password) {
        final role = kasirUser['role'] as String? ?? 'kasir';
        await _db.setSetting('session_username', trimmedUsername);
        await _db.setSetting('session_role', role);
        Get.find<UserSession>().setSession(username: trimmedUsername, role: role);
        Get.offAllNamed(AppRoutes.main);
        return;
      }

      Get.snackbar(
        'Login Gagal',
        'Username atau password salah',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isLoginLoading.value = false;
    }
  }

  // ── Forgot Password ───────────────────────────────────────────────────────

  void forgotPassword() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock_reset_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Reset Password'),
          ],
        ),
        content: const Text(
          'Untuk reset password, Anda perlu membuat ulang akun. '
          'Kredensial lama akan diganti dengan yang baru.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.offAllNamed(AppRoutes.setup);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Buat Ulang Akun'),
          ),
        ],
      ),
    );
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────

  final isGoogleLoading = false.obs;
  final _googleSignIn = GoogleSignIn();

  Future<void> signInWithGoogle() async {
    if (!_googleSignInSupported) {
      Get.snackbar(
        'Tidak Tersedia',
        'Login Google hanya tersedia di Android dan iOS.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        margin: const EdgeInsets.all(16),
      );
      return;
    }
    isGoogleLoading.value = true;
    try {
      // Paksa pilih akun setiap kali (bukan auto-login akun terakhir)
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User membatalkan pemilihan akun
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      Get.offAllNamed(AppRoutes.main);
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'account-exists-with-different-credential' =>
          'Akun sudah terdaftar dengan metode login lain.',
        'network-request-failed' => 'Tidak ada koneksi internet.',
        _ => 'Login Google gagal: ${e.message}',
      };
      Get.snackbar(
        'Login Gagal',
        msg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar(
        'Login Gagal',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 10),
      );
    } finally {
      isGoogleLoading.value = false;
    }
  }

  // ── Setup ─────────────────────────────────────────────────────────────────

  Future<void> setupAccount({
    required String username,
    required String password,
    required String confirm,
  }) async {
    var trimmedUsername = username.trim();

    if (trimmedUsername.isEmpty || password.isEmpty || confirm.isEmpty) {
      Get.snackbar(
        'Perhatian',
        'Semua kolom wajib diisi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    if (trimmedUsername.length < 3) {
      Get.snackbar(
        'Perhatian',
        'Username minimal 3 karakter',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    if (password.length < 4) {
      Get.snackbar(
        'Perhatian',
        'Password minimal 4 karakter',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    if (password != confirm) {
      Get.snackbar(
        'Perhatian',
        'Konfirmasi password tidak cocok',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    // Cek apakah username sudah digunakan (admin atau kasir)
    final adminUsername = await _db.getSetting('app_username') ?? '';
    if (adminUsername.isNotEmpty && trimmedUsername == adminUsername) {
      Get.snackbar(
        'Username Sudah Digunakan',
        'Username "$trimmedUsername" sudah terdaftar sebagai Admin. Gunakan username lain.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      );
      return;
    }

    final kasirExists = await _db.appUsernameExists(trimmedUsername);
    if (kasirExists) {
      Get.snackbar(
        'Username Sudah Digunakan',
        'Username "$trimmedUsername" sudah terdaftar. Gunakan username lain.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      );
      return;
    }

    isSetupLoading.value = true;
    try {
      // Simpan sebagai akun kasir di tabel app_users
      await _db.insertAppUser(
        username: trimmedUsername,
        password: password,
        role: 'kasir',
      );

      Get.snackbar(
        'Akun Kasir Dibuat',
        'Akun "$trimmedUsername" berhasil dibuat sebagai Kasir.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        margin: const EdgeInsets.all(16),
      );

      await Future.delayed(const Duration(milliseconds: 800));
      Get.offAllNamed(AppRoutes.login);
    } finally {
      isSetupLoading.value = false;
    }
  }
}
