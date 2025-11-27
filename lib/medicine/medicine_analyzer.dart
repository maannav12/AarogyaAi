import 'dart:io';
import 'package:aarogya/utils/app_theme.dart';
import 'package:aarogya/utils/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'medicin_controler.dart';

class MedicineScanView extends GetView<MedicineController> {
  const MedicineScanView({super.key});

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
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: AppTheme.onBackgroundColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Medicine Analyzer',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onBackgroundColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Obx(
                    () => Column(
                      spacing: 20.0,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Image Preview
                        Container(
                          width: 260,
                          height: 280,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5), width: 2),
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white.withOpacity(0.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: controller.currentImagePath.value.isEmpty
                                ? const Center(
                                    child: Text(
                                      "Tap camera or gallery\nto select medicine",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  )
                                : Image.file(
                                    File(controller.currentImagePath.value),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),

                        // Camera and Gallery buttons row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Camera Button
                            InkWell(
                              onTap: () => controller.scanAndAnalyze(ImageSource.camera),
                              borderRadius: BorderRadius.circular(50),
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 38,
                                ),
                              ),
                            ),
                            const SizedBox(width: 30),
                            // Gallery Button
                            InkWell(
                              onTap: () => controller.scanAndAnalyze(ImageSource.gallery),
                              borderRadius: BorderRadius.circular(50),
                              child: Container(
                                width: 65,
                                height: 65,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey.shade300),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.photo_library_rounded,
                                  color: AppTheme.onBackgroundColor,
                                  size: 28,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // 🔹 Analysis Section
                        GlassContainer(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Text(
                                "Analysis Results",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.onBackgroundColor,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 🔹 New Animated Progress Loader
                              controller.isAnalyzing.value
                                  ? Column(
                                      children: [
                                        CircularPercentIndicator(
                                          radius: 40.0,
                                          lineWidth: 8.0,
                                          animation: true,
                                          percent: controller.progressValue.value
                                              .clamp(0.0, 1.0),
                                          center: Text(
                                            "${(controller.progressValue.value * 100).toInt()}%",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20.0,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                          circularStrokeCap: CircularStrokeCap.round,
                                          progressColor: AppTheme.primaryColor,
                                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          controller.statusMessage.value,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.onBackgroundColor,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      controller.statusMessage.value,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: AppTheme.onBackgroundColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),

                              const SizedBox(height: 14),
                              const Text(
                                "Disclaimer: For informational purposes only.\nConsult a doctor or pharmacist.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.errorColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
