// Example: Integrating AI Agent System with Existing Chatbot
// File: lib/features/chatbot/chatbot_controller_enhanced.dart

import 'package:get/get.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import '../../agents/agent_system_manager.dart';

class ChatbotControllerEnhanced extends GetxController {
  // Agent system
  final agentSystem = AgentSystemManager.getInstance();
  
  // Chat state
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isTyping = false.obs;
  final RxString currentAgent = ''.obs;
  
  // Users
  final currentUser = ChatUser(id: 'user', firstName: 'You');
  final geminiUser = ChatUser(
    id: 'assistant',
    firstName: 'Dr. AI',
    profileImage: 'https://ui-avatars.com/api/?name=Dr+AI&background=4285F4&color=fff',
  );
  
  @override
  void onInit() {
    super.onInit();
    _sendWelcomeMessage();
  }
  
  void _sendWelcomeMessage() {
    messages.insert(0, ChatMessage(
      text: 'Namaste! 🙏 I\'m Dr. AI, your intelligent health assistant. '
            'I can analyze medical reports, answer health questions, '
            'and provide personalized health guidance. How can I help you today?',
      user: geminiUser,
      createdAt: DateTime.now(),
    ));
  }
  
  /// Send message through agent system
  Future<void> sendMessage(ChatMessage chatMessage) async {
    // Add user message
    messages.insert(0, chatMessage);
    isTyping.value = true;
    currentAgent.value = 'Processing...';
    
    try {
      // Get user ID from auth (or use demo ID)
      final userId = _getCurrentUserId();
      
      // Process query through agent orchestrator
      final result = await agentSystem.processQuery(
        query: chatMessage.text,
        userId: userId,
        context: {
          'conversationHistory': _getRecentHistory(),
        },
      );
      
      if (result['success']) {
        // Determine which agent(s) handled the query
        final executionMode = result['executionMode'];
        String agentInfo = '';
        
        if (executionMode == 'multi-agent') {
          final agents = (result['agents'] as List).join(', ');
          agentInfo = '🤖 Collaborative response from: $agents';
          currentAgent.value = 'Multiple agents';
        } else if (executionMode == 'single') {
          final agent = result['agent'];
          agentInfo = '🤖 Answered by: ${_getAgentDisplayName(agent)}';
          currentAgent.value = _getAgentDisplayName(agent);
        }
        
        // Create response message
        String responseText = result['synthesizedResult']?['response'] ?? 
                             result['result']?['response'] ?? 
                             'I apologize, I couldn\'t process that request.';
        
        // Add agent identifier as metadata (optional)
        if (agentInfo.isNotEmpty) {
          responseText = '$responseText\n\n_$agentInfo_';
        }
        
        messages.insert(0, ChatMessage(
          text: responseText,
          user: geminiUser,
          createdAt: DateTime.now(),
        ));
        
        // If diagnostic analysis with image was done, show additional UI
        if (result['result']?['mlClassification'] != null) {
          _showDiagnosticResults(result['result']);
        }
        
      } else {
        _showErrorMessage(result['error']);
      }
      
    } catch (e) {
      print('[Chatbot] Error: $e');
      _showErrorMessage('Sorry, something went wrong. Please try again.');
    } finally {
      isTyping.value = false;
      currentAgent.value = '';
    }
  }
  
  /// Send medical image for analysis
  Future<void> sendMedicalImage({
    required String imagePath,
    required String imageType,
  }) async {
    isTyping.value = true;
    currentAgent.value = 'Diagnostic Agent';
    
    try {
      final userId = _getCurrentUserId();
      
      // Send to diagnostic agent
      final result = await agentSystem.analyzeMedicalImage(
        imagePath: imagePath,
        imageType: imageType,
        userId: userId,
      );
      
      if (result['success']) {
        // Show ML classification
        final mlClass = result['mlClassification'];
        final visualAnalysis = result['visualAnalysis'];
        
        String responseText = '📊 **Diagnostic Analysis Complete**\n\n';
        
        // ML Results
        if (mlClass != null && mlClass['success']) {
          responseText += '**AI Classification:**\n';
          responseText += '${mlClass['topPrediction']} ';
          responseText += '(${(mlClass['topConfidence'] * 100).toStringAsFixed(1)}% confidence)\n\n';
        }
        
        // Visual Analysis
        if (visualAnalysis != null && visualAnalysis['success']) {
          responseText += '**Detailed Analysis:**\n';
          responseText += '${visualAnalysis['summary']}\n\n';
        }
        
        // Historical trend
        if (result['historicalComparison'] != null) {
          final trend = result['historicalComparison'];
          responseText += '**Trend Analysis:**\n';
          responseText += 'Compared to your previous scans, this shows a ';
          responseText += '**${trend['trend']}** trend.\n\n';
        }
        
        responseText += '_⚠️ This is an AI-assisted analysis. Please consult a healthcare professional for definitive diagnosis._';
        
        messages.insert(0, ChatMessage(
          text: responseText,
          user: geminiUser,
          createdAt: DateTime.now(),
        ));
        
      } else {
        _showErrorMessage('Failed to analyze image');
      }
      
    } catch (e) {
      print('[Chatbot] Image analysis error: $e');
      _showErrorMessage('Image analysis failed');
    } finally {
      isTyping.value = false;
      currentAgent.value = '';
    }
  }
  
  /// Request proactive health check-in
  Future<void> requestDailyInsights() async {
    try {
      final userId = _getCurrentUserId();
      final insights = await agentSystem.generateDailyInsights(userId);
      
      if (insights['success']) {
        messages.insert(0, ChatMessage(
          text: '🌅 **Your Daily Health Insights**\n\n${insights['response']}',
          user: geminiUser,
          createdAt: DateTime.now(),
        ));
      }
    } catch (e) {
      print('[Chatbot] Daily insights error: $e');
    }
  }
  
  /// Get agent display name
  String _getAgentDisplayName(String agentKey) {
    final names = {
      'orchestrator': 'Health Orchestrator',
      'diagnostic': 'Diagnostic Specialist',
      'care': 'Care Plan Specialist',
      'emergency': 'Emergency Triage',
      'knowledge': 'Medical Knowledge',
    };
    return names[agentKey] ?? agentKey;
  }
  
  /// Get recent conversation history
  List<Map<String, String>> _getRecentHistory() {
    return messages
        .take(5)
        .map((msg) => {
              'role': msg.user.id == currentUser.id ? 'user' : 'assistant',
              'content': msg.text,
            })
        .toList();
  }
  
  /// Get current user ID (integrate with your auth)
  String _getCurrentUserId() {
    // TODO: Replace with actual user ID from auth
    return 'demo_user_123';
  }
  
  /// Show error message
  void _showErrorMessage(String error) {
    messages.insert(0, ChatMessage(
      text: '❌ $error',
      user: geminiUser,
      createdAt: DateTime.now(),
    ));
  }
  
  /// Show diagnostic results in specialized UI
  void _showDiagnosticResults(Map<String, dynamic> results) {
    // TODO: Navigate to detailed results screen
    print('[Chatbot] Diagnostic results available: $results');
  }
  
  /// Get system status for debugging
  void printSystemStatus() {
    final status = agentSystem.getSystemStatus();
    print('=== Agent System Status ===');
    print('Tasks Processed: ${status['orchestratorStats']['totalTasks']}');
    print('Success Rate: ${(status['orchestratorStats']['successRate'] * 100).toStringAsFixed(1)}%');
    print('Token Usage: ${status['geminiUsage']['totalTokens']}');
    print('Estimated Cost: \$${status['geminiUsage']['estimatedCostUSD']}');
    print('Active Agents: ${status['activeAgents']}');
  }
}
