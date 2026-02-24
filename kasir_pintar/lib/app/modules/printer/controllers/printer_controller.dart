import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:get/get.dart';
import '../../../services/printer_service.dart';

class PrinterController extends GetxController {
  final _service = Get.find<PrinterService>();

  RxBool get isConnected => _service.isConnected;
  RxString get connectedDeviceName => _service.connectedDeviceName;
  RxBool get isLoading => _service.isLoading;
  RxList<BluetoothDevice> get devices => _service.devices;
  RxString get savedMac => _service.savedMac;
  RxString get savedName => _service.savedName;

  @override
  void onInit() {
    super.onInit();
    _service.checkConnection();
    _service.scanDevices();
  }

  Future<void> scanDevices() => _service.scanDevices();

  Future<void> connect(BluetoothDevice device) => _service.connect(device);

  Future<void> disconnect() => _service.disconnect();

  Future<void> testPrint() => _service.testPrint();
}
