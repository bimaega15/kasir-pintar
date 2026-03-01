import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/login_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/constants/app_colors.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 64),
              _buildLogo(),
              const SizedBox(height: 32),
              _buildTitle(),
              const SizedBox(height: 36),
              _buildCard(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Text('🏪', style: TextStyle(fontSize: 44)),
      ),
    );
  }

  Widget _buildTitle() {
    return const Column(
      children: [
        Text(
          'Kasir Pintar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Masuk untuk melanjutkan',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildField(
            label: 'Username',
            controller: controller.loginUsernameCtrl,
            hint: 'Masukkan username',
            icon: Icons.person_outline_rounded,
            obscure: false,
            visibleObs: null,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 18),
          Obx(() => _buildField(
                label: 'Password',
                controller: controller.loginPasswordCtrl,
                hint: 'Masukkan password',
                icon: Icons.lock_outline_rounded,
                obscure: !controller.isLoginPasswordVisible.value,
                visibleObs: controller.isLoginPasswordVisible,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => controller.login(),
              )),
          // Lupa Password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: controller.forgotPassword,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Lupa Password?',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Tombol Masuk
          Obx(() => SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      controller.isLoginLoading.value ? null : controller.login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: controller.isLoginLoading.value
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Masuk',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              )),
          const SizedBox(height: 24),
          // Divider ATAU
          Row(
            children: [
              const Expanded(child: Divider(thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'ATAU',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Expanded(child: Divider(thickness: 1)),
            ],
          ),
          const SizedBox(height: 16),
          // Tombol Login Google
          Obx(() => SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: controller.isGoogleLoading.value
                      ? null
                      : controller.signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: Colors.white,
                  ),
                  child: controller.isGoogleLoading.value
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Google G logo menggunakan RichText
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const _GoogleIcon(),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Lanjutkan dengan Google',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF3C4043),
                              ),
                            ),
                          ],
                        ),
                ),
              )),
          const SizedBox(height: 20),
          // Link Daftar Akun
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Belum punya akun? ',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              GestureDetector(
                onTap: () => Get.offAllNamed(AppRoutes.setup),
                child: const Text(
                  'Daftar',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool obscure,
    required RxBool? visibleObs,
    TextInputAction textInputAction = TextInputAction.next,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            suffixIcon: visibleObs != null
                ? GestureDetector(
                    onTap: () => visibleObs.toggle(),
                    child: Icon(
                      visibleObs.value
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  )
                : null,
            filled: true,
            fillColor: AppColors.background,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Google G Logo (4-warna) ───────────────────────────────────────────────────
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(22, 22),
      painter: _GoogleGPainter(),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final stroke = size.width * 0.19;
    final arcRect = Rect.fromCircle(
      center: Offset(cx, cy),
      radius: r - stroke / 2,
    );

    Paint arc(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // 4 busur Google: Biru, Merah, Kuning, Hijau
    canvas.drawArc(arcRect, -math.pi / 2, math.pi * 0.55, false,
        arc(const Color(0xFF4285F4))); // biru (atas→kanan)
    canvas.drawArc(arcRect, math.pi * 0.05, math.pi * 0.50, false,
        arc(const Color(0xFFEA4335))); // merah (kanan→bawah)
    canvas.drawArc(arcRect, math.pi * 0.55, math.pi * 0.50, false,
        arc(const Color(0xFFFBBC05))); // kuning (bawah→kiri)
    canvas.drawArc(arcRect, math.pi * 1.05, math.pi * 0.45, false,
        arc(const Color(0xFF34A853))); // hijau (kiri→atas)

    // Horizontal bar (bagian "G")
    canvas.drawRect(
      Rect.fromLTRB(cx, cy - stroke / 2, size.width - 1, cy + stroke / 2),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
