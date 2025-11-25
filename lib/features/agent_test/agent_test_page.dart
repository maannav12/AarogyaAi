import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../agents/agent_system_manager.dart';

/// Agent Test Page - Test and demonstrate AI agent capabilities
class AgentTestPage extends StatefulWidget {
  const AgentTestPage({Key? key}) : super(key: key);

  @override
  State<AgentTestPage> createState() => _AgentTestPageState();
}

class _AgentTestPageState extends State<AgentTestPage> {
  final _queryController = TextEditingController();
  final _resultController = TextEditingController();
  bool _isProcessing = false;
  String _statusMessage = '';
  
  late AgentSystemManager agentSystem;
  
  @override
  void initState() {
    super.initState();
    try {
      agentSystem = AgentSystemManager.getInstance();
    } catch (e) {
      _statusMessage = 'Agent system not initialized. Check main.dart';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Agent System Test'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showSystemStatus,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            _buildStatusCard(),
            
            const SizedBox(height: 24),
            
            // Quick Test Buttons
            const Text(
              'Quick Tests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTestButton(
                  'Health Query',
                  Icons.health_and_safety,
                  Colors.blue,
                  () => _testQuery("What are symptoms of diabetes?"),
                ),
                _buildTestButton(
                  'Diagnostic Intent',
                  Icons.medical_services,
                  Colors.orange,
                  () => _testQuery("I have an MRI scan to analyze"),
                ),
                _buildTestButton(
                  'Emergency Test',
                  Icons.emergency,
                  Colors.red,
                  () => _testQuery("I have severe chest pain"),
                ),
                _buildTestButton(
                  'Daily Insights',
                  Icons.insights,
                  Colors.green,
                  _testDailyInsights,
                ),
                _buildTestButton(
                  'System Status',
                  Icons.settings,
                  Colors.purple,
                  _showSystemStatus,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            
            // Custom Query
            const Text(
              'Custom Query',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _queryController,
              decoration: InputDecoration(
                hintText: 'Enter your health question...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.chat),
              ),
              maxLines: 3,
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: _isProcessing ? null : () => _testQuery(_queryController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Send to Agent System', style: TextStyle(fontSize: 16)),
            ),
            
            const SizedBox(height: 24),
            
            // Results
            if (_statusMessage.isNotEmpty) ...[
              const Text(
                'Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(_statusMessage),
              ),
              const SizedBox(height: 16),
            ],
            
            if (_resultController.text.isNotEmpty) ...[
              const Text(
                'Agent Response',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _resultController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 10,
                readOnly: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    bool isInitialized = false;
    String statusText = 'Checking...';
    Color statusColor = Colors.orange;
    
    try {
      final status = agentSystem.getSystemStatus();
      isInitialized = status['initialized'] == true;
      
      if (isInitialized) {
        statusText = '✅ Agent System Online';
        statusColor = Colors.green;
      } else {
        statusText = '❌ Agent System Not Initialized';
        statusColor = Colors.red;
      }
    } catch (e) {
      statusText = '❌ Error: $e';
      statusColor = Colors.red;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        children: [
          Icon(
            isInitialized ? Icons.check_circle : Icons.error,
            color: statusColor,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                if (!isInitialized)
                  const Text(
                    'See main.dart initialization steps',
                    style: TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      onPressed: _isProcessing ? null : onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _testQuery(String query) async {
    if (query.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter a query');
      return;
    }
    
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Processing query through agent system...';
      _resultController.clear();
    });

    try {
      final result = await agentSystem.processQuery(
        query: query,
        userId: 'test_user_123',
      );

      setState(() {
        if (result['success']) {
          // Format the result
          String formattedResult = '';
          
          // Execution mode
          formattedResult += '🤖 Execution Mode: ${result['executionMode']}\n\n';
          
          // Agent(s) used
          if (result['executionMode'] == 'multi-agent') {
            formattedResult += '👥 Agents: ${result['agents'].join(', ')}\n\n';
          } else if (result['agent'] != null) {
            formattedResult += '👤 Agent: ${result['agent']}\n\n';
          }
          
          // Response
          formattedResult += '💬 Response:\n';
          formattedResult += result['synthesizedResult']?['response'] ?? 
                            result['result']?['response'] ?? 
                            result['response'] ?? 
                            'No response text available';
          
          _resultController.text = formattedResult;
          _statusMessage = '✅ Query processed successfully!';
        } else {
          _resultController.text = 'Error: ${result['error']}';
          _statusMessage = '❌ Query failed';
        }
      });
    } catch (e) {
      setState(() {
        _resultController.text = 'Exception: $e';
        _statusMessage = '❌ Exception occurred';
      });
      
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red.shade100,
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _testDailyInsights() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Generating daily insights...';
      _resultController.clear();
    });

    try {
      final result = await agentSystem.generateDailyInsights('test_user_123');

      setState(() {
        if (result['success']) {
          _resultController.text = '📊 Daily Health Insights:\n\n${result['response']}';
          _statusMessage = '✅ Insights generated!';
        } else {
          _resultController.text = 'Error: ${result['error']}';
          _statusMessage = '❌ Failed to generate insights';
        }
      });
    } catch (e) {
      setState(() {
        _resultController.text = 'Exception: $e';
        _statusMessage = '❌ Exception occurred';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showSystemStatus() {
    try {
      final status = agentSystem.getSystemStatus();
      final orchestratorStats = status['orchestratorStats'] as Map<String, dynamic>;
      final geminiUsage = status['geminiUsage'] as Map<String, dynamic>;

      Get.dialog(
        AlertDialog(
          title: const Text('Agent System Status'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusRow('Initialized', status['initialized'].toString()),
                const Divider(),
                const Text('Orchestrator Stats:', style: TextStyle(fontWeight: FontWeight.bold)),
                _buildStatusRow('Total Tasks', orchestratorStats['totalTasks'].toString()),
                _buildStatusRow('Successful Tasks', orchestratorStats['successfulTasks'].toString()),
                _buildStatusRow('Success Rate', '${(orchestratorStats['successRate'] * 100).toStringAsFixed(1)}%'),
                _buildStatusRow('Active Agents', orchestratorStats['activeAgents'].toString()),
                _buildStatusRow('Queued Tasks', orchestratorStats['queuedTasks'].toString()),
                const Divider(),
                const Text('Gemini API Usage:', style: TextStyle(fontWeight: FontWeight.bold)),
                _buildStatusRow('Total Tokens', geminiUsage['totalTokens'].toString()),
                _buildStatusRow('Input Tokens', geminiUsage['totalInputTokens'].toString()),
                _buildStatusRow('Output Tokens', geminiUsage['totalOutputTokens'].toString()),
                _buildStatusRow('Estimated Cost', '\$${geminiUsage['estimatedCostUSD']}'),
                _buildStatusRow('Request Count', geminiUsage['requestCount'].toString()),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to get system status: $e');
    }
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _queryController.dispose();
    _resultController.dispose();
    super.dispose();
  }
}
