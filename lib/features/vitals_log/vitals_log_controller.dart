import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'vital_reading.dart';

class VitalsLogController extends GetxController {
  final GetStorage _storage = GetStorage();
  final RxList<VitalReading> readings = <VitalReading>[].obs;
  
  // Form fields
  final RxString bpSystolic = ''.obs;
  final RxString bpDiastolic = ''.obs;
  final RxString heartRate = ''.obs;
  final RxString temperature = ''.obs;
  final RxString oxygenSaturation = ''.obs;
  final RxString bloodSugar = ''.obs;
  final RxString notes = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadReadings();
  }

  void loadReadings() {
    final List<dynamic>? savedReadings = _storage.read('vital_readings');
    if (savedReadings != null) {
      readings.value = savedReadings
          .map((json) => VitalReading.fromJson(json))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
  }

  void saveReadings() {
    _storage.write(
      'vital_readings',
      readings.map((r) => r.toJson()).toList(),
    );
  }

  void addReading() {
    final reading = VitalReading(
      timestamp: DateTime.now(),
      bloodPressureSystolic: bpSystolic.value.isNotEmpty ? double.tryParse(bpSystolic.value) : null,
      bloodPressureDiastolic: bpDiastolic.value.isNotEmpty ? double.tryParse(bpDiastolic.value) : null,
      heartRate: heartRate.value.isNotEmpty ? double.tryParse(heartRate.value) : null,
      temperature: temperature.value.isNotEmpty ? double.tryParse(temperature.value) : null,
      oxygenSaturation: oxygenSaturation.value.isNotEmpty ? double.tryParse(oxygenSaturation.value) : null,
      bloodSugar: bloodSugar.value.isNotEmpty ? double.tryParse(bloodSugar.value) : null,
      notes: notes.value.isNotEmpty ? notes.value : null,
    );

    if (reading.hasAnyReading) {
      readings.insert(0, reading);
      saveReadings();
      clearForm();
      Get.back();
      Get.snackbar(
        'Success',
        'Vital reading added successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Error',
        'Please enter at least one vital reading',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void deleteReading(int index) {
    readings.removeAt(index);
    saveReadings();
    Get.snackbar(
      'Deleted',
      'Reading removed',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void clearForm() {
    bpSystolic.value = '';
    bpDiastolic.value = '';
    heartRate.value = '';
    temperature.value = '';
    oxygenSaturation.value = '';
    bloodSugar.value = '';
    notes.value = '';
  }

  String getStatusColor(String type, double? value) {
    if (value == null) return 'normal';
    
    switch (type) {
      case 'heartRate':
        if (value < 60 || value > 100) return 'warning';
        return 'normal';
      case 'temperature':
        if (value < 36.1 || value > 37.2) return 'warning';
        return 'normal';
      case 'oxygen':
        if (value < 95) return 'critical';
        if (value < 98) return 'warning';
        return 'normal';
      case 'bloodSugar':
        if (value < 70 || value > 140) return 'warning';
        return 'normal';
      case 'bpSystolic':
        if (value < 90 || value > 140) return 'warning';
        return 'normal';
      case 'bpDiastolic':
        if (value < 60 || value > 90) return 'warning';
        return 'normal';
      default:
        return 'normal';
    }
  }
}
