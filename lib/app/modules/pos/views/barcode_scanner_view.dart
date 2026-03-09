import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../utils/constants/app_colors.dart';

/// Layar scan QR/Barcode produk.
/// Hanya tersedia di Android & iOS. Mengembalikan [String] data QR via [Get.back].
class BarcodeScannerView extends StatefulWidget {
  const BarcodeScannerView({super.key});

  /// Platform guard — return true jika scan didukung
  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  @override
  State<BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeScannerView>
    with SingleTickerProviderStateMixin {
  MobileScannerController? _ctrl;
  bool _hasScanned = false;
  bool _torchOn = false;
  late AnimationController _lineAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
    _lineAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _lineAnim.dispose();
    _ctrl?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    _hasScanned = true;
    _ctrl?.stop();

    // Kembalikan data ke halaman pemanggil
    Navigator.of(context).pop(barcode.rawValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan QR / Barcode Produk'),
        actions: [
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flashlight_off_rounded : Icons.flashlight_on_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              _ctrl?.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Kamera
          MobileScanner(
            controller: _ctrl!,
            onDetect: _onDetect,
          ),

          // Overlay gelap + lubang kotak scan
          _ScanOverlay(),

          // Garis scan animasi
          Positioned.fill(
            child: Center(
              child: SizedBox(
                width: 260,
                height: 260,
                child: AnimatedBuilder(
                  animation: _lineAnim,
                  builder: (_, __) => Stack(
                    children: [
                      Positioned(
                        top: _lineAnim.value * 250,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.transparent,
                              AppColors.primary.withValues(alpha: 0.9),
                              Colors.transparent,
                            ]),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Label bawah
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  'Arahkan kamera ke QR Code produk',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'QR akan terbaca otomatis',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Tombol bawah: Galeri + Input manual
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library_rounded,
                      color: Colors.white70, size: 18),
                  label: const Text('Dari Galeri',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ),
                Container(
                  width: 1,
                  height: 16,
                  color: Colors.white30,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                TextButton.icon(
                  onPressed: _showManualInput,
                  icon: const Icon(Icons.keyboard_rounded,
                      color: Colors.white70, size: 18),
                  label: const Text('Input manual',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result == null || result.files.single.path == null) return;

      final path = result.files.single.path!;
      final capture = await _ctrl!.analyzeImage(path);
      final barcode = capture?.barcodes.firstOrNull;

      if (barcode?.rawValue != null) {
        if (mounted) Navigator.of(context).pop(barcode!.rawValue);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('QR Code tidak ditemukan di gambar ini'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (_) {
      // file_picker dibatalkan user — abaikan
    }
  }

  void _showManualInput() {
    final tc = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Input Kode Produk'),
        content: TextField(
          controller: tc,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Paste atau ketik data QR...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = tc.text.trim();
              if (val.isNotEmpty) {
                Navigator.pop(ctx);
                Navigator.of(context).pop(val);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Custom painter untuk overlay gelap dengan lubang scan di tengah
class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OverlayPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    const boxSize = 260.0;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rect = Rect.fromCenter(
        center: Offset(cx, cy), width: boxSize, height: boxSize);

    // Gelap di luar kotak
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12))),
      ),
      paint,
    );

    // Sudut-sudut kotak (corner brackets)
    final corner = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const c = 24.0; // panjang sudut
    final l = rect.left;
    final t = rect.top;
    final r = rect.right;
    final b = rect.bottom;

    // Top-left
    canvas.drawLine(Offset(l, t + c), Offset(l, t), corner);
    canvas.drawLine(Offset(l, t), Offset(l + c, t), corner);
    // Top-right
    canvas.drawLine(Offset(r - c, t), Offset(r, t), corner);
    canvas.drawLine(Offset(r, t), Offset(r, t + c), corner);
    // Bottom-left
    canvas.drawLine(Offset(l, b - c), Offset(l, b), corner);
    canvas.drawLine(Offset(l, b), Offset(l + c, b), corner);
    // Bottom-right
    canvas.drawLine(Offset(r - c, b), Offset(r, b), corner);
    canvas.drawLine(Offset(r, b), Offset(r, b - c), corner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
