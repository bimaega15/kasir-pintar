import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../data/providers/storage_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/constants/app_colors.dart';

class LoginController extends GetxController {
  final _db = Get.find<DatabaseProvider>();

  // ── Login fields ─────────────────────────────────────────────────────────
  final loginUsernameCtrl = TextEditingController();
  final loginPasswordCtrl = TextEditingController();
  final isLoginPasswordVisible = false.obs;
  final isLoginLoading = false.obs;

  // ── Setup fields ──────────────────────────────────────────────────────────
  final setupUsernameCtrl = TextEditingController();
  final setupPasswordCtrl = TextEditingController();
  final setupConfirmCtrl = TextEditingController();
  final isSetupPasswordVisible = false.obs;
  final isSetupConfirmVisible = false.obs;
  final isSetupLoading = false.obs;

  @override
  void onClose() {
    loginUsernameCtrl.dispose();
    loginPasswordCtrl.dispose();
    setupUsernameCtrl.dispose();
    setupPasswordCtrl.dispose();
    setupConfirmCtrl.dispose();
    super.onClose();
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<void> login() async {
    final username = loginUsernameCtrl.text.trim();
    final password = loginPasswordCtrl.text;

    if (username.isEmpty || password.isEmpty) {
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
      final savedUsername = await _db.getSetting('app_username') ?? '';
      final savedPassword = await _db.getSetting('app_password') ?? '';

      if (username == savedUsername && password == savedPassword) {
        Get.offAllNamed(AppRoutes.main);
      } else {
        Get.snackbar(
          'Login Gagal',
          'Username atau password salah',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          margin: const EdgeInsets.all(16),
        );
      }
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

  Future<void> setupAccount() async {
    final username = setupUsernameCtrl.text.trim();
    final password = setupPasswordCtrl.text;
    final confirm = setupConfirmCtrl.text;

    if (username.isEmpty || password.isEmpty || confirm.isEmpty) {
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

    if (username.length < 3) {
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

    isSetupLoading.value = true;
    try {
      await _db.setSetting('app_username', username);
      await _db.setSetting('app_password', password);

      Get.snackbar(
        'Berhasil',
        'Akun berhasil dibuat. Silakan login.',
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
