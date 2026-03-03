import 'package:get/get.dart';
import '../controllers/kitchen_controller.dart';

class KitchenBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<KitchenController>(KitchenController());
  }
}
