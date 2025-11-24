import 'package:aarogya/features/chatbot/chatbot_page.dart';
import 'package:aarogya/features/physio_trainer/physio_trainer_page.dart';
import 'package:aarogya/features/physio_trainer/physio_trainer_controller.dart';
import 'package:aarogya/features/profile/profile_page.dart';
import 'package:aarogya/home/home_page.dart';
import 'package:aarogya/medicine/medicine_analyzer.dart';
import 'package:aarogya/medicine/medicine_binding.dart';
import 'package:aarogya/medicine/medicin_controler.dart';
import 'package:aarogya/features/mri_scan_page.dart';
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
    Center(child: HomeScreen()),
    Center(child: MedicineScanView()),
    PhysioTrainerPage(),
    const MriScanPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('AarogyaAI'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 28),
            onPressed: () => Get.to(() => ProfilePage()),
            tooltip: 'My Profile',
          ),
        ],
      ),
      body: _pages[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => ChatbotPage());
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedBottomNavigation(
        height: 70,
        indicatorSpaceBotton: 25,
        icons: [
          Icons.home,
          Icons.medical_services_outlined,
          Icons.person,
          Icons.document_scanner_outlined,
        ],
        currentIndex: _currentIndex,
        onTapChange: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
