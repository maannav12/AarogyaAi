import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:convert';
import 'base_agent.dart';

/// MemoryEntry represents a single memory item
class MemoryEntry {
  final String id;
  final String agentName;
  final String content;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final double? relevanceScore; // For semantic search results
  
  MemoryEntry({
    required this.id,
    required this.agentName,
    required this.content,
    required this.metadata,
    DateTime? timestamp,
    this.relevanceScore,
  }) : timestamp = timestamp ?? DateTime.now();
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'agentName': agentName,
    'content': content,
    'metadata': jsonEncode(metadata),
    'timestamp': timestamp.toIso8601String(),
  };
  
  factory MemoryEntry.fromJson(Map<String, dynamic> json) => MemoryEntry(
    id: json['id'],
    agentName: json['agentName'],
    content: json['content'],
    metadata: jsonDecode(json['metadata']),
    timestamp: DateTime.parse(json['timestamp']),
    relevanceScore: json['relevanceScore'],
  );
}

/// AgentMemory - Manages persistent and working memory for agents
class AgentMemory {
  final String agentName;
  late Database _database;
  late GetStorage _workingMemory;
  
  // Configuration
  final int maxWorkingMemorySize = 50; // Keep last 50 items in working memory
  final int maxLongTermMemoryDays = 90; // Keep memories for 90 days
  
  AgentMemory({required this.agentName});
  
  /// Initialize memory storage
  Future<void> initialize() async {
    await _initializeDatabase();
    await _initializeWorkingMemory();
  }
  
  /// Initialize SQLite database for long-term memory
  Future<void> _initializeDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'agent_memory.db');
    
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Memory table
        await db.execute('''
          CREATE TABLE memories (
            id TEXT PRIMARY KEY,
            agentName TEXT,
            content TEXT,
            metadata TEXT,
            timestamp TEXT,
            UNIQUE(id)
          )
        ''');
        
        // Decision log table
        await db.execute('''
          CREATE TABLE decisions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            agentName TEXT,
            task TEXT,
            reasoning TEXT,
            action TEXT,
            result TEXT,
            timestamp TEXT
          )
        ''');
        
        // User health data table
        await db.execute('''
          CREATE TABLE health_data (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId TEXT,
            dataType TEXT,
            value TEXT,
            metadata TEXT,
            timestamp TEXT
          )
        ''');
        
        // Create indexes for faster queries
        await db.execute('CREATE INDEX idx_memories_agent ON memories(agentName)');
        await db.execute('CREATE INDEX idx_memories_timestamp ON memories(timestamp)');
        await db.execute('CREATE INDEX idx_decisions_agent ON decisions(agentName)');
        await db.execute('CREATE INDEX idx_health_data_user ON health_data(userId)');
      },
    );
  }
  
  /// Initialize working memory (in-memory cache)
  Future<void> _initializeWorkingMemory() async {
    await GetStorage.init('agent_working_memory_$agentName');
    _workingMemory = GetStorage('agent_working_memory_$agentName');
  }
  
  /// Save memory entry
  Future<void> saveMemory({
    required String content,
    required Map<String, dynamic> metadata,
  }) async {
    final entry = MemoryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      agentName: agentName,
      content: content,
      metadata: metadata,
    );
    
    // Save to database (long-term)
    await _database.insert(
      'memories',
      entry.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // Update working memory
    await _updateWorkingMemory(entry);
    
    // Cleanup old memories
    await _cleanupOldMemories();
  }
  
  /// Update working memory with new entry
  Future<void> _updateWorkingMemory(MemoryEntry entry) async {
    List<dynamic> workingMem = _workingMemory.read('recent_memories') ?? [];
    
    // Add new entry
    workingMem.insert(0, entry.toJson());
    
    // Limit size
    if (workingMem.length > maxWorkingMemorySize) {
      workingMem = workingMem.sublist(0, maxWorkingMemorySize);
    }
    
    await _workingMemory.write('recent_memories', workingMem);
  }
  
  /// Retrieve relevant context (simplified semantic search)
  /// In a production system, this would use vector embeddings and similarity search
  Future<List<MemoryEntry>> retrieveRelevantContext(
    String query,
    {int limit = 5}
  ) async {
    // For now, implement keyword-based search
    // TODO: Implement actual vector similarity search with embeddings
    
    final results = await _database.query(
      'memories',
      where: 'agentName = ? AND content LIKE ?',
      whereArgs: [agentName, '%$query%'],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    
    return results.map((json) => MemoryEntry.fromJson(json)).toList();
  }
  
  /// Get recent memories from working memory
  List<MemoryEntry> getRecentMemories({int limit = 10}) {
    List<dynamic> workingMem = _workingMemory.read('recent_memories') ?? [];
    
    return workingMem
        .take(limit)
        .map((json) => MemoryEntry.fromJson(json))
        .toList();
  }
  
  /// Save agent decision
  Future<void> saveDecision(AgentDecision decision) async {
    await _database.insert(
      'decisions',
      {
        'agentName': decision.agentName,
        'task': decision.task,
        'reasoning': decision.reasoning,
        'action': decision.action,
        'result': jsonEncode(decision.result),
        'timestamp': decision.timestamp.toIso8601String(),
      },
    );
  }
  
  /// Get decision history
  Future<List<AgentDecision>> getDecisionHistory({int limit = 20}) async {
    final results = await _database.query(
      'decisions',
      where: 'agentName = ?',
      whereArgs: [agentName],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    
    return results.map((json) => AgentDecision(
      agentName: json['agentName'] as String,
      task: json['task'] as String,
      reasoning: json['reasoning'] as String,
      action: json['action'] as String,
      result: jsonDecode(json['result'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
    )).toList();
  }
  
  /// Save user health data
  Future<void> saveHealthData({
    required String userId,
    required String dataType,
    required dynamic value,
    Map<String, dynamic>? metadata,
  }) async {
    await _database.insert(
      'health_data',
      {
        'userId': userId,
        'dataType': dataType,
        'value': jsonEncode(value),
        'metadata': jsonEncode(metadata ?? {}),
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
  
  /// Get user health data by type
  Future<List<Map<String, dynamic>>> getHealthData({
    required String userId,
    required String dataType,
    int? limit,
  }) async {
    final results = await _database.query(
      'health_data',
      where: 'userId = ? AND dataType = ?',
      whereArgs: [userId, dataType],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    
    return results.map((row) => {
      'id': row['id'],
      'userId': row['userId'],
      'dataType': row['dataType'],
      'value': jsonDecode(row['value'] as String),
      'metadata': jsonDecode(row['metadata'] as String),
      'timestamp': DateTime.parse(row['timestamp'] as String),
    }).toList();
  }
  
  /// Get conversation summary (for context management)
  Future<String> getConversationSummary({int lastNMessages = 10}) async {
    final recentMemories = getRecentMemories(limit: lastNMessages);
    
    if (recentMemories.isEmpty) {
      return 'No recent conversation history.';
    }
    
    // Simple summarization (in production, use Gemini to generate summary)
    final messages = recentMemories
        .map((m) => m.content)
        .join('\n');
    
    return 'Recent conversation:\n$messages';
  }
  
  /// Cleanup old memories to keep database size manageable
  Future<void> _cleanupOldMemories() async {
    final cutoffDate = DateTime.now().subtract(
      Duration(days: maxLongTermMemoryDays),
    );
    
    await _database.delete(
      'memories',
      where: 'timestamp < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }
  
  /// Clear all memories (for testing/debugging)
  Future<void> clearAllMemories() async {
    await _database.delete('memories');
    await _database.delete('decisions');
    await _workingMemory.erase();
  }
  
  /// Dispose resources
  void dispose() {
    _database.close();
  }
}
