import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/license_service.dart';
import '../../../utils/constants/app_colors.dart';

/// Developer-only license key generator.
/// Accessible via 7 taps on the app logo in the About page.
/// Protected by a developer PIN.
class LicenseGeneratorView extends StatefulWidget {
  const LicenseGeneratorView({super.key});

  @override
  State<LicenseGeneratorView> createState() => _LicenseGeneratorViewState();
}

class _LicenseGeneratorViewState extends State<LicenseGeneratorView> {
  // Developer PIN — change this to your preferred PIN
  static const _devPin = 'MB2025';

  bool _unlocked = false;
  final _pinCtrl = TextEditingController();
  String? _pinError;

  // Generator state
  int _selectedDays = 30;
  final _customDaysCtrl = TextEditingController(text: '30');
  bool _useCustom = false;
  String? _generatedKey;
  DateTime? _expiryDate;
  bool _copied = false;

  static const _presets = [
    {'label': '7 Hari', 'days': 7},
    {'label': '30 Hari', 'days': 30},
    {'label': '3 Bulan', 'days': 90},
    {'label': '6 Bulan', 'days': 180},
    {'label': '1 Tahun', 'days': 365},
  ];

  @override
  void dispose() {
    _pinCtrl.dispose();
    _customDaysCtrl.dispose();
    super.dispose();
  }

  void _verifyPin() {
    if (_pinCtrl.text.trim() == _devPin) {
      setState(() {
        _unlocked = true;
        _pinError = null;
      });
    } else {
      setState(() => _pinError = 'PIN salah');
    }
  }

  void _generate() {
    int days = _useCustom
        ? (int.tryParse(_customDaysCtrl.text) ?? 30)
        : _selectedDays;
    if (days <= 0) days = 1;

    final key = LicenseService.generateKey(days);
    final expiry = LicenseService.expiryFromKey(key);
    setState(() {
      _generatedKey = key;
      _expiryDate = expiry;
      _copied = false;
    });
  }

  Future<void> _copyKey() async {
    if (_generatedKey == null) return;
    await Clipboard.setData(ClipboardData(text: _generatedKey!));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.developer_mode_rounded, size: 20),
            SizedBox(width: 8),
            Text('License Generator', style: TextStyle(fontSize: 16)),
          ],
        ),
        elevation: 0,
      ),
      body: _unlocked ? _buildGenerator() : _buildPinGate(),
    );
  }

  Widget _buildPinGate() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.admin_panel_settings_rounded,
                    color: AppColors.primary, size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'Developer Access',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Masukkan PIN developer untuk mengakses\ntool generate lisensi.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _pinCtrl,
                obscureText: true,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    letterSpacing: 8,
                    fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '••••••',
                  hintStyle:
                      TextStyle(color: Colors.grey.shade700, letterSpacing: 8),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.07),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  errorText: _pinError,
                  errorStyle: const TextStyle(color: Colors.redAccent),
                ),
                onSubmitted: (_) => _verifyPin(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _verifyPin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Masuk',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenerator() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Duration selector
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Durasi Lisensi',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._presets.map((p) {
                      final days = p['days'] as int;
                      final isSelected = !_useCustom && _selectedDays == days;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _useCustom = false;
                          _selectedDays = days;
                          _generatedKey = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white24,
                            ),
                          ),
                          child: Text(
                            p['label'] as String,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }),
                    GestureDetector(
                      onTap: () => setState(() {
                        _useCustom = true;
                        _generatedKey = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: _useCustom
                              ? Colors.orange.shade800
                              : Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _useCustom
                                ? Colors.orange.shade600
                                : Colors.white24,
                          ),
                        ),
                        child: Text(
                          'Custom',
                          style: TextStyle(
                            color: _useCustom ? Colors.white : Colors.white70,
                            fontWeight: _useCustom
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_useCustom) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text('Jumlah hari: ',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: _customDaysCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('hari',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Generate button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _generate,
              icon: const Icon(Icons.generating_tokens_rounded, size: 20),
              label: const Text('Generate Kunci Lisensi',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          // Generated key result
          if (_generatedKey != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade900.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.shade800),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: Colors.green.shade400, size: 18),
                      const SizedBox(width: 8),
                      const Text('Kunci Berhasil Dibuat',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _generatedKey!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_expiryDate != null)
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            color: Colors.white38, size: 13),
                        const SizedBox(width: 6),
                        Text(
                          'Berlaku hingga: '
                          '${_expiryDate!.day.toString().padLeft(2, '0')}/'
                          '${_expiryDate!.month.toString().padLeft(2, '0')}/'
                          '${_expiryDate!.year}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _copyKey,
                      icon: Icon(
                          _copied ? Icons.check_rounded : Icons.copy_rounded,
                          size: 18),
                      label: Text(_copied ? 'Tersalin!' : 'Salin Kunci'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _copied
                            ? Colors.green.shade700
                            : Colors.white.withValues(alpha: 0.15),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade900.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade800),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange.shade400, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Jaga kerahasiaan kunci ini. '
                      'Berikan hanya kepada pelanggan yang telah membayar.',
                      style:
                          TextStyle(color: Colors.white54, fontSize: 11, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
