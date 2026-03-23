import 'package:get/get.dart';
import '../controllers/export_import_controller.dart';

class ExportImportBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ExportImportController>(() => ExportImportController());
  }
}
