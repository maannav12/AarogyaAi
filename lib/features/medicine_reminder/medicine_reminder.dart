class MedicineReminder {
  final String id;
  final String medicineName;
  final String dosage;
  final List<String> times; // e.g., ["08:00 AM", "02:00 PM", "08:00 PM"]
  final List<String> days; // e.g., ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"] or ["Daily"]
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final bool isActive;
  final List<DateTime> takenHistory; // Track when medicine was actually taken

  MedicineReminder({
    required this.id,
    required this.medicineName,
    required this.dosage,
    required this.times,
    required this.days,
    required this.startDate,
    this.endDate,
    this.notes,
    this.isActive = true,
    this.takenHistory = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicineName': medicineName,
      'dosage': dosage,
      'times': times,
      'days': days,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'notes': notes,
      'isActive': isActive,
      'takenHistory': takenHistory.map((d) => d.toIso8601String()).toList(),
    };
  }

  factory MedicineReminder.fromJson(Map<String, dynamic> json) {
    return MedicineReminder(
      id: json['id'],
      medicineName: json['medicineName'],
      dosage: json['dosage'],
      times: List<String>.from(json['times']),
      days: List<String>.from(json['days']),
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      notes: json['notes'],
      isActive: json['isActive'] ?? true,
      takenHistory: (json['takenHistory'] as List<dynamic>?)
              ?.map((d) => DateTime.parse(d))
              .toList() ??
          [],
    );
  }

  MedicineReminder copyWith({
    String? id,
    String? medicineName,
    String? dosage,
    List<String>? times,
    List<String>? days,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    bool? isActive,
    List<DateTime>? takenHistory,
  }) {
    return MedicineReminder(
      id: id ?? this.id,
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage ?? this.dosage,
      times: times ?? this.times,
      days: days ?? this.days,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      takenHistory: takenHistory ?? this.takenHistory,
    );
  }

  String get frequency {
    if (days.contains('Daily') || days.length == 7) {
      return 'Daily';
    }
    return '${days.length} days/week';
  }

  String get timesDisplay {
    return '${times.length}x daily';
  }
}
