# 🧪 Testing the AI Agent System

## Quick Start (3 Steps)

### Step 1: Add Your Gemini API Key

Open `lib/main.dart` and replace the placeholder:

```dart
final agentSystem = AgentSystemManager.getInstance(
  geminiApiKey: 'YOUR_ACTUAL_GEMINI_API_KEY', // ⚠️ Get from Google AI Studio
);
```

**Get API Key:** https://aistudio.google.com/app/apikey

### Step 2: Hot Reload the App

Since you already have `flutter run` active:
1. Save the file (`main.dart`)
2. Press `r` in the terminal for hot reload
3. Check console for "✅ Agent System Initialized Successfully"

### Step 3: Navigate to Agent Test Page

**Option A: Add to your navigation**
```dart
// In your routes or direct navigation
import 'package:aarogya/features/agent_test/agent_test_page.dart';

Get.to(() => AgentTestPage());
```

**Option B: From Home Screen**
- Look for the new "🤖 AI Agent Test" card
- Tap it to open the test page

**Option C: Set as default home (for testing)**
```dart
// In main.dart, temporarily change:
home: AgentTestPage(), // Instead of SplaceScreen()
```

---

## What You Can Test

### 1. Health Query Test
**Example:** "What are symptoms of diabetes?"

**Expected:**
- Agent: `orchestrator` or `knowledge`
- Response: Medical information about diabetes symptoms
- Status: Shows which agent handled it

### 2. Diagnostic Intent
**Example:** "I have an MRI scan to analyze"

**Expected:**
- Agent routes to: `diagnostic`
- Response: Asks for image or explains MRI analysis capability
- Shows multi-modal readiness

### 3. Emergency Detection
**Example:** "I have severe chest pain"

**Expected:**
- High priority routing to `emergency` agent (when implemented)
- Currently routes to `orchestrator`
- Response emphasizes seeking immediate medical attention

### 4. Daily Insights
**Button:** Click "Daily Insights"

**Expected:**
- Agent generates health summary
- Provides encouragement/recommendations
- Uses Health Orchestrator Agent

### 5. System Status
**Button:** Click "System Status"

**Expected Dialog:**
```
Initialized: true
Total Tasks: X
Success Rate: XX%
Token Usage: XXX
Estimated Cost: $X.XX
```

---

## Troubleshooting

### ❌ "Agent system not initialized"

**Cause:** API key not set or initialization failed

**Fix:**
1. Check main.dart has correct API key
2. Restart app (not just hot reload)
3. Check console for error messages

### ❌ "Tool not found" errors

**Cause:** Agent trying to use unregistered tool

**Fix:** Normal - some tools are placeholders for future phases

### ❌ Slow responses

**Cause:** Gemini API network latency

**Expected:** 2-5 seconds for simple queries, 5-10s for complex

### ⚠️ API Errors

**Common:**
- `Invalid API key`: Check key is correct
- `Quota exceeded`: Free tier has limits
- `Model not found`: Using correct model name

---

## Testing from Existing Features

### Chatbot Integration

Replace your existing chatbot controller's send message:

```dart
// Old way
final response = await gemini.generateContent([Content.text(message)]);

// New way (with agents)
final result = await Get.agentSystem.processQuery(
  query: message,
  userId: currentUserId,
);

String response = result['synthesizedResult']?['response'] ?? 
                 result['result']?['response'] ?? 
                 'Error processing request';
```

### Medical Image Analysis

```dart
// In your image diagnostic page
final analysis = await Get.agentSystem.analyzeMedicalImage(
  imagePath: imageFile.path,
  imageType: 'mri', // or 'xray', 'skin'
  userId: currentUserId,
);

print('ML Result: ${analysis['mlClassification']}');
print('Vision Analysis: ${analysis['visualAnalysis']}');
```

---

## What to Look For

### ✅ Success Indicators
- No console errors
- Agent responses in 2-10 seconds
- Appropriate agent routing (diagnostic for scans, etc.)
- Memory persisting between queries
- Token usage tracking incrementing

### ⚠️ Expected Limitations (Current Phase)
- Only 2 agents active (Orchestrator, Diagnostic)
- Simplified keyword routing
- No vector embeddings (using keyword search)
- OCR extraction is placeholder
- Some tools return mock data

### 🔮 Coming in Future Phases
- Emergency Triage Agent
- Personalized Care Agent
- Medical Knowledge Agent
- Predictive analytics
- Voice integration
- Wearable data integration

---

## Console Monitoring

Watch for these logs:

```
✅ Agent System Initialized Successfully
🔍 [Orchestrator] Processing query: ...
🤖 [HealthOrchestrator] Executing task: ...
📊 [DiagnosticAgent] Analyzing mri image: ...
💾 [AgentMemory] Saved memory entry
📈 Token usage - Input: XX, Output: YY
```

---

## Performance Tips

1. **Test with short queries first** - Verify basic functionality
2. **Monitor token usage** - Click "System Status" regularly
3. **Check success rate** - Should be >90%
4. **Clear memory if needed** - Use agent.memory.clearAllMemories()

---

## Next Steps After Testing

1. ✅ Verify agents work correctly
2. 📝 Integrate with existing chatbot
3. 🎨 Create custom UI for agent interactions
4. 🔧 Implement remaining agents (Phase 3-4)
5. 📊 Add analytics dashboard
6. 🚀 Deploy to production

---

## Support

- **Documentation:** `lib/agents/README.md`
- **Examples:** `lib/examples/chatbot_controller_enhanced_example.dart`
- **Walkthrough:** Check artifacts for detailed implementation guide

Happy Testing! 🚀
