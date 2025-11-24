class UserProfile {
  String? name;
  int? age;
  String? gender;
  String? bloodType;
  double? height; // in cm
  double? weight; // in kg
  List<String>? allergies;
  List<String>? chronicConditions;
  List<String>? currentMedications;
  List<String>? pastSurgeries;
  String? emergencyContactName;
  String? emergencyContactPhone;

  UserProfile({
    this.name,
    this.age,
    this.gender,
    this.bloodType,
    this.height,
    this.weight,
    this.allergies,
    this.chronicConditions,
    this.currentMedications,
    this.pastSurgeries,
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  // Calculate BMI
  double? get bmi {
    if (height != null && weight != null && height! > 0) {
      return weight! / ((height! / 100) * (height! / 100));
    }
    return null;
  }

  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return 'Unknown';
    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25) return 'Normal';
    if (bmiValue < 30) return 'Overweight';
    return 'Obese';
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'bloodType': bloodType,
      'height': height,
      'weight': weight,
      'allergies': allergies,
      'chronicConditions': chronicConditions,
      'currentMedications': currentMedications,
      'pastSurgeries': pastSurgeries,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
    };
  }

  // Create from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'],
      age: json['age'],
      gender: json['gender'],
      bloodType: json['bloodType'],
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
      allergies: json['allergies'] != null ? List<String>.from(json['allergies']) : null,
      chronicConditions: json['chronicConditions'] != null ? List<String>.from(json['chronicConditions']) : null,
      currentMedications: json['currentMedications'] != null ? List<String>.from(json['currentMedications']) : null,
      pastSurgeries: json['pastSurgeries'] != null ? List<String>.from(json['pastSurgeries']) : null,
      emergencyContactName: json['emergencyContactName'],
      emergencyContactPhone: json['emergencyContactPhone'],
    );
  }

  // Get profile summary for chatbot context
  String getProfileSummary() {
    List<String> summary = [];
    
    if (name != null) summary.add('Name: $name');
    if (age != null) summary.add('Age: $age years');
    if (gender != null) summary.add('Gender: $gender');
    if (bloodType != null) summary.add('Blood Type: $bloodType');
    if (height != null && weight != null) {
      summary.add('Height: ${height!.toStringAsFixed(0)}cm, Weight: ${weight!.toStringAsFixed(1)}kg');
      if (bmi != null) summary.add('BMI: ${bmi!.toStringAsFixed(1)} ($bmiCategory)');
    }
    if (allergies != null && allergies!.isNotEmpty) {
      summary.add('Allergies: ${allergies!.join(', ')}');
    }
    if (chronicConditions != null && chronicConditions!.isNotEmpty) {
      summary.add('Chronic Conditions: ${chronicConditions!.join(', ')}');
    }
    if (currentMedications != null && currentMedications!.isNotEmpty) {
      summary.add('Current Medications: ${currentMedications!.join(', ')}');
    }
    
    return summary.isEmpty ? 'No profile data available' : summary.join('\n');
  }
}
