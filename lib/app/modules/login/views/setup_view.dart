import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/login_controller.dart';
import '../../../utils/constants/app_colors.dart';

class SetupView extends StatefulWidget {
  const SetupView({super.key});

  @override
  State<SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends State<SetupView> {
  late TextEditingController setupUsernameCtrl;
  late TextEditingController setupPasswordCtrl;
  late TextEditingController setupConfirmCtrl;
  late RxBool isSetupPasswordVisible;
  late RxBool isSetupConfirmVisible;
  late LoginController controller;

  @override
  void initState() {
    super.initState();
    setupUsernameCtrl = TextEditingController();
    setupPasswordCtrl = TextEditingController();
    setupConfirmCtrl = TextEditingController();
    isSetupPasswordVisible = false.obs;
    isSetupConfirmVisible = false.obs;
    controller = Get.find<LoginController>();
  }

  @override
  void dispose() {
    setupUsernameCtrl.dispose();
    setupPasswordCtrl.dispose();
    setupConfirmCtrl.dispose();
    super.dispose();
  }

  void _setupAccount() {
    controller.setupAccount(
      username: setupUsernameCtrl.text,
      password: setupPasswordCtrl.text,
      confirm: setupConfirmCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 48),
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
          'Buat Akun',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Atur kredensial pertama kali untuk masuk',
          style: TextStyle(color: Colors.white70, fontSize: 13),
          textAlign: TextAlign.center,
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
            controller: setupUsernameCtrl,
            hint: 'Masukkan username',
            icon: Icons.person_outline_rounded,
            obscure: false,
            visibleObs: null,
          ),
          const SizedBox(height: 18),
          Obx(() => _buildField(
                label: 'Password',
                controller: setupPasswordCtrl,
                hint: 'Masukkan password',
                icon: Icons.lock_outline_rounded,
                obscure: !isSetupPasswordVisible.value,
                visibleObs: isSetupPasswordVisible,
              )),
          const SizedBox(height: 18),
          Obx(() => _buildField(
                label: 'Konfirmasi Password',
                controller: setupConfirmCtrl,
                hint: 'Ulangi password',
                icon: Icons.lock_outline_rounded,
                obscure: !isSetupConfirmVisible.value,
                visibleObs: isSetupConfirmVisible,
              )),
          const SizedBox(height: 28),
          Obx(() => SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: controller.isSetupLoading.value
                      ? null
                      : _setupAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: controller.isSetupLoading.value
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Buat Akun',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              )),
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
    RxBool? visibleObs,
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
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
