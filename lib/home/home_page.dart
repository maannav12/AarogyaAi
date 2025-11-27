import 'package:aarogya/features/image_diagnostic_page.dart';
import 'package:aarogya/utils/app_theme.dart';
import 'package:aarogya/utils/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aarogya/features/profile/profile_page.dart';
import 'package:aarogya/features/vitals_log/vitals_log_page.dart';
import 'package:aarogya/features/medicine_reminder/medicine_reminder_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GetStorage box = GetStorage();

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE0F2F1), // Light Teal
                  AppTheme.backgroundColor,
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello,',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppTheme.onBackgroundColor.withOpacity(0.6),
                            ),
                          ),
                          const Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.onBackgroundColor,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Get.to(() => ProfilePage()),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.primaryColor, width: 2),
                          ),
                          child: const CircleAvatar(
                            radius: 24,
                            backgroundImage: AssetImage('assets/logo3.png'), // Placeholder
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Search Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search for symptoms, doctors...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: InputBorder.none,
                        icon: const Icon(Icons.search, color: AppTheme.primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Quick Actions Section
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onBackgroundColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick Action Cards
                  InkWell(
                    onTap: () => Get.to(() => VitalsLogPage()),
                    child: _buildActionCard(
                      title: 'Vitals Log',
                      subtitle: 'Log and track your vital signs',
                      icon: Icons.monitor_heart_outlined,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => Get.to(() => MedicineReminderPage()),
                    child: _buildActionCard(
                      title: 'Medicine Reminder',
                      subtitle: 'Never miss a dose',
                      icon: Icons.medication,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () {
                      Get.toNamed('/agent-test') ?? 
                      Get.snackbar('Info', 'Add AgentTestPage route to test agents');
                    },
                    child: _buildActionCard(
                      title: 'AI Agent Test',
                      subtitle: 'Test the multi-agent AI system',
                      icon: Icons.psychology,
                      color: Colors.deepPurple,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Call Line Button
                  InkWell(
                    onTap: () => _makePhoneCall('+12173758459'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: const [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.phone_in_talk, color: Colors.white, size: 28),
                              SizedBox(width: 12),
                              Text(
                                'FREE AI CALL LINE (24/7)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Text(
                            'No Internet Needed',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 80), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.call, color: Colors.white),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      opacity: 0.8,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onBackgroundColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}
