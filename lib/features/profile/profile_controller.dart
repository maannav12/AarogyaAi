import 'package:get/get.dart';
import '../../models/user_profile_model.dart';
import '../../services/user_health_service.dart';

class ProfileController extends GetxController {
  final UserHealthService _healthService = Get.find<UserHealthService>();

  final Rx<UserProfile> profile = UserProfile().obs;
  final RxBool isEditing = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Sync with service profile
    profile.value = _healthService.userProfile.value;
    
    // Listen for changes
    ever(_healthService.userProfile, (UserProfile p) {
      profile.value = p;
    });
  }

  Future<void> saveProfile() async {
    await _healthService.saveProfile(profile.value);
    Get.snackbar(
      'Success',
      'Profile saved successfully',
      snackPosition: SnackPosition.BOTTOM,
    );
    isEditing.value = false;
  }

  void toggleEdit() {
    isEditing.value = !isEditing.value;
  }

  void updateName(String value) => profile.update((val) => val?.name = value);
  void updateAge(String value) => profile.update((val) => val?.age = int.tryParse(value));
  void updateGender(String value) => profile.update((val) => val?.gender = value);
  void updateBloodType(String value) => profile.update((val) => val?.bloodType = value);
  void updateHeight(String value) => profile.update((val) => val?.height = double.tryParse(value));
  void updateWeight(String value) => profile.update((val) => val?.weight = double.tryParse(value));
  
  void updateAllergies(List<String> value) => profile.update((val) => val?.allergies = value);
  void updateChronicConditions(List<String> value) => profile.update((val) => val?.chronicConditions = value);
  void updateCurrentMedications(List<String> value) => profile.update((val) => val?.currentMedications = value);
  void updatePastSurgeries(List<String> value) => profile.update((val) => val?.pastSurgeries = value);
  
  void updateEmergencyContactName(String value) => profile.update((val) => val?.emergencyContactName = value);
  void updateEmergencyContactPhone(String value) => profile.update((val) => val?.emergencyContactPhone = value);

  void addAllergy(String allergy) {
    profile.update((val) {
      val?.allergies ??= [];
      if (!val!.allergies!.contains(allergy)) {
        val.allergies!.add(allergy);
      }
    });
  }

  void removeAllergy(String allergy) {
    profile.update((val) => val?.allergies?.remove(allergy));
  }

  void addChronicCondition(String condition) {
    profile.update((val) {
      val?.chronicConditions ??= [];
      if (!val!.chronicConditions!.contains(condition)) {
        val.chronicConditions!.add(condition);
      }
    });
  }

  void removeChronicCondition(String condition) {
    profile.update((val) => val?.chronicConditions?.remove(condition));
  }

  void addMedication(String medication) {
    profile.update((val) {
      val?.currentMedications ??= [];
      if (!val!.currentMedications!.contains(medication)) {
        val.currentMedications!.add(medication);
      }
    });
  }

  void removeMedication(String medication) {
    profile.update((val) => val?.currentMedications?.remove(medication));
  }

  void addSurgery(String surgery) {
    profile.update((val) {
      val?.pastSurgeries ??= [];
      if (!val!.pastSurgeries!.contains(surgery)) {
        val.pastSurgeries!.add(surgery);
      }
    });
  }

  void removeSurgery(String surgery) {
    profile.update((val) => val?.pastSurgeries?.remove(surgery));
  }
}
