import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../services/license_service.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../routes/app_routes.dart';

class LicenseGateView extends StatefulWidget {
  const LicenseGateView({super.key});

  @override
  State<LicenseGateView> createState() => _LicenseGateViewState();
}

class _LicenseGateViewState extends State<LicenseGateView> {
  final _keyCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await Get.find<LicenseService>().activate(_keyCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
    } else {
      Get.offAllNamed(AppRoutes.main);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLockBadge(),
                const SizedBox(height: 24),
                _buildTitle(),
                const SizedBox(height: 32),
                _buildActivationCard(),
                const SizedBox(height: 20),
                _buildContactCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockBadge() {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                Colors.red.shade800.withValues(alpha: 0.4),
                Colors.red.shade900.withValues(alpha: 0.1),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.red.shade700, width: 2),
          ),
          child: Icon(Icons.lock_rounded, color: Colors.red.shade400, size: 44),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.shade900.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade800),
          ),
          child: Text(
            'MASA TRIAL BERAKHIR',
            style: TextStyle(
              color: Colors.red.shade400,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return const Column(
      children: [
        Text(
          'Aplikasi Terkunci',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Masa trial 7 hari Anda telah berakhir.\n'
          'Masukkan kunci lisensi untuk melanjutkan menggunakan\nKasir Pintar MB.',
          style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13, height: 1.6),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActivationCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.vpn_key_rounded, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'Aktivasi Lisensi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _keyCtrl,
            inputFormatters: [_LicenseKeyFormatter()],
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.5,
            ),
            decoration: InputDecoration(
              hintText: 'XXXXX-XXXXX-XXXXX-XXXXX',
              hintStyle: TextStyle(
                color: Colors.grey.shade700,
                letterSpacing: 2,
                fontSize: 14,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.07),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              suffixIcon: IconButton(
                tooltip: 'Tempel dari clipboard',
                icon: const Icon(Icons.paste_rounded, color: Colors.white38, size: 20),
                onPressed: () async {
                  final data = await Clipboard.getData('text/plain');
                  if (data?.text != null) _keyCtrl.text = data!.text!;
                },
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade400, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade400, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _activate,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 18),
              label: Text(
                _loading ? 'Memverifikasi...' : 'Aktivasi Sekarang',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        children: [
          Text(
            'Belum punya lisensi?',
            style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Hubungi developer untuk mendapatkan kunci lisensi.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _contactChip(Icons.phone_rounded, '082277506232'),
              const SizedBox(width: 8),
              _contactChip(Icons.email_outlined, 'bimaega15@gmail.com'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contactChip(IconData icon, String label) {
    return GestureDetector(
      onTap: () => Clipboard.setData(ClipboardData(text: label)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white38, size: 13),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

/// Auto-formats input as XXXXX-XXXXX-XXXXX-XXXXX (hex only, max 20 chars)
class _LicenseKeyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue next) {
    final raw =
        next.text.toUpperCase().replaceAll(RegExp(r'[^0-9A-F]'), '');
    final limited = raw.length > 20 ? raw.substring(0, 20) : raw;
    final buf = StringBuffer();
    for (int i = 0; i < limited.length; i++) {
      if (i > 0 && i % 5 == 0) buf.write('-');
      buf.write(limited[i]);
    }
    final out = buf.toString();
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}
