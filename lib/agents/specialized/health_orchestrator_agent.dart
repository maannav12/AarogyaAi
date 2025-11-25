import 'package:get/get.dart';
import '../agent_architecture/base_agent.dart';
import '../agent_architecture/agent_memory.dart';
import '../agent_architecture/agent_tools.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../services/user_health_service.dart';

/// HealthOrchestratorAgent - Master conversational AI and coordinator
/// 
/// This agent serves as the primary interface for user interactions,
/// handling general health queries, coordinating with specialized agents,
/// and providing proactive health insights.
class HealthOrchestratorAgent extends BaseAgent {
  
  HealthOrchestratorAgent({
    required String geminiApiKey,
  }) : super(
    agentName: 'health_orchestrator',
    agentRole: 'Master Health Assistant and Coordinator',
    systemPrompt: '''
You are Dr. AI, a compassionate and knowledgeable health assistant powered by advanced AI.

Your role is to:
1. Engage in natural, empathetic conversations about health concerns
2. Provide accurate, evidence-based health information
3. Assess when to delegate complex tasks to specialized agents:
   - "diagnostic" agent: For analyzing medical images, reports, and symptoms
   - "care" agent: For creating personalized health plans and tracking adherence
   - "emergency" agent: For assessing urgent medical situations
   - "knowledge" agent: For deep medical research and explanations

4. Provide proactive health insights based on user history
5. Schedule follow-ups and reminders for health actions

Important guidelines:
- Always prioritize user safety - if you detect emergency symptoms, immediately delegate to emergency agent
- Be empathetic and non-judgmental
- Explain medical terms in simple language
- Cite sources when providing medical information
- Remind users that you're an AI assistant, not a substitute for professional medical care
- Respect user privacy and data confidentiality
- Provide responses in the user's preferred language (Hindi or English)

When you need to use a specialized agent, use the "delegate_to_agent" function.
When you want to remember important information, use the "save_to_memory" function.
To schedule follow-ups, use the "schedule_followup" function.
To retrieve user health history, use the "get_user_health_data" function.
''',
    geminiApiKey: geminiApiKey,
    modelName: 'gemini-2.0-flash',
  );
  
  @override
  void registerTools() {
    // Register common tools
    toolRegistry.registerTool(CommonAgentTools.getCurrentTimeTool());
    
    toolRegistry.registerTool(
      CommonAgentTools.createSaveMemoryTool(
        (content, metadata) => saveToMemory(content: content, metadata: metadata),
      ),
    );
    
    toolRegistry.registerTool(
      CommonAgentTools.createSearchMemoryTool(
        (query) => memory.retrieveRelevantContext(query),
      ),
    );
    
    // Register orchestrator-specific tools
    _registerOrchestratorTools();
  }
  
  void _registerOrchestratorTools() {
    // Get user context tool
    toolRegistry.registerTool(
      AgentTool(
        name: 'get_user_context',
        description: 'Retrieve comprehensive user health profile and preferences',
        parameters: {
          'userId': Schema(
            SchemaType.string,
            description: 'User ID to retrieve context for',
          ),
        },
        function: (args) async {
          final userId = args['userId'] as String;
          final userHealthService = Get.find<UserHealthService>();
          
          // Get recent conversation summary
          final conversationSummary = await memory.getConversationSummary(
            lastNMessages: 10,
          );
          
          // Get health context from service
          final healthContext = await userHealthService.getHealthContext();
          
          return {
            'success': true,
            'userId': userId,
            'conversationSummary': conversationSummary,
            'healthContext': healthContext,
            'preferences': {
              'language': 'hi', // TODO: Get from user profile
              'notificationEnabled': true,
            },
          };
        },
      ),
    );
    
    // Summarize health status tool
    toolRegistry.registerTool(
      AgentTool(
        name: 'summarize_health_status',
        description: 'Generate a comprehensive health status summary for the user',
        parameters: {
          'userId': Schema(
            SchemaType.string,
            description: 'User ID to summarize health status for',
          ),
          'period': Schema(
            SchemaType.string,
            description: 'Time period for summary (e.g., "daily", "weekly", "monthly")',
            nullable: true,
          ),
        },
        function: (args) async {
          final userId = args['userId'] as String;
          final period = args['period'] as String? ?? 'weekly';
          
          // In production, this would aggregate actual health data
          // For now, return a template
          
          return {
            'success': true,
            'userId': userId,
            'period': period,
            'summary': 'Your health summary for the past $period shows positive trends. '
                      'Keep up the good work with your medication adherence.',
            'metrics': {
              'vitalsLogged': 5,
              'medicationAdherence': 85,
              'exerciseMinutes': 120,
            },
          };
        },
      ),
    );
    
    // Detect intent tool (for better routing)
    toolRegistry.registerTool(
      AgentTool(
        name: 'detect_user_intent',
        description: 'Analyze user query to understand their intent and emotional state',
        parameters: {
          'query': Schema(
            SchemaType.string,
            description: 'User query to analyze',
          ),
        },
        function: (args) async {
          final query = args['query'] as String;
          final queryLower = query.toLowerCase();
          
          // Simple intent detection (in production, use NLU)
          String intent = 'general_health';
          int urgencyLevel = 0;
          
          // Emergency detection
          if (queryLower.contains(RegExp(
            r"emergency|urgent|severe|chest pain|can't breathe|bleeding heavily"
          ))) {
            intent = 'emergency';
            urgencyLevel = 10;
          }
          // Diagnostic intent
          else if (queryLower.contains(RegExp(
            r'scan|image|test|result|analyze|symptom|diagnosis'
          ))) {
            intent = 'diagnostic';
            urgencyLevel = 5;
          }
          // Care plan intent
          else if (queryLower.contains(RegExp(
            r'plan|routine|exercise|diet|medication|therapy'
          ))) {
            intent = 'care_plan';
            urgencyLevel = 3;
          }
          // Knowledge intent
          else if (queryLower.contains(RegExp(
            r'what is|explain|tell me about|how does|information'
          ))) {
            intent = 'knowledge';
            urgencyLevel = 1;
          }
          
          return {
            'success': true,
            'intent': intent,
            'urgencyLevel': urgencyLevel,
            'requiresSpecialistAgent': urgencyLevel >= 5,
            'suggestedAgent': intent == 'general_health' ? null : intent,
          };
        },
      ),
    );
  }
  
  @override
  Future<Map<String, dynamic>> _executeWithContext(
    AgentTask task,
    List<MemoryEntry> context,
  ) async {
    final query = task.context['query'] as String;
    final userId = task.context['userId'] as String?;
    
    // Build context for Gemini
    final contextString = context.isEmpty
        ? 'No previous context available.'
        : 'Previous relevant interactions:\n${context.map((c) => '- ${c.content}').join('\n')}';
    
    // Generate response with function calling
    final result = await generateResponse(
      prompt: query,
      additionalContext: {
        'userId': userId,
        'previousContext': contextString,
      },
    );
    
    // Save interaction to memory
    if (result['success'] == true) {
      await saveToMemory(
        content: 'User: $query\nAssistant: ${result['response']}',
        metadata: {
          'type': 'conversation',
          'userId': userId,
          'intent': task.context['intent'],
        },
      );
    }
    
    return result;
  }
  
  /// Proactive health check-in
  Future<Map<String, dynamic>> performProactiveCheckIn(String userId) async {
    logger.i('[HealthOrchestrator] Performing proactive check-in for user: $userId');
    
    // Get user context
    final contextResult = await toolRegistry.executeTool(
      'get_user_context',
      {'userId': userId},
    );
    
    // Generate personalized check-in message
    final result = await generateResponse(
      prompt: 'Generate a friendly, personalized health check-in message based on the user\'s recent activity.',
      additionalContext: contextResult,
    );
    
    return result;
  }
  
  /// Generate daily health insights
  Future<Map<String, dynamic>> generateDailyInsights(String userId) async {
    logger.i('[HealthOrchestrator] Generating daily insights for user: $userId');
    
    // Get health summary
    final summaryResult = await toolRegistry.executeTool(
      'summarize_health_status',
      {
        'userId': userId,
        'period': 'daily',
      },
    );
    
    // Generate insights
    final result = await generateResponse(
      prompt: 'Based on this health summary, provide 2-3 actionable insights and encouragement for the user.',
      additionalContext: summaryResult,
    );
    
    return result;
  }
}
