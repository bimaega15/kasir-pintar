import 'package:get/get.dart';
import '../data/repositories/product_repository.dart';
import '../data/repositories/transaction_repository.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProductRepository>(() => ProductRepository(), fenix: true);
    Get.lazyPut<TransactionRepository>(() => TransactionRepository(), fenix: true);
  }
}
