import 'package:get/get.dart';
import 'agent_architecture/agent_orchestrator.dart';
import 'specialized/health_orchestrator_agent.dart';
import 'specialized/diagnostic_analysis_agent.dart';
import '../services/gemini_agent_service.dart';

/// AgentSystemManager - Centralized manager for the multi-agent system
/// 
/// This singleton class initializes and manages all AI agents,
/// providing a simple interface for the rest of the application.
class AgentSystemManager {
  static AgentSystemManager? _instance;
  
  // Orchestrator
  late final AgentOrchestrator orchestrator;
  
  // Specialized agents
  late final HealthOrchestratorAgent healthAgent;
  late final DiagnosticAnalysisAgent diagnosticAgent;
  
  // Gemini service
  late final GeminiAgentService geminiService;
  
  // Configuration
  final String geminiApiKey;
  
  bool _isInitialized = false;
  
  AgentSystemManager._({required this.geminiApiKey});
  
  /// Get or create singleton instance
  static AgentSystemManager getInstance({String? geminiApiKey}) {
    if (_instance == null) {
      if (geminiApiKey == null) {
        throw Exception('Gemini API key required for first initialization');
      }
      _instance = AgentSystemManager._(geminiApiKey: geminiApiKey);
    }
    return _instance!;
  }
  
  /// Initialize the multi-agent system
  Future<void> initialize() async {
    if (_isInitialized) {
      print('[AgentSystem] Already initialized');
      return;
    }
    
    print('[AgentSystem] Initializing multi-agent system...');
    
    try {
      // Initialize Gemini service
      geminiService = GeminiAgentService(apiKey: geminiApiKey);
      
      // Initialize orchestrator
      orchestrator = AgentOrchestrator();
      Get.put(orchestrator, permanent: true);
      
      // Initialize specialized agents
      healthAgent = HealthOrchestratorAgent(geminiApiKey: geminiApiKey);
      diagnosticAgent = DiagnosticAnalysisAgent(geminiApiKey: geminiApiKey);
      
      // Put agents in GetX for dependency injection
      Get.put(healthAgent, permanent: true);
      Get.put(diagnosticAgent, permanent: true);
      
      // Register agents with orchestrator
      orchestrator.registerAgent('orchestrator', healthAgent);
      orchestrator.registerAgent('diagnostic', diagnosticAgent);
      
      _isInitialized = true;
      print('[AgentSystem] Multi-agent system initialized successfully');
      print('[AgentSystem] Active agents: ${orchestrator.getExecutionStats()['agentUsage']}');
      
    } catch (e) {
      print('[AgentSystem] Initialization error: $e');
      throw Exception('Failed to initialize agent system: $e');
    }
  }
  
  /// Process a user query through the orchestrator
  Future<Map<String, dynamic>> processQuery({
    required String query,
    String? userId,
    Map<String, dynamic>? context,
  }) async {
    _ensureInitialized();
    
    return await orchestrator.processQuery(
      query: query,
      userId: userId,
      context: context,
    );
  }
  
  /// Analyze a medical image
  Future<Map<String, dynamic>> analyzeMedicalImage({
    required String imagePath,
    required String imageType, // 'mri', 'xray', or 'skin'
    String? userId,
  }) async {
    _ensureInitialized();
    
    return await orchestrator.delegateTask(
      targetAgent: 'diagnostic',
      taskType: 'analyze_image',
      context: {
        'imagePath': imagePath,
        'imageType': imageType,
        'userId': userId,
      },
      priority: 8,
    );
  }
  
  /// Perform proactive health check-in
  Future<Map<String, dynamic>> performHealthCheckIn(String userId) async {
    _ensureInitialized();
    
    return await healthAgent.performProactiveCheckIn(userId);
  }
  
  /// Generate daily health insights
  Future<Map<String, dynamic>> generateDailyInsights(String userId) async {
    _ensureInitialized();
    
    return await healthAgent.generateDailyInsights(userId);
  }
  
  /// Get system status and statistics
  Map<String, dynamic> getSystemStatus() {
    _ensureInitialized();
    
    return {
      'initialized': _isInitialized,
      'orchestratorStats': orchestrator.getExecutionStats(),
      'geminiUsage': geminiService.getUsageStats(),
      'activeAgents': [
        'health_orchestrator',
        'diagnostic',
        // More agents will be added here
      ],
    };
  }
  
  /// Cleanup and dispose resources
  Future<void> dispose() async {
    if (!_isInitialized) return;
    
    print('[AgentSystem] Disposing agent system...');
    
    orchestrator.onClose();
    healthAgent.onClose();
    diagnosticAgent.onClose();
    
    Get.delete<AgentOrchestrator>();
    Get.delete<HealthOrchestratorAgent>();
    Get.delete<DiagnosticAnalysisAgent>();
    
    geminiService.clearModelCache();
    
    _isInitialized = false;
    _instance = null;
    
    print('[AgentSystem] Agent system disposed');
  }
  
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception('Agent system not initialized. Call initialize() first.');
    }
  }
}

/// Extension methods for easy access from anywhere in the app
extension AgentSystemExtension on GetInterface {
  AgentSystemManager get agentSystem => AgentSystemManager.getInstance();
}
