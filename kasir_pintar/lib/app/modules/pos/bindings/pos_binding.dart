import 'package:get/get.dart';

class PosBinding extends Bindings {
  @override
  void dependencies() {
    // OrderController is registered in InitialBinding (fenix: true)
    // and used by PosView / CartPanel.
  }
}
