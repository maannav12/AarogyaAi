import 'package:aarogya/features/chatbot/chatbot_page.dart';
import 'package:aarogya/features/physio_trainer/physio_trainer_page.dart';
import 'package:aarogya/features/physio_trainer/physio_trainer_controller.dart';
import 'package:aarogya/features/profile/profile_page.dart';
import 'package:aarogya/home/home_page.dart';
import 'package:aarogya/medicine/medicine_analyzer.dart';
import 'package:aarogya/medicine/medicine_binding.dart';
import 'package:aarogya/medicine/medicin_controler.dart';
import 'package:aarogya/features/mri_scan_page.dart';
import 'package:aarogya/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:animated_botton_navigation/animated_botton_navigation.dart';
import 'package:get/get.dart';

class BottomBar extends StatefulWidget {
  const BottomBar({super.key});

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Get.lazyPut(() => MedicineController());
    Get.lazyPut(() => PhysioTrainerController());
  }

  final List<Widget> _pages = [
    const HomeScreen(),
    const MedicineScanView(),
    PhysioTrainerPage(),
    const MriScanPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allow body to extend behind the bottom bar
      body: _pages[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => ChatbotPage());
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedBottomNavigation(
        height: 70,
        indicatorSpaceBotton: 25,
        icons: const [
          Icons.home,
          Icons.medical_services_outlined,
          Icons.fitness_center, // Changed icon for Physio
          Icons.document_scanner_outlined,
        ],
        currentIndex: _currentIndex,
        onTapChange: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white,

        // indicatorColor: AppTheme.primaryColor, // Removed invalid parameter
        // iconColor: Colors.grey, // Removed invalid parameter
        // activeIconColor: AppTheme.primaryColor, // Removed invalid parameter
      ),
    );
  }
}
