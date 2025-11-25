import 'dart:developer';


import 'package:aarogya/login/login_controler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get_storage/get_storage.dart';
import 'package:aarogya/features/image_diagnostic_page.dart'; // Adjust path as needed


class HomeScreen extends StatefulWidget {
   HomeScreen({Key? key}) : super(key: key); 




  @override
  State<HomeScreen> createState() => _HomeScreenState();
    
}

class _HomeScreenState extends State<HomeScreen> {
    //  final LoginControler controller = Get.find();

  GetStorage box = GetStorage();

  @override
  Widget build(BuildContext context) {
   var isLogin = box.read('isLoagin');
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40), // Added spacing for status bar since AppBar is removed

            // Quick Actions Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Action Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  InkWell(onTap: () {
                     Get.to(() => ImageDiagnosticPage());

                  }
,
                    child: _buildActionCard(
                      title: 'Symptom Check',
                      subtitle: 'Check your symptoms with our AI',
                      icon: Icons.health_and_safety_outlined,
                      color: Colors.blue,
                     ),
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    title: 'Vitals Log',
                    subtitle: 'Log and track your vital signs',
                    icon: Icons.monitor_heart_outlined,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () {
                      // Navigate to Agent Test Page
                      Get.toNamed('/agent-test') ?? 
                      Get.snackbar('Info', 'Add AgentTestPage route to test agents');
                    },
                    child: _buildActionCard(
                      title: '🤖 AI Agent Test',
                      subtitle: 'Test the multi-agent AI system',
                      icon: Icons.psychology,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Call Line Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1ABC9C), Color(0xFF16A085)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1ABC9C).withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: const [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone, color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'FREE AI CALL LINE (24/7)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'No Internet Needed',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
     floatingActionButton: IconButton(onPressed: (){}, icon: Icon(Icons.call)),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ],
      ),
    );
  }
}
