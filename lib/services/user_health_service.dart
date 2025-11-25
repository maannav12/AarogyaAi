import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/user_profile_model.dart';
import '../agents/agent_architecture/agent_memory.dart';

class UserHealthService extends GetxService {
  final storage = GetStorage();
  static const String _profileKey = 'user_profile';
  
  // Singleton instance
  static UserHealthService get to => Get.find();
  
  // Reactive profile
  final Rx<UserProfile> userProfile = UserProfile().obs;
  
  // Agent Memory reference (for long-term storage)
  late final AgentMemory _agentMemory;
  
  Future<UserHealthService> init() async {
    // Initialize AgentMemory
    _agentMemory = AgentMemory(agentName: 'user_health_service');
    await _agentMemory.initialize();
    
    // Load local profile
    loadProfile();
    
    return this;
  }
  
  /// Load profile from local storage
  void loadProfile() {
    final data = storage.read(_profileKey);
    if (data != null) {
      try {
        userProfile.value = UserProfile.fromJson(Map<String, dynamic>.from(data));
      } catch (e) {
        print('Error loading profile: $e');
      }
    }
  }
  
  /// Save profile to local storage and agent memory
  Future<void> saveProfile(UserProfile profile) async {
    userProfile.value = profile;
    await storage.write(_profileKey, profile.toJson());
    
    // Also save to agent memory as a "profile update" event
    await _agentMemory.saveMemory(
      content: 'User updated profile: ${profile.getProfileSummary()}',
      metadata: {
        'type': 'profile_update',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
  
  /// Save workout session
  Future<void> saveWorkout({
    required String exerciseName,
    required int reps,
    required int durationSeconds,
    required int score,
  }) async {
    final workoutData = {
      'exercise': exerciseName,
      'reps': reps,
      'duration': durationSeconds,
      'score': score,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    // Save to Agent Memory
    await _agentMemory.saveHealthData(
      userId: 'current_user', // TODO: Use actual user ID
      dataType: 'workout',
      value: workoutData,
    );
    
    // Create a memory entry for context
    await _agentMemory.saveMemory(
      content: 'User completed $reps reps of $exerciseName with a form score of $score%.',
      metadata: {
        'type': 'workout_log',
        'exercise': exerciseName,
        'score': score,
      },
    );
  }
  
  /// Save chat interaction
  Future<void> saveChatInteraction(String userMessage, String botResponse) async {
    await _agentMemory.saveMemory(
      content: 'User: $userMessage\nAssistant: $botResponse',
      metadata: {
        'type': 'chat_interaction',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
  
  /// Get relevant health context for agents
  Future<String> getHealthContext() async {
    final profileSummary = userProfile.value.getProfileSummary();
    final recentMemories = _agentMemory.getRecentMemories(limit: 5);
    
    final memoryString = recentMemories.map((m) => '- ${m.content}').join('\n');
    
    return '''
User Profile:
$profileSummary

Recent Activity:
$memoryString
''';
  }
  
  /// Get recent workouts
  Future<List<Map<String, dynamic>>> getRecentWorkouts({int limit = 10}) async {
    return await _agentMemory.getHealthData(
      userId: 'current_user',
      dataType: 'workout',
      limit: limit,
    );
  }
}
