import 'package:get/get.dart';
import '../controllers/price_levels_controller.dart';

class PriceLevelsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PriceLevelsController>(() => PriceLevelsController());
  }
}
