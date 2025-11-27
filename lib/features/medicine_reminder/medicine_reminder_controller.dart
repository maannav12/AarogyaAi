import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'medicine_reminder.dart';

class MedicineReminderController extends GetxController {
  final GetStorage _storage = GetStorage();
  final RxList<MedicineReminder> reminders = <MedicineReminder>[].obs;
  
  // Form fields
  final RxString medicineName = ''.obs;
  final RxString dosage = ''.obs;
  final RxList<String> selectedTimes = <String>[].obs;
  final RxList<String> selectedDays = <String>['Daily'].obs;
  final Rx<DateTime> startDate = DateTime.now().obs;
  final Rxn<DateTime> endDate = Rxn<DateTime>();
  final RxString notes = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadReminders();
  }

  void loadReminders() {
    final List<dynamic>? savedReminders = _storage.read('medicine_reminders');
    if (savedReminders != null) {
      reminders.value = savedReminders
          .map((json) => MedicineReminder.fromJson(json))
          .toList()
        ..sort((a, b) => b.startDate.compareTo(a.startDate));
    }
  }

  void saveReminders() {
    _storage.write(
      'medicine_reminders',
      reminders.map((r) => r.toJson()).toList(),
    );
  }

  void addReminder() {
    if (medicineName.value.isEmpty || dosage.value.isEmpty || selectedTimes.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill in medicine name, dosage, and at least one time',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final reminder = MedicineReminder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      medicineName: medicineName.value,
      dosage: dosage.value,
      times: List.from(selectedTimes),
      days: List.from(selectedDays),
      startDate: startDate.value,
      endDate: endDate.value,
      notes: notes.value.isNotEmpty ? notes.value : null,
    );

    reminders.insert(0, reminder);
    saveReminders();
    clearForm();
    Get.back();
    Get.snackbar(
      'Success',
      'Medicine reminder added',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void deleteReminder(String id) {
    reminders.removeWhere((r) => r.id == id);
    saveReminders();
    Get.snackbar(
      'Deleted',
      'Reminder removed',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void toggleReminderActive(String id) {
    final index = reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      reminders[index] = reminders[index].copyWith(
        isActive: !reminders[index].isActive,
      );
      saveReminders();
    }
  }

  void markMedicineTaken(String id) {
    final index = reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      final updatedHistory = List<DateTime>.from(reminders[index].takenHistory)
        ..add(DateTime.now());
      reminders[index] = reminders[index].copyWith(
        takenHistory: updatedHistory,
      );
      saveReminders();
      Get.snackbar(
        'Logged',
        'Medicine intake recorded',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void clearForm() {
    medicineName.value = '';
    dosage.value = '';
    selectedTimes.clear();
    selectedDays.value = ['Daily'];
    startDate.value = DateTime.now();
    endDate.value = null;
    notes.value = '';
  }

  void addTime(String time) {
    if (!selectedTimes.contains(time)) {
      selectedTimes.add(time);
      selectedTimes.sort();
    }
  }

  void removeTime(String time) {
    selectedTimes.remove(time);
  }

  void toggleDay(String day) {
    if (day == 'Daily') {
      selectedDays.value = ['Daily'];
    } else {
      selectedDays.remove('Daily');
      if (selectedDays.contains(day)) {
        selectedDays.remove(day);
      } else {
        selectedDays.add(day);
      }
      if (selectedDays.isEmpty) {
        selectedDays.value = ['Daily'];
      }
    }
  }

  List<MedicineReminder> get todayReminders {
    final today = DateTime.now();
    final dayName = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][today.weekday % 7];
    
    return reminders.where((r) {
      if (!r.isActive) return false;
      if (r.endDate != null && today.isAfter(r.endDate!)) return false;
      if (r.days.contains('Daily')) return true;
      return r.days.contains(dayName);
    }).toList();
  }

  bool wasTakenToday(MedicineReminder reminder) {
    final today = DateTime.now();
    return reminder.takenHistory.any((d) =>
        d.year == today.year &&
        d.month == today.month &&
        d.day == today.day);
  }
}
