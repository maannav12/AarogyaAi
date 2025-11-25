import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logger/logger.dart';
import 'dart:async';

/// AgentTool represents a callable function that agents can use
typedef ToolFunction = Future<Map<String, dynamic>> Function(Map<String, dynamic> args);

class AgentTool {
  final String name;
  final String description;
  final Map<String, Schema> parameters;
  final ToolFunction function;
  
  AgentTool({
    required this.name,
    required this.description,
    required this.parameters,
    required this.function,
  });
  
  /// Convert to Gemini FunctionDeclaration
  FunctionDeclaration toGeminiFunctionDeclaration() {
    return FunctionDeclaration(
      name,
      description,
      Schema(
        SchemaType.object,
        properties: parameters,
        requiredProperties: parameters.keys.toList(),
      ),
    );
  }
}

/// AgentToolRegistry - Manages all available tools for agents
class AgentToolRegistry {
  final Map<String, AgentTool> _tools = {};
  final Logger _logger = Logger();
  
  /// Register a tool
  void registerTool(AgentTool tool) {
    _tools[tool.name] = tool;
    _logger.i('Registered tool: ${tool.name}');
  }
  
  /// Execute a tool by name
  Future<Map<String, dynamic>> executeTool(
    String toolName,
    Map<String, dynamic> args,
  ) async {
    if (!_tools.containsKey(toolName)) {
      _logger.e('Tool not found: $toolName');
      return {
        'success': false,
        'error': 'Tool not found: $toolName',
      };
    }
    
    try {
      _logger.i('Executing tool: $toolName with args: $args');
      final result = await _tools[toolName]!.function(args);
      return result;
    } catch (e) {
      _logger.e('Tool execution error for $toolName: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Get all function declarations for Gemini
  List<FunctionDeclaration> getGeminiFunctionDeclarations() {
    return _tools.values
        .map((tool) => tool.toGeminiFunctionDeclaration())
        .toList();
  }
  
  /// Get tool by name
  AgentTool? getTool(String name) => _tools[name];
  
  /// Get all tool names
  List<String> getToolNames() => _tools.keys.toList();
  
  /// Check if tool exists
  bool hasTool(String name) => _tools.containsKey(name);
  
  /// Remove a tool
  void removeTool(String name) {
    _tools.remove(name);
    _logger.i('Removed tool: $name');
  }
  
  /// Clear all tools
  void clearTools() {
    _tools.clear();
    _logger.i('Cleared all tools');
  }
}

/// Common tool definitions that can be used by any agent

class CommonAgentTools {
  
  /// Create a "get current time" tool
  static AgentTool getCurrentTimeTool() {
    return AgentTool(
      name: 'get_current_time',
      description: 'Get the current date and time in ISO 8601 format',
      parameters: {},
      function: (args) async {
        return {
          'success': true,
          'currentTime': DateTime.now().toIso8601String(),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
      },
    );
  }
  
  /// Create a "search memory" tool
  static AgentTool createSearchMemoryTool(Function(String query) searchFunction) {
    return AgentTool(
      name: 'search_memory',
      description: 'Search agent memory for relevant past conversations or data',
      parameters: {
        'query': Schema(
          SchemaType.string,
          description: 'The search query to find relevant memories',
        ),
        'limit': Schema(
          SchemaType.integer,
          description: 'Maximum number of results to return (default: 5)',
          nullable: true,
        ),
      },
      function: (args) async {
        final query = args['query'] as String;
        final limit = args['limit'] as int? ?? 5;
        
        final results = await searchFunction(query);
        
        return {
          'success': true,
          'results': results,
          'count': (results as List).length,
        };
      },
    );
  }
  
  /// Create a "save to memory" tool
  static AgentTool createSaveMemoryTool(
    Future<void> Function(String content, Map<String, dynamic> metadata) saveFunction
  ) {
    return AgentTool(
      name: 'save_to_memory',
      description: 'Save important information to long-term memory',
      parameters: {
        'content': Schema(
          SchemaType.string,
          description: 'The content to save to memory',
        ),
        'category': Schema(
          SchemaType.string,
          description: 'Category of the memory (e.g., "health_data", "user_preference", "decision")',
        ),
        'tags': Schema(
          SchemaType.array,
          description: 'Tags for categorizing the memory',
          items: Schema(SchemaType.string),
          nullable: true,
        ),
      },
      function: (args) async {
        final content = args['content'] as String;
        final category = args['category'] as String;
        final tags = args['tags'] as List<dynamic>? ?? [];
        
        await saveFunction(content, {
          'category': category,
          'tags': tags,
        });
        
        return {
          'success': true,
          'message': 'Saved to memory successfully',
        };
      },
    );
  }
  
  /// Create a "delegate to agent" tool (for orchestrator)
  static AgentTool createDelegateToAgentTool(
    Future<Map<String, dynamic>> Function(String agentName, Map<String, dynamic> task) delegateFunction
  ) {
    return AgentTool(
      name: 'delegate_to_agent',
      description: 'Delegate a task to a specialized agent',
      parameters: {
        'agentName': Schema(
          SchemaType.string,
          description: 'The name of the agent to delegate to (e.g., "diagnostic", "care", "emergency", "knowledge")',
          enumValues: ['diagnostic', 'care', 'emergency', 'knowledge'],
        ),
        'task': Schema(
          SchemaType.string,
          description: 'Description of the task to delegate',
        ),
        'context': Schema(
          SchemaType.object,
          description: 'Additional context for the task',
          nullable: true,
        ),
        'priority': Schema(
          SchemaType.integer,
          description: 'Task priority (0-10, higher is more urgent)',
          nullable: true,
        ),
      },
      function: (args) async {
        final agentName = args['agentName'] as String;
        final task = args['task'] as String;
        final context = args['context'] as Map<String, dynamic>? ?? {};
        final priority = args['priority'] as int? ?? 5;
        
        final result = await delegateFunction(agentName, {
          'task': task,
          'context': context,
          'priority': priority,
        });
        
        return result;
      },
    );
  }
  
  /// Create a "schedule followup" tool
  static AgentTool createScheduleFollowupTool(
    Future<void> Function(String message, DateTime scheduledTime) scheduleFunction
  ) {
    return AgentTool(
      name: 'schedule_followup',
      description: 'Schedule a follow-up reminder or task for the user',
      parameters: {
        'message': Schema(
          SchemaType.string,
          description: 'The reminder message to show the user',
        ),
        'hoursFromNow': Schema(
          SchemaType.integer,
          description: 'How many hours from now to schedule the reminder',
        ),
      },
      function: (args) async {
        final message = args['message'] as String;
        final hoursFromNow = args['hoursFromNow'] as int;
        
        final scheduledTime = DateTime.now().add(Duration(hours: hoursFromNow));
        
        await scheduleFunction(message, scheduledTime);
        
        return {
          'success': true,
          'message': 'Follow-up scheduled',
          'scheduledTime': scheduledTime.toIso8601String(),
        };
      },
    );
  }
  
  /// Create a "get user health data" tool
  static AgentTool createGetHealthDataTool(
    Future<List<Map<String, dynamic>>> Function(String dataType, int? limit) getDataFunction
  ) {
    return AgentTool(
      name: 'get_user_health_data',
      description: 'Retrieve user health data by type',
      parameters: {
        'dataType': Schema(
          SchemaType.string,
          description: 'Type of health data (e.g., "blood_pressure", "heart_rate", "symptoms", "medications")',
        ),
        'limit': Schema(
          SchemaType.integer,
          description: 'Maximum number of records to retrieve',
          nullable: true,
        ),
      },
      function: (args) async {
        final dataType = args['dataType'] as String;
        final limit = args['limit'] as int?;
        
        final data = await getDataFunction(dataType, limit);
        
        return {
          'success': true,
          'dataType': dataType,
          'records': data,
          'count': data.length,
        };
      },
    );
  }
}
