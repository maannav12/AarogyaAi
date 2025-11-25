import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'dart:async';
import 'dart:collection';
import 'base_agent.dart';

/// AgentRoute defines how tasks should be routed to agents
class AgentRoute {
  final String agentName;
  final List<String> keywords; // Keywords that trigger this agent
  final int priority;
  
  AgentRoute({
    required this.agentName,
    required this.keywords,
    this.priority = 0,
  });
}

/// AgentOrchestrator - Master coordinator for multi-agent system
/// Implements LangGraph-inspired workflow coordination
class AgentOrchestrator extends GetxController {
  final Logger logger = Logger();
  
  // Registered agents
  final Map<String, BaseAgent> _agents = {};
  
  // Task queue (priority queue)
  final PriorityQueue<AgentTask> _taskQueue = PriorityQueue<AgentTask>(
    (a, b) => b.priority.compareTo(a.priority), // Higher priority first
  );
  
  // Routing configuration
  final List<AgentRoute> _routes = [];
  
  // Current execution state
  final RxBool isProcessing = false.obs;
  final Rx<AgentTask?> currentTask = Rx<AgentTask?>(null);
  final RxList<String> activeAgents = <String>[].obs;
  
  // Execution history
  final List<Map<String, dynamic>> executionHistory = [];
  
  @override
  void onInit() {
    super.onInit();
    _setupDefaultRoutes();
    logger.i('[Orchestrator] Initialized');
  }
  
  /// Setup default routing rules
  void _setupDefaultRoutes() {
    _routes.addAll([
      AgentRoute(
        agentName: 'emergency',
        keywords: [
          'emergency', 'urgent', 'severe', 'chest pain', 'can\'t breathe',
          'unconscious', 'bleeding', 'stroke', 'heart attack'
        ],
        priority: 100, // Highest priority
      ),
      AgentRoute(
        agentName: 'diagnostic',
        keywords: [
          'scan', 'image', 'mri', 'x-ray', 'report', 'analyze', 'test results',
          'lab results', 'diagnosis', 'symptom'
        ],
        priority: 80,
      ),
      AgentRoute(
        agentName: 'care',
        keywords: [
          'exercise', 'diet', 'meal', 'medication', 'plan', 'routine',
          'adherence', 'reminder', 'therapy'
        ],
        priority: 60,
      ),
      AgentRoute(
        agentName: 'knowledge',
        keywords: [
          'what is', 'explain', 'tell me about', 'how does', 'information',
          'research', 'study', 'treatment', 'cause'
        ],
        priority: 40,
      ),
    ]);
  }
  
  /// Register an agent
  void registerAgent(String name, BaseAgent agent) {
    _agents[name] = agent;
    logger.i('[Orchestrator] Registered agent: $name');
  }
  
  /// Unregister an agent
  void unregisterAgent(String name) {
    _agents.remove(name);
    logger.i('[Orchestrator] Unregistered agent: $name');
  }
  
  /// Route a user query to appropriate agent(s)
  Future<Map<String, dynamic>> processQuery({
    required String query,
    Map<String, dynamic>? context,
    String? userId,
  }) async {
    logger.i('[Orchestrator] Processing query: $query');
    
    // Create task
    final task = AgentTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'user_query',
      context: {
        'query': query,
        'userId': userId,
        ...?context,
      },
    );
    
    // Determine routing
    final targetAgents = _determineRouting(query);
    
    if (targetAgents.isEmpty) {
      // Default to orchestrator agent (conversational)
      return await _handleConversationalQuery(task);
    }
    
    // Execute with appropriate agent(s)
    if (targetAgents.length == 1) {
      // Single agent execution
      return await _executeSingleAgent(targetAgents.first, task);
    } else {
      // Multi-agent collaboration
      return await _executeMultiAgent(targetAgents, task);
    }
  }
  
  /// Determine which agent(s) should handle the query
  List<String> _determineRouting(String query) {
    final queryLower = query.toLowerCase();
    final matches = <String, int>{}; // Agent name -> score
    
    for (final route in _routes) {
      int score = 0;
      
      for (final keyword in route.keywords) {
        if (queryLower.contains(keyword.toLowerCase())) {
          score += route.priority;
        }
      }
      
      if (score > 0) {
        matches[route.agentName] = score;
      }
    }
    
    // Sort by score and return top agents
    final sorted = matches.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Return agents with score > threshold
    const threshold = 40;
    return sorted
        .where((entry) => entry.value >= threshold)
        .map((entry) => entry.key)
        .toList();
  }
  
  /// Execute task with single agent
  Future<Map<String, dynamic>> _executeSingleAgent(
    String agentName,
    AgentTask task,
  ) async {
    if (!_agents.containsKey(agentName)) {
      logger.e('[Orchestrator] Agent not found: $agentName');
      return {
        'success': false,
        'error': 'Agent not available: $agentName',
      };
    }
    
    try {
      activeAgents.add(agentName);
      currentTask.value = task;
      
      final agent = _agents[agentName]!;
      final result = await agent.executeTask(task);
      
      _logExecution(agentName, task, result);
      
      return {
        'success': true,
        'agent': agentName,
        'result': result,
        'executionMode': 'single',
      };
      
    } catch (e) {
      logger.e('[Orchestrator] Single agent execution error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    } finally {
      activeAgents.remove(agentName);
      currentTask.value = null;
    }
  }
  
  /// Execute task with multiple agents (collaborative)
  Future<Map<String, dynamic>> _executeMultiAgent(
    List<String> agentNames,
    AgentTask task,
  ) async {
    logger.i('[Orchestrator] Multi-agent execution: $agentNames');
    
    final results = <String, Map<String, dynamic>>{};
    
    try {
      activeAgents.addAll(agentNames);
      currentTask.value = task;
      
      // Execute agents in parallel
      final futures = agentNames.map((name) async {
        if (_agents.containsKey(name)) {
          final result = await _agents[name]!.executeTask(task);
          return MapEntry(name, result);
        }
        return MapEntry(name, {
          'success': false,
          'error': 'Agent not available'
        });
      });
      
      final entries = await Future.wait(futures);
      results.addAll(Map.fromEntries(entries));
      
      // Synthesize results
      final synthesizedResult = await _synthesizeResults(results, task);
      
      _logExecution('multi-agent', task, synthesizedResult);
      
      return {
        'success': true,
        'agents': agentNames,
        'individualResults': results,
        'synthesizedResult': synthesizedResult,
        'executionMode': 'multi-agent',
      };
      
    } catch (e) {
      logger.e('[Orchestrator] Multi-agent execution error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    } finally {
      activeAgents.clear();
      currentTask.value = null;
    }
  }
  
  /// Synthesize results from multiple agents
  Future<Map<String, dynamic>> _synthesizeResults(
    Map<String, Map<String, dynamic>> agentResults,
    AgentTask task,
  ) async {
    // Simple synthesis: combine responses
    // In production, use an LLM to intelligently combine insights
    
    final combinedResponse = StringBuffer();
    combinedResponse.writeln('Based on analysis from multiple specialists:\n');
    
    for (final entry in agentResults.entries) {
      if (entry.value['success'] == true) {
        combinedResponse.writeln('**${entry.key.toUpperCase()} Agent:**');
        combinedResponse.writeln(entry.value['response'] ?? 'No response');
        combinedResponse.writeln();
      }
    }
    
    return {
      'success': true,
      'response': combinedResponse.toString(),
      'agentCount': agentResults.length,
    };
  }
  
  /// Handle conversational query (default orchestrator behavior)
  Future<Map<String, dynamic>> _handleConversationalQuery(AgentTask task) async {
    // This would use the Health Orchestrator agent
    // For now, return a simple response
    
    return {
      'success': true,
      'response': 'I\'m processing your query. This will be handled by the conversational agent.',
      'agent': 'orchestrator',
      'executionMode': 'conversational',
    };
  }
  
  /// Delegate task to specific agent (for agent-to-agent communication)
  Future<Map<String, dynamic>> delegateTask({
    required String targetAgent,
    required String taskType,
    required Map<String, dynamic> context,
    int priority = 5,
  }) async {
    final task = AgentTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: taskType,
      context: context,
      priority: priority,
    );
    
    return await _executeSingleAgent(targetAgent, task);
  }
  
  /// Add task to queue
  void enqueueTask(AgentTask task) {
    _taskQueue.add(task);
    logger.i('[Orchestrator] Task queued: ${task.id}');
    
    // Process queue if not already processing
    if (!isProcessing.value) {
      _processQueue();
    }
  }
  
  /// Process task queue
  Future<void> _processQueue() async {
    if (_taskQueue.isEmpty || isProcessing.value) return;
    
    isProcessing.value = true;
    
    while (_taskQueue.isNotEmpty) {
      final task = _taskQueue.removeFirst();
      
      await processQuery(
        query: task.context['query'] ?? '',
        context: task.context,
      );
    }
    
    isProcessing.value = false;
  }
  
  /// Log execution for analysis
  void _logExecution(
    String agentName,
    AgentTask task,
    Map<String, dynamic> result,
  ) {
    executionHistory.add({
      'timestamp': DateTime.now().toIso8601String(),
      'agent': agentName,
      'taskId': task.id,
      'taskType': task.type,
      'success': result['success'] ?? false,
      'duration': 0, // TODO: Track actual duration
    });
    
    // Keep history size manageable
    if (executionHistory.length > 100) {
      executionHistory.removeRange(0, 50);
    }
  }
  
  /// Get execution statistics
  Map<String, dynamic> getExecutionStats() {
    final totalTasks = executionHistory.length;
    final successfulTasks = executionHistory
        .where((e) => e['success'] == true)
        .length;
    
    final agentUsage = <String, int>{};
    for (final entry in executionHistory) {
      final agent = entry['agent'] as String;
      agentUsage[agent] = (agentUsage[agent] ?? 0) + 1;
    }
    
    return {
      'totalTasks': totalTasks,
      'successfulTasks': successfulTasks,
      'successRate': totalTasks > 0 ? successfulTasks / totalTasks : 0,
      'agentUsage': agentUsage,
      'activeAgents': activeAgents.toList(),
      'queuedTasks': _taskQueue.length,
    };
  }
  
  @override
  void onClose() {
    // Cleanup agents
    for (final agent in _agents.values) {
      agent.onClose();
    }
    super.onClose();
  }
}

/// Priority Queue implementation
class PriorityQueue<E> {
  final List<E> _elements = [];
  final Comparator<E> _comparator;
  
  PriorityQueue(this._comparator);
  
  void add(E element) {
    _elements.add(element);
    _elements.sort(_comparator);
  }
  
  E removeFirst() {
    return _elements.removeAt(0);
  }
  
  bool get isEmpty => _elements.isEmpty;
  bool get isNotEmpty => _elements.isNotEmpty;
  int get length => _elements.length;
  
  E? get first => _elements.isEmpty ? null : _elements.first;
}
