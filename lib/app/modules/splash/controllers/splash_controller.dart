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
    // Selalu ke login dulu, dari login ada tombol "Daftar" jika belum punya akun
    Get.offAllNamed(AppRoutes.login);
  }
}
