import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
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
  String? _selectedPaket;

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
                const SizedBox(height: 20),
                _buildDeviceIdCard(),
                const SizedBox(height: 16),
                _buildPricingCards(),
                const SizedBox(height: 20),
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

  Widget _buildDeviceIdCard() {
    return Obx(() {
      final deviceId = Get.find<LicenseService>().deviceIdDisplay.value;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Icon(Icons.fingerprint_rounded, color: Colors.grey.shade500, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ID Perangkat',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    deviceId.isEmpty ? 'Memuat...' : deviceId,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Salin ID Perangkat',
              icon: Icon(Icons.copy_rounded, color: Colors.grey.shade500, size: 18),
              onPressed: deviceId.isEmpty
                  ? null
                  : () {
                      Clipboard.setData(ClipboardData(text: deviceId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ID Perangkat disalin'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
            ),
          ],
        ),
      );
    });
  }

  void _openOrderDialog(String paket, String harga) {
    final namaCtrl = TextEditingController();
    final hpCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.chat_rounded, color: Colors.green.shade400, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Hubungi Kami',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paket dipilih: $paket ($harga)',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              _dialogField(namaCtrl, 'Nama Pelanggan', Icons.person_rounded),
              const SizedBox(height: 10),
              _dialogField(hpCtrl, 'Nomor Handphone', Icons.phone_rounded,
                  type: TextInputType.phone),
              const SizedBox(height: 10),
              _dialogField(emailCtrl, 'Email', Icons.email_rounded,
                  type: TextInputType.emailAddress),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child:
                Text('Batal', style: TextStyle(color: Colors.grey.shade500)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final nama = namaCtrl.text.trim();
              final hp = hpCtrl.text.trim();
              final email = emailCtrl.text.trim();
              if (nama.isEmpty || hp.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Nama dan nomor HP wajib diisi'),
                  backgroundColor: Colors.red,
                ));
                return;
              }
              Navigator.of(ctx).pop();
              final deviceId = Get.find<LicenseService>().deviceIdDisplay.value;
              final msg = Uri.encodeComponent(
                'Hai kak, saya ingin memperpanjang aplikasi Kasir Pintar MB nya '
                'dengan paket *$paket ($harga)*\n\n'
                'Nama Pelanggan: $nama\n'
                'Nomor Handphone: $hp\n'
                'Email: ${email.isEmpty ? '-' : email}\n'
                'Paket: $paket ($harga)\n'
                'ID Perangkat: $deviceId',
              );
              final url = Uri.parse('https://wa.me/62${_stripLeadingZero('082277506232')}?text=$msg');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            icon: Icon(Icons.chat_rounded, color: Colors.white, size: 18),
            label: const Text('Kirim via WhatsApp',
                style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
          ),
        ],
      ),
    ).whenComplete(() {
      namaCtrl.dispose();
      hpCtrl.dispose();
      emailCtrl.dispose();
    });
  }

  String _stripLeadingZero(String phone) =>
      phone.startsWith('0') ? phone.substring(1) : phone;

  Widget _dialogField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 18),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildPricingCards() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Text(
            'Pilih Paket Langganan',
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _pricingChip(
                label: 'Mingguan',
                price: 'Rp 15.000',
                period: '/ minggu',
                icon: Icons.calendar_view_week_rounded,
                highlight: false,
              ),
              const SizedBox(width: 8),
              _pricingChip(
                label: 'Bulanan',
                price: 'Rp 50.000',
                period: '/ bulan',
                icon: Icons.calendar_month_rounded,
                highlight: true,
              ),
              const SizedBox(width: 8),
              _pricingChip(
                label: 'Tahunan',
                price: 'Rp 500.000',
                period: '/ tahun',
                icon: Icons.workspace_premium_rounded,
                highlight: false,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Ketuk paket untuk menghubungi kami',
            style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _pricingChip({
    required String label,
    required String price,
    required String period,
    required IconData icon,
    required bool highlight,
  }) {
    final selected = _selectedPaket == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedPaket = label);
          _openOrderDialog(label, price);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.25)
                : highlight
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : highlight
                      ? AppColors.primary.withValues(alpha: 0.6)
                      : Colors.white12,
              width: selected || highlight ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              if (highlight)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'POPULER',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8),
                  ),
                ),
              Icon(icon,
                  color: highlight || selected
                      ? AppColors.primary
                      : Colors.white38,
                  size: 22),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: highlight || selected
                      ? Colors.white
                      : Colors.grey.shade400,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                price,
                style: TextStyle(
                  color: highlight || selected
                      ? AppColors.primary
                      : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                period,
                style:
                    TextStyle(color: Colors.grey.shade600, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
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
