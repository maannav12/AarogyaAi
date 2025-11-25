import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logger/logger.dart';
import 'dart:async';

/// Centralized Gemini API service optimized for agent usage
class GeminiAgentService {
  final String apiKey;
  final Logger logger = Logger();
  
  // Model instances cache
  final Map<String, GenerativeModel> _models = {};
  
  // Token usage tracking
  int _totalInputTokens = 0;
  int _totalOutputTokens = 0;
  final List<Map<String, dynamic>> _usageHistory = [];
  
  GeminiAgentService({required this.apiKey});
  
  /// Get or create a model instance
  GenerativeModel getModel({
    String modelName = 'gemini-2.0-flash',
    List<Tool>? tools,
    GenerationConfig? config,
    Content? systemInstruction,
  }) {
    final cacheKey = _getCacheKey(modelName, tools?.length ?? 0);
    
    if (_models.containsKey(cacheKey)) {
      return _models[cacheKey]!;
    }
    
    final model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      generationConfig: config ?? _getDefaultConfig(),
      tools: tools,
      systemInstruction: systemInstruction,
    );
    
    _models[cacheKey] = model;
    logger.i('[GeminiService] Created model: $modelName');
    
    return model;
  }
  
  /// Generate content with automatic retry and error handling
  Future<GenerateContentResponse> generateContent({
    required List<Content> contents,
    String modelName = 'gemini-2.0-flash',
    List<Tool>? tools,
    Content? systemInstruction,
    int maxRetries = 3,
  }) async {
    final model = getModel(
      modelName: modelName,
      tools: tools,
      systemInstruction: systemInstruction,
    );
    
    int attempts = 0;
    Duration retryDelay = const Duration(seconds: 2);
    
    while (attempts < maxRetries) {
      try {
        final response = await model.generateContent(contents);
        
        // Track token usage (if available in response metadata)
        _trackUsage(modelName, contents, response);
        
        return response;
        
      } catch (e) {
        attempts++;
        logger.w('[GeminiService] Attempt $attempts failed: $e');
        
        if (attempts >= maxRetries) {
          logger.e('[GeminiService] Max retries exceeded');
          rethrow;
        }
        
        // Exponential backoff
        await Future.delayed(retryDelay);
        retryDelay *= 2;
      }
    }
    
    throw Exception('Failed to generate content after $maxRetries attempts');
  }
  
  /// Stream content generation (for real-time responses)
  Stream<GenerateContentResponse> generateContentStream({
    required List<Content> contents,
    String modelName = 'gemini-2.0-flash',
    List<Tool>? tools,
    Content? systemInstruction,
  }) {
    final model = getModel(
      modelName: modelName,
      tools: tools,
      systemInstruction: systemInstruction,
    );
    
    return model.generateContentStream(contents);
  }
  
  /// Create chat session with conversation history
  ChatSession createChatSession({
    String modelName = 'gemini-2.0-flash',
    List<Content>? history,
    List<Tool>? tools,
    Content? systemInstruction,
  }) {
    final model = getModel(
      modelName: modelName,
      tools: tools,
      systemInstruction: systemInstruction,
    );
    
    return model.startChat(history: history ?? []);
  }
  
  /// Send message with function calling support
  Future<Map<String, dynamic>> sendMessageWithFunctions({
    required ChatSession chat,
    required String message,
    required Function(String functionName, Map<String, dynamic> args) onFunctionCall,
  }) async {
    try {
      // Send initial message
      GenerateContentResponse response = await chat.sendMessage(
        Content.text(message),
      );
      
      // Handle function calls
      while (response.functionCalls != null && response.functionCalls!.isNotEmpty) {
        logger.i('[GeminiService] Processing ${response.functionCalls!.length} function calls');
        
        final functionResults = <FunctionResponse>[];
        
        for (final call in response.functionCalls!) {
          logger.i('[GeminiService] Calling function: ${call.name}');
          
          final result = await onFunctionCall(call.name, call.args);
          functionResults.add(FunctionResponse(call.name, result));
        }
        
        // Send results back
        response = await chat.sendMessage(
          Content.functionResponses(functionResults),
        );
      }
      
      return {
        'success': true,
        'text': response.text ?? '',
        'response': response,
      };
      
    } catch (e) {
      logger.e('[GeminiService] Chat error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Embed text for semantic search
  Future<List<double>> embedText(String text) async {
    try {
      final model = getModel(modelName: 'text-embedding-004');
      
      final result = await model.embedContent(
        Content.text(text),
      );
      
      return result.embedding.values.toList();
      
    } catch (e) {
      logger.e('[GeminiService] Embedding error: $e');
      return [];
    }
  }
  
  /// Batch embed multiple texts
  Future<List<List<double>>> embedBatch(List<String> texts) async {
    try {
      final model = getModel(modelName: 'text-embedding-004');
      
      final results = await Future.wait(
        texts.map((text) => model.embedContent(Content.text(text))),
      );
      
      return results.map((r) => r.embedding.values.toList()).toList();
      
    } catch (e) {
      logger.e('[GeminiService] Batch embedding error: $e');
      return [];
    }
  }
  
  /// Summarize long text (for context management)
  Future<String> summarizeText({
    required String text,
    int maxWords = 100,
  }) async {
    try {
      final response = await generateContent(
        contents: [
          Content.text(
            'Summarize the following text in approximately $maxWords words, '
            'preserving the most important information:\n\n$text'
          ),
        ],
        modelName: 'gemini-2.0-flash',
      );
      
      return response.text ?? text;
      
    } catch (e) {
      logger.e('[GeminiService] Summarization error: $e');
      return text;
    }
  }
  
  /// Get default generation config
  GenerationConfig _getDefaultConfig() {
    return GenerationConfig(
      temperature: 0.7,
      topK: 40,
      topP: 0.95,
      maxOutputTokens: 2048,
    );
  }
  
  /// Get cache key for model instances
  String _getCacheKey(String modelName, int toolsCount) {
    return '${modelName}_tools_$toolsCount';
  }
  
  /// Track API usage
  void _trackUsage(
    String modelName,
    List<Content> contents,
    GenerateContentResponse response,
  ) {
    // Estimate token counts (Gemini API doesn't always provide this)
    final inputLength = contents
        .map((c) => c.parts.map((p) => p.toString().length).fold(0, (a, b) => a + b))
        .fold(0, (a, b) => a + b);
    
    final outputLength = response.text?.length ?? 0;
    
    // Rough estimation: 1 token ≈ 4 characters
    final estimatedInputTokens = (inputLength / 4).round();
    final estimatedOutputTokens = (outputLength / 4).round();
    
    _totalInputTokens += estimatedInputTokens;
    _totalOutputTokens += estimatedOutputTokens;
    
    _usageHistory.add({
      'timestamp': DateTime.now().toIso8601String(),
      'model': modelName,
      'inputTokens': estimatedInputTokens,
      'outputTokens': estimatedOutputTokens,
    });
    
    // Keep history size manageable
    if (_usageHistory.length > 1000) {
      _usageHistory.removeRange(0, 500);
    }
    
    logger.d('[GeminiService] Token usage - Input: $estimatedInputTokens, Output: $estimatedOutputTokens');
  }
  
  /// Get usage statistics
  Map<String, dynamic> getUsageStats() {
    final costPerMillionInputTokens = 0.075; // USD for gemini-2.0-flash
    final costPerMillionOutputTokens = 0.30;
    
    final estimatedCost = 
        (_totalInputTokens / 1000000 * costPerMillionInputTokens) +
        (_totalOutputTokens / 1000000 * costPerMillionOutputTokens);
    
    return {
      'totalInputTokens': _totalInputTokens,
      'totalOutputTokens': _totalOutputTokens,
      'totalTokens': _totalInputTokens + _totalOutputTokens,
      'estimatedCostUSD': estimatedCost.toStringAsFixed(4),
      'requestCount': _usageHistory.length,
    };
  }
  
  /// Reset usage tracking
  void resetUsageTracking() {
    _totalInputTokens = 0;
    _totalOutputTokens = 0;
    _usageHistory.clear();
    logger.i('[GeminiService] Usage tracking reset');
  }
  
  /// Clear model cache
  void clearModelCache() {
    _models.clear();
    logger.i('[GeminiService] Model cache cleared');
  }
}
