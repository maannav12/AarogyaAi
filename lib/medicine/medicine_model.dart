class MedicineModel {
  final String medicineName;
  final String usageInfo;
  final String dosageInfo;
  final String warningInfo;

  MedicineModel({
    required this.medicineName,
    required this.usageInfo,
    required this.dosageInfo,
    required this.warningInfo,
  });

  factory MedicineModel.fromMap(Map<String, dynamic> map) {
    // Check if API returns "details" object (actual API format)
    if (map.containsKey('details')) {
      var details = map['details'] as Map<String, dynamic>;
      String name = details['Medicine Name'] ?? 'Unknown Medicine';
      String composition = details['Composition'] ?? '';
      String uses = details['Uses'] ?? '';
      String sideEffects = details['Side_effects'] ?? '';
      
      // Combine composition with name if available
      if (composition.isNotEmpty) {
        name = "$name ($composition)";
      }
      
      return MedicineModel(
        medicineName: name,
        usageInfo: uses,
        dosageInfo: "", // Not provided by API
        warningInfo: sideEffects,
      );
    }
    
    // Check if API returns "Hindi Explanation" field (from console logs)
    if (map.containsKey('Hindi Explanation')) {
      String explanation = map['Hindi Explanation'] ?? '';
      return MedicineModel(
        medicineName: "Medicine Details",
        usageInfo: explanation,
        dosageInfo: "",
        warningInfo: "",
      );
    }
    
    // Fallback to original format
    return MedicineModel(
      medicineName: map['medicine_name'] ?? '',
      usageInfo: map['usage_info'] ?? '',
      dosageInfo: map['dosage_info'] ?? '',
      warningInfo: map['warning_info'] ?? '',
    );
  }
}
