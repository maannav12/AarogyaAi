class VitalReading {
  final DateTime timestamp;
  final double? bloodPressureSystolic;
  final double? bloodPressureDiastolic;
  final double? heartRate;
  final double? temperature;
  final double? oxygenSaturation;
  final double? bloodSugar;
  final String? notes;

  VitalReading({
    required this.timestamp,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.heartRate,
    this.temperature,
    this.oxygenSaturation,
    this.bloodSugar,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'bloodPressureSystolic': bloodPressureSystolic,
      'bloodPressureDiastolic': bloodPressureDiastolic,
      'heartRate': heartRate,
      'temperature': temperature,
      'oxygenSaturation': oxygenSaturation,
      'bloodSugar': bloodSugar,
      'notes': notes,
    };
  }

  factory VitalReading.fromJson(Map<String, dynamic> json) {
    return VitalReading(
      timestamp: DateTime.parse(json['timestamp']),
      bloodPressureSystolic: json['bloodPressureSystolic']?.toDouble(),
      bloodPressureDiastolic: json['bloodPressureDiastolic']?.toDouble(),
      heartRate: json['heartRate']?.toDouble(),
      temperature: json['temperature']?.toDouble(),
      oxygenSaturation: json['oxygenSaturation']?.toDouble(),
      bloodSugar: json['bloodSugar']?.toDouble(),
      notes: json['notes'],
    );
  }

  String get bloodPressureReading {
    if (bloodPressureSystolic != null && bloodPressureDiastolic != null) {
      return '${bloodPressureSystolic!.toInt()}/${bloodPressureDiastolic!.toInt()}';
    }
    return '-';
  }

  bool get hasAnyReading {
    return bloodPressureSystolic != null ||
        bloodPressureDiastolic != null ||
        heartRate != null ||
        temperature != null ||
        oxygenSaturation != null ||
        bloodSugar != null;
  }
}
