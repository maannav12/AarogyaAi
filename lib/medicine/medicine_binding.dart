import 'package:get/get.dart';
import 'medicin_controler.dart';

class MedicineBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MedicineController());
  }
}
