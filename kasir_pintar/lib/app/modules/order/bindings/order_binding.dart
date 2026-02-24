import 'package:get/get.dart';
import '../controllers/order_controller.dart';

class OrderBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<OrderController>(OrderController(), permanent: false);
  }
}
