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
    final username = await _db.getSetting('app_username');
    if (username == null || username.isEmpty) {
      Get.offAllNamed(AppRoutes.setup);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
