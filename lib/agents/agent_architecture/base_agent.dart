import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logger/logger.dart';
import 'agent_memory.dart';
import 'agent_tools.dart';

/// AgentTask represents a unit of work for an agent
class AgentTask {
  final String id;
  final String type;
  final Map<String, dynamic> context;
  final DateTime createdAt;
  final int priority; // Higher = more urgent
  
  AgentTask({
    required this.id,
    required this.type,
    required this.context,
    DateTime? createdAt,
    this.priority = 0,
  }) : createdAt = createdAt ?? DateTime.now();
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'context': context,
    'createdAt': createdAt.toIso8601String(),
    'priority': priority,
  };
}

/// AgentState represents the current execution state of an agent
enum AgentStatus { idle, thinking, executing, waiting, error }

class AgentState {
  final AgentStatus status;
  final String? currentTask;
  final String? statusMessage;
  final double? progress;
  
  AgentState({
    required this.status,
    this.currentTask,
    this.statusMessage,
    this.progress,
  });
  
  AgentState copyWith({
    AgentStatus? status,
    String? currentTask,
    String? statusMessage,
    double? progress,
  }) {
    return AgentState(
      status: status ?? this.status,
      currentTask: currentTask ?? this.currentTask,
      statusMessage: statusMessage ?? this.statusMessage,
      progress: progress ?? this.progress,
    );
  }
}

/// AgentDecision logs agent reasoning and actions
class AgentDecision {
  final String agentName;
  final String task;
  final String reasoning;
  final String action;
  final Map<String, dynamic>? result;
  final DateTime timestamp;
  
  AgentDecision({
    required this.agentName,
    required this.task,
    required this.reasoning,
    required this.action,
    this.result,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  Map<String, dynamic> toJson() => {
    'agentName': agentName,
    'task': task,
    'reasoning': reasoning,
    'action': action,
    'result': result,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// BaseAgent - Abstract base class for all AI agents
abstract class BaseAgent extends GetxController {
  // Agent identity
  final String agentName;
  final String agentRole;
  final String systemPrompt;
  
  // Agent state
  final Rx<AgentState> state = AgentState(status: AgentStatus.idle).obs;
  
  // Dependencies
  late final AgentMemory memory;
  late final AgentToolRegistry toolRegistry;
  late final GenerativeModel model;
  final Logger logger = Logger();
  
  // Configuration
  final String geminiApiKey;
  final String modelName;
  
  BaseAgent({
    required this.agentName,
    required this.agentRole,
    required this.systemPrompt,
    required this.geminiApiKey,
    this.modelName = 'gemini-2.0-flash',
  });
  
  @override
  void onInit() {
    super.onInit();
    _initializeAgent();
  }
  
  /// Initialize agent components
  Future<void> _initializeAgent() async {
    try {
      // Initialize memory
      memory = AgentMemory(agentName: agentName);
      await memory.initialize();
      
      // Initialize tool registry
      toolRegistry = AgentToolRegistry();
      registerTools();
      
      // Initialize Gemini model with function calling
      model = GenerativeModel(
        model: modelName,
        apiKey: geminiApiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 2048,
        ),
        tools: [
          Tool(functionDeclarations: toolRegistry.getGeminiFunctionDeclarations()),
        ],
        systemInstruction: Content.system(systemPrompt),
      );
      
      logger.i('[$agentName] Agent initialized successfully');
    } catch (e) {
      logger.e('[$agentName] Initialization error: $e');
      state.value = state.value.copyWith(
        status: AgentStatus.error,
        statusMessage: 'Initialization failed: $e',
      );
    }
  }
  
  /// Register agent-specific tools (override in subclasses)
  void registerTools();
  
  /// Execute an agent task
  Future<Map<String, dynamic>> executeTask(AgentTask task) async {
    try {
      state.value = AgentState(
        status: AgentStatus.thinking,
        currentTask: task.id,
        statusMessage: 'Processing task: ${task.type}',
      );
      
      logger.i('[$agentName] Executing task: ${task.type}');
      
      // Load relevant context from memory
      final context = await memory.retrieveRelevantContext(
        task.context['query'] ?? '',
        limit: 5,
      );
      
      // Execute task with context
      final result = await _executeWithContext(task, context);
      
      // Save decision to memory
      await _logDecision(task, result);
      
      state.value = AgentState(
        status: AgentStatus.idle,
        statusMessage: 'Task completed',
      );
      
      return result;
      
    } catch (e) {
      logger.e('[$agentName] Task execution error: $e');
      state.value = AgentState(
        status: AgentStatus.error,
        statusMessage: 'Task failed: $e',
      );
      
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Execute task with retrieved context (override in subclasses)
  Future<Map<String, dynamic>> _executeWithContext(
    AgentTask task,
    List<MemoryEntry> context,
  );
  
  /// Generate response using Gemini with function calling
  Future<Map<String, dynamic>> generateResponse({
    required String prompt,
    List<Content>? conversationHistory,
    Map<String, dynamic>? additionalContext,
  }) async {
    try {
      state.value = state.value.copyWith(status: AgentStatus.thinking);
      
      // Build conversation
      final chat = model.startChat(history: conversationHistory ?? []);
      
      // Add additional context to prompt if provided
      String enhancedPrompt = prompt;
      if (additionalContext != null) {
        enhancedPrompt = '$prompt\n\nContext: ${additionalContext.toString()}';
      }
      
      // Generate response
      final response = await chat.sendMessage(Content.text(enhancedPrompt));
      
      // Handle function calls
      if (response.functionCalls != null && response.functionCalls!.isNotEmpty) {
        return await _handleFunctionCalls(response.functionCalls!.toList(), chat);
      }
      
      // Return text response
      return {
        'success': true,
        'response': response.text ?? '',
        'type': 'text',
      };
      
    } catch (e) {
      logger.e('[$agentName] Response generation error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Handle function calls from Gemini
  Future<Map<String, dynamic>> _handleFunctionCalls(
    List<FunctionCall> functionCalls,
    ChatSession chat,
  ) async {
    state.value = state.value.copyWith(status: AgentStatus.executing);
    
    final functionResults = <FunctionResponse>[];
    
    for (final call in functionCalls) {
      logger.i('[$agentName] Executing function: ${call.name}');
      
      final result = await toolRegistry.executeTool(
        call.name,
        call.args,
      );
      
      functionResults.add(FunctionResponse(call.name, result));
    }
    
    // Send function results back to model
    final response = await chat.sendMessage(
      Content.functionResponses(functionResults),
    );
    
    return {
      'success': true,
      'response': response.text ?? '',
      'type': 'function_result',
      'functionCalls': functionCalls.map((c) => c.name).toList(),
    };
  }
  
  /// Log agent decision to memory
  Future<void> _logDecision(
    AgentTask task,
    Map<String, dynamic> result,
  ) async {
    final decision = AgentDecision(
      agentName: agentName,
      task: task.type,
      reasoning: result['reasoning'] ?? 'No reasoning provided',
      action: result['action'] ?? 'Unknown action',
      result: result,
    );
    
    await memory.saveDecision(decision);
  }
  
  /// Save interaction to memory
  Future<void> saveToMemory({
    required String content,
    required Map<String, dynamic> metadata,
  }) async {
    await memory.saveMemory(
      content: content,
      metadata: metadata,
    );
  }
  
  @override
  void onClose() {
    memory.dispose();
    super.onClose();
  }
}
