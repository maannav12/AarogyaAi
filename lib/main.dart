import 'package:aarogya/features/physio_trainer/physio_trainer_controller.dart';
import 'package:aarogya/firebase_options.dart';
import 'package:aarogya/login/login_screen.dart';
import 'package:aarogya/medicine/medicine_analyzer.dart';
import 'package:aarogya/onboarding/onboarding_screen.dart';
import 'package:aarogya/onboarding/splace_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/route_manager.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import agent system
import 'package:aarogya/agents/agent_system_manager.dart';
import 'package:aarogya/features/agent_test/agent_test_page.dart';
import 'package:aarogya/services/user_health_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GetStorage.init();
  
  // Initialize User Health Service
  await Get.putAsync(() => UserHealthService().init());
  
  // Initialize AI Agent System
  // TODO: Replace with your actual Gemini API key from environment or config
  try {
    await dotenv.load(fileName: ".env");
    final agentSystem = AgentSystemManager.getInstance(
      geminiApiKey: dotenv.env['AGENT_SYSTEM_KEY'] ?? '',
    );
    await agentSystem.initialize();
    print('✅ Agent System Initialized Successfully');
  } catch (e) {
    print('❌ Agent System Initialization Failed: $e');
    print('ℹ️  App will run but agent features will be disabled');
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'AarogyaAi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
      
      // Add named route for agent test page
      getPages: [
        GetPage(
          name: '/agent-test',
          page: () => const AgentTestPage(),
        ),
      ],
      
      home: SplaceScreen(),
   
            // home: MedicineAnalyzer(),

    );
  }
}
