# AI Agent System - README

## Overview

AarogyaAi now features an advanced multi-agent AI system that transforms the app from reactive to proactive, intelligent healthcare assistance.

## Architecture

### Core Components

1. **Agent Architecture** (`lib/agents/agent_architecture/`)
   - `base_agent.dart` - Abstract base class for all agents
   - `agent_memory.dart` - Persistent memory with SQLite + working memory cache
   - `agent_tools.dart` - Tool registry and function calling framework
   - `agent_orchestrator.dart` - LangGraph-inspired multi-agent coordinator

2. **Specialized Agents** (`lib/agents/specialized/`)
   - `health_orchestrator_agent.dart` - Master conversational AI
   - `diagnostic_analysis_agent.dart` - Medical image/report analysis expert
   - (More agents to be added in future phases)

3. **Services** (`lib/services/`)
   - `gemini_agent_service.dart` - Centralized Gemini API service with retry, streaming, embeddings

## Quick Start

### 1. Initialize the Agent System

In your `main.dart`:

```dart
import 'package:aarogya/agents/agent_system_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GetStorage.init();
  
  // Initialize multi-agent system
  final agentSystem = AgentSystemManager.getInstance(
    geminiApiKey: 'YOUR_GEMINI_API_KEY', // Use from env or config
  );
  await agentSystem.initialize();
  
  runApp(MyApp());
}
```

### 2. Using Agents in Your Controllers

**Example: Enhanced Chatbot**

```dart
import 'package:aarogya/agents/agent_system_manager.dart';

class ChatbotController extends GetxController {
  final agentSystem = AgentSystemManager.getInstance();
  
  Future<void> sendMessage(String message) async {
    // Route message through intelligent agent system
    final result = await agentSystem.processQuery(
      query: message,
      userId: currentUserId,
    );
    
    if (result['success']) {
      // Show response in UI
      addMessage(result['response']);
      
      // Show which agent(s) handled it
      if (result['executionMode'] == 'multi-agent') {
        print('Collaborative response from: ${result['agents']}');
      }
    }
  }
}
```

**Example: Medical Image Analysis**

```dart
Future<void> analyzeMedicalScan(String imagePath, String type) async {
  final result = await Get.agentSystem.analyzeMedicalImage(
    imagePath: imagePath,
    imageType: type, // 'mri', 'xray', or 'skin'
    userId: currentUserId,
  );
  
  if (result['success']) {
    // ML classification
    print('Classification: ${result['mlClassification']['topPrediction']}');
    
    // Gemini Vision analysis
    print('Visual Analysis: ${result['visualAnalysis']['summary']}');
    
    // Historical comparison
    if (result['historicalComparison'] != null) {
      print('Trend: ${result['historicalComparison']['trend']}');
    }
  }
}
``

### 3. Proactive Features

**Daily Health Check-In:**

```dart
// Schedule this with workmanager for background execution
Future<void> morningHealthCheckIn() async {
  final insight = await Get.agentSystem.generateDailyInsights(userId);
  
  // Show as notification or in-app message
  showNotification(
    title: 'Good Morning! Your Health Insights',
    body: insight['response'],
  );
}
```

## Agent Capabilities

### Health Orchestrator Agent

**Purpose:** Master conversational AI and coordinator

**Capabilities:**
- Natural language health conversations
- Intent detection and routing
- Proactive health check-ins
- Daily insight generation
- User context management

**Tools:**
- `get_user_context` - Retrieve user health profile
- `summarize_health_status` - Generate health summaries
- `detect_user_intent` - Understand query intent and urgency

### Diagnostic Analysis Agent

**Purpose:** Medical image and report analysis

**Capabilities:**
- Multi-modal analysis (ML models + Gemini Vision)
- Lab report interpretation with OCR
- Historical trend analysis
- Doctor-like explanations in Hindi/English

**Tools:**
- `analyze_medical_image` - Run TFLite + Vision analysis
- `extract_lab_values` - OCR-based value extraction
- `compare_historical_data` - Trend identification
- `generate_medical_interpretation` - Comprehensive reports

## Agent Routing

The orchestrator automatically routes queries based on keywords:

-**Emergency** (Priority: 100)
  - Keywords: "emergency", "urgent", "severe", "chest pain", "can't breathe"
  
- **Diagnostic** (Priority: 80)
  - Keywords: "scan", "image", "mri", "x-ray", "report", "analyze", "symptoms"
  
- **Care Plan** (Priority: 60)
  - Keywords: "exercise", "diet", "medication", "plan", "routine"
  
- **Knowledge** (Priority: 40)
  - Keywords: "what is", "explain", "tell me about", "how does"

## Memory System

Agents have two types of memory:

### 1. Working Memory (Fast, In-RAM)
- Last 50 interactions cached using GetStorage
- Immediate access for context-aware responses

### 2. Long-Term Memory (Persistent, SQLite)
- All conversations and decisions
- Health data history
- 90-day retention by default

**Usage:**

```dart
// Agents automatically save important information
await agent.saveToMemory(
  content: 'User reported headache frequency increasing',
  metadata: {
    'type': 'symptom_report',
    'severity': 'moderate',
    'date': DateTime.now().toIso8601String(),
  },
);

// Retrieve relevant context
final context = await agent.memory.retrieveRelevantContext(
  'headache history',
  limit: 5,
);
```

## Function Calling

Agents use Gemini's function calling to execute actions:

```dart
// Define custom tools
toolRegistry.registerTool(
  AgentTool(
    name: 'schedule_appointment',
    description: 'Schedule a doctor appointment',
    parameters: {
      'specialty': Schema(SchemaType.string, description: 'Medical specialty'),
      'urgency': Schema(SchemaType.string, description: 'Urgency level'),
    },
    function: (args) async {
      // Implementation
      return {'success': true, 'appointmentId': '123'};
    },
  ),
);
```

## Monitoring & Analytics

```dart
// Get system stats
final status = Get.agentSystem.getSystemStatus();

print('Total Tasks: ${status['orchestratorStats']['totalTasks']}');
print('Success Rate: ${status['orchestratorStats']['successRate']}');
print('Token Usage: ${status['geminiUsage']['totalTokens']}');
print('Estimated Cost: \$${status['geminiUsage']['estimatedCostUSD']}');
```

## Best Practices

1. **Always Initialize:** Ensure agent system is initialized before use
2. **User IDs:** Always pass user ID for personalized experiences
3. **Error Handling:** Wrap agent calls in try-catch
4. **Context Management:** Provide additional context when available
5. **Token Optimization:** Monitor token usage and optimize prompts

## Troubleshooting

**Issue:** "Agent system not initialized"
- **Solution:** Call `await agentSystem.initialize()` in main.dart

**Issue:** High API costs
- **Solution:** Check token usage with `getSystemStatus()`, optimize prompts

**Issue:** Slow responses
- **Solution:** Use streaming responses for real-time feedback

## Next Steps

Upcoming agents in future phases:
- Personalized Care Agent (exercise/diet plans)
- Emergency Triage Agent (critical situation assessment)
- Medical Knowledge Agent (research and fact-checking)
- Proactive monitoring agents (predictive analytics)

## Support

For implementation questions, refer to the full implementation plan in `/artifacts/implementation_plan.md`.
