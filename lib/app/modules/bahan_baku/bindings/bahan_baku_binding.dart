import 'package:get/get.dart';
import '../controllers/bahan_baku_controller.dart';

class BahanBakuBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BahanBakuController>(() => BahanBakuController());
  }
}
