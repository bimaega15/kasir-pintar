import 'dart:async';
import 'package:get/get.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';

class KitchenController extends GetxController {
  final _repo = Get.find<OrderRepository>();

  final orders = <OrderModel>[].obs;
  final isLoading = false.obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    loadOrders();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => loadOrders());
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> loadOrders() async {
    isLoading.value = true;
    try {
      final list = await _repo.getActive();
      orders.assignAll(list);
    } finally {
      isLoading.value = false;
    }
  }

  List<OrderModel> get pendingOrders =>
      orders
          .where((o) =>
              o.kitchenStatus == KitchenStatus.pending ||
              o.kitchenStatus == KitchenStatus.onHold)
          .toList();

  List<OrderModel> get inProgressOrders =>
      orders.where((o) => o.kitchenStatus == KitchenStatus.inProgress).toList();

  List<OrderModel> get readyOrders =>
      orders.where((o) => o.kitchenStatus == KitchenStatus.ready).toList();

  Future<void> updateStatus(String id, KitchenStatus status) async {
    await _repo.updateKitchenStatus(id, status);
    await loadOrders();
  }
}
