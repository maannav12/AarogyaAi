import 'dart:io';
import 'dart:typed_data';
import '../agent_architecture/base_agent.dart';
import '../agent_architecture/agent_memory.dart';
import '../agent_architecture/agent_tools.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/render_api_service.dart';
import '../../services/tflite_service.dart';

/// DiagnosticAnalysisAgent - Medical image and report analysis expert
/// 
/// This agent specializes in analyzing medical images (MRI, X-Ray, Skin),
/// interpreting lab reports, and providing doctor-like explanations.
class DiagnosticAnalysisAgent extends BaseAgent {
  final RenderApiService? _apiService;
  final TfliteService? _tfliteService;
  
  DiagnosticAnalysisAgent({
    required String geminiApiKey,
    RenderApiService? apiService,
    TfliteService? tfliteService,
  }) : _apiService = apiService ?? RenderApiService(),
       _tfliteService = tfliteService ?? TfliteService(),
       super(
    agentName: 'diagnostic',
    agentRole: 'Medical Diagnostic Analysis Specialist',
    systemPrompt: '''
You are a specialized AI diagnostic assistant with expertise in medical image analysis and report interpretation.

Your capabilities:
1. Analyze medical images (MRI, X-Ray, Skin conditions) using both ML models and visual analysis
2. Extract and interpret lab report values from images
3. Compare results against normal ranges and patient history
4. Identify trends and anomalies in health data
5. Generate detailed, doctor-like explanations in Hindi or English

Your analysis process:
1. First, use available ML models (TFLite classifier) to get initial classification
2. Then, analyze the image visually using your multimodal capabilities
3. Cross-reference with patient history if available
4. Provide comprehensive interpretation with:
   - What the image/report shows
   - Whether findings are normal or concerning
   - Possible causes or explanations
   - Recommended next steps
   - Urgency level (routine, urgent, emergency)

Key guidelines:
- Always include confidence levels in your assessments
- Highlight any concerning findings prominently
- Explain medical terminology in simple language
- Recommend professional medical consultation for concerning findings
- Note limitations of AI analysis vs. professional medical diagnosis
- Provide responses in the user's preferred language

Use the following tools:
- "analyze_medical_image": Run ML model classification on medical images
- "extract_lab_values": Extract structured data from lab reports
- "compare_historical_data": Find trends in patient's previous test results
''',
    geminiApiKey: geminiApiKey,
    modelName: 'gemini-2.0-flash',
  );
  
  @override
  void onInit() {
    super.onInit();
    // Initialize TFLite models
    if (_tfliteService != null) {
      _initializeTFLiteModels();
    }
  }
  
  Future<void> _initializeTFLiteModels() async {
    try {
      // Models will be loaded on-demand
      logger.i('[DiagnosticAgent] TFLite service ready');
    } catch (e) {
      logger.e('[DiagnosticAgent] TFLite initialization error: $e');
    }
  }
  
  @override
  void registerTools() {
    // Register common tools
    toolRegistry.registerTool(CommonAgentTools.getCurrentTimeTool());
    
    toolRegistry.registerTool(
      CommonAgentTools.createSaveMemoryTool(
        (content, metadata) => saveToMemory(content: content, metadata: metadata),
      ),
    );
    
    // Register diagnostic-specific tools
    _registerDiagnosticTools();
  }
  
  void _registerDiagnosticTools() {
    // Analyze medical image tool
    toolRegistry.registerTool(
      AgentTool(
        name: 'analyze_medical_image',
        description: 'Analyze a medical image using ML classification models',
        parameters: {
          'imagePath': Schema(
            SchemaType.string,
            description: 'Path to the medical image file',
          ),
          'imageType': Schema(
            SchemaType.string,
            description: 'Type of medical image: "mri", "xray", or "skin"',
            enumValues: ['mri', 'xray', 'skin'],
          ),
        },
        function: (args) async {
          final imagePath = args['imagePath'] as String;
          final imageType = args['imageType'] as String;
          
          try {
            // Load appropriate model
            await _tfliteService?.loadModel(imageType);
            
            // Run inference
            final XFile imageFile = XFile(imagePath);
            final output = await _tfliteService?.runInference(imageFile);
            
            if (output == null || output.isEmpty) {
              return {
                'success': false,
                'error': 'Model inference failed',
              };
            }
            
            // Sort results by confidence
            final sortedResults = output.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            
            return {
              'success': true,
              'imageType': imageType,
              'predictions': sortedResults.map((e) => {
                'class': e.key,
                'confidence': e.value,
              }).toList(),
              'topPrediction': sortedResults.first.key,
              'topConfidence': sortedResults.first.value,
            };
          } catch (e) {
            logger.e('[DiagnosticAgent] Image analysis error: $e');
            return {
              'success': false,
              'error': e.toString(),
            };
          }
        },
      ),
    );
    
    // Extract lab values tool
    toolRegistry.registerTool(
      AgentTool(
        name: 'extract_lab_values',
        description: 'Extract structured lab test values from a medical report image using OCR',
        parameters: {
          'imagePath': Schema(
            SchemaType.string,
            description: 'Path to the lab report image',
          ),
        },
        function: (args) async {
          final imagePath = args['imagePath'] as String;
          
          // This would integrate with OCR and structured extraction
          // For now, return a placeholder
          // TODO: Implement actual OCR-based extraction
          
          return {
            'success': true,
            'extractedValues': [
              {
                'test': 'Hemoglobin',
                'value': '13.5',
                'unit': 'g/dL',
                'normalRange': '12-16 g/dL',
                'isNormal': true,
              },
              // More values would be extracted here
            ],
            'reportDate': DateTime.now().toIso8601String(),
          };
        },
      ),
    );
    
    // Compare with historical data tool
    toolRegistry.registerTool(
      AgentTool(
        name: 'compare_historical_data',
        description: 'Compare current test results with patient\'s historical data to identify trends',
        parameters: {
          'userId': Schema(
            SchemaType.string,
            description: 'User ID to retrieve historical data for',
          ),
          'testType': Schema(
            SchemaType.string,
            description: 'Type of test (e.g., "blood_pressure", "hemoglobin", "glucose")',
          ),
          'currentValue': Schema(
            SchemaType.number,
            description: 'Current test value to compare',
          ),
        },
        function: (args) async {
          final userId = args['userId'] as String;
          final testType = args['testType'] as String;
          final currentValue = args['currentValue'] as num;
          
          // Get historical data from memory
          final historicalData = await memory.getHealthData(
            userId: userId,
            dataType: testType,
            limit: 10,
          );
          
          if (historicalData.isEmpty) {
            return {
              'success': true,
              'trend': 'no_history',
              'message': 'No historical data available for comparison',
            };
          }
          
          // Calculate trend
          final values = historicalData
              .map((d) => (d['value'] as num).toDouble())
              .toList();
          
          final average = values.reduce((a, b) => a + b) / values.length;
          final percentageChange = ((currentValue - average) / average * 100).abs();
          
          String trend = 'stable';
          if (percentageChange > 10) {
            trend = currentValue > average ? 'increasing' : 'decreasing';
          }
          
          return {
            'success': true,
            'trend': trend,
            'currentValue': currentValue,
            'historicalAverage': average,
            'percentageChange': percentageChange,
            'dataPoints': values.length,
          };
        },
      ),
    );
    
    // Generate interpretation tool
    toolRegistry.registerTool(
      AgentTool(
        name: 'generate_medical_interpretation',
        description: 'Generate a comprehensive, doctor-like interpretation of medical findings',
        parameters: {
          'findings': Schema(
            SchemaType.object,
            description: 'Medical findings from analysis',
          ),
          'language': Schema(
            SchemaType.string,
            description: 'Language for interpretation (en or hi)',
            nullable: true,
          ),
        },
        function: (args) async {
          final findings = args['findings'] as Map<String, dynamic>;
          final language = args['language'] as String? ?? 'en';
          
          // This would use Gemini to generate interpretation
          // For now, return a structured template
          
          return {
            'success': true,
            'interpretation': {
              'summary': 'Based on the analysis...',
              'detailedFindings': 'The image shows...',
              'normalityAssessment': 'The findings appear...',
              'recommendations': [
                'Consider follow-up imaging in 3 months',
                'Consult with a specialist',
              ],
              'urgencyLevel': 'routine', // routine, urgent, emergency
            },
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
    final taskType = task.type;
    
    if (taskType == 'analyze_image') {
      return await _handleImageAnalysis(task);
    } else if (taskType == 'interpret_report') {
      return await _handleReportInterpretation(task);
    } else {
      // General diagnostic query
      return await _handleGeneralQuery(task, context);
    }
  }
  
  /// Handle medical image analysis
  Future<Map<String, dynamic>> _handleImageAnalysis(AgentTask task) async {
    final imagePath = task.context['imagePath'] as String;
    final imageType = task.context['imageType'] as String;
    final userId = task.context['userId'] as String?;
    
    logger.i('[DiagnosticAgent] Analyzing $imageType image: $imagePath');
    
    // Step 1: Run ML model classification
    final mlResult = await toolRegistry.executeTool(
      'analyze_medical_image',
      {
        'imagePath': imagePath,
        'imageType': imageType,
      },
    );
    
    // Step 2: Perform visual analysis with Gemini Vision
    final imageBytes = await File(imagePath).readAsBytes();
    final visualAnalysis = await _analyzeImageWithGemini(imageBytes, imageType, mlResult);
    
    // Step 3: Compare with historical data if user ID provided
    Map<String, dynamic>? historicalComparison;
    if (userId != null && mlResult['success'] == true) {
      // Extract relevant test type from ML result
      // This is a simplified example
      historicalComparison = await toolRegistry.executeTool(
        'compare_historical_data',
        {
          'userId': userId,
          'testType': imageType,
          'currentValue': mlResult['topConfidence'],
        },
      );
    }
    
    // Save analysis to memory
    await saveToMemory(
      content: 'Analyzed $imageType image. ML Classification: ${mlResult['topPrediction'] ?? 'N/A'}. '
               'Visual Analysis: ${visualAnalysis['summary'] ?? 'N/A'}',
      metadata: {
        'type': 'diagnostic_analysis',
        'imageType': imageType,
        'userId': userId,
      },
    );
    
    return {
      'success': true,
      'imageType': imageType,
      'mlClassification': mlResult,
      'visualAnalysis': visualAnalysis,
      'historicalComparison': historicalComparison,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  /// Analyze image using Gemini's multimodal capabilities
  Future<Map<String, dynamic>> _analyzeImageWithGemini(
    Uint8List imageBytes,
    String imageType,
    Map<String, dynamic> mlResult,
  ) async {
    try {
      final prompt = '''
Analyze this $imageType medical image. 

ML model classification results: ${mlResult['topPrediction'] ?? 'N/A'} with ${(mlResult['topConfidence'] ?? 0) * 100}% confidence.

Provide:
1. Visual description of what you see in the image
2. Assessment of whether findings appear normal or abnormal
3. Any specific patterns, lesions, or abnormalities
4. Correlation with ML classification
5. Confidence level in your visual assessment
6. Recommended next steps

Respond in a structured, doctor-like manner.
''';
      
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];
      
      final response = await model.generateContent(content);
      
      return {
        'success': true,
        'summary': response.text ?? '',
        'confidence': 0.8, // Gemini doesn't provide confidence, use estimate
      };
      
    } catch (e) {
      logger.e('[DiagnosticAgent] Gemini vision analysis error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Handle lab report interpretation
  Future<Map<String, dynamic>> _handleReportInterpretation(AgentTask task) async {
    final imagePath = task.context['imagePath'] as String;
    
    // Extract values using OCR
    final extractionResult = await toolRegistry.executeTool(
      'extract_lab_values',
      {'imagePath': imagePath},
    );
    
    // Generate interpretation
    final interpretation = await toolRegistry.executeTool(
      'generate_medical_interpretation',
      {
        'findings': extractionResult,
        'language': task.context['language'] ?? 'en',
      },
    );
    
    return {
      'success': true,
      'extractedValues': extractionResult,
      'interpretation': interpretation,
    };
  }
  
  /// Handle general diagnostic query
  Future<Map<String, dynamic>> _handleGeneralQuery(
    AgentTask task,
    List<MemoryEntry> context,
  ) async {
    final query = task.context['query'] as String;
    
    // Use Gemini to process the query with diagnostic expertise
    final result = await generateResponse(
      prompt: query,
      additionalContext: {
        'previousDiagnostics': context.map((c) => c.content).toList(),
      },
    );
    
    return result;
  }
  
  @override
  void onClose() {
    _tfliteService?.dispose();
    super.onClose();
  }
}
