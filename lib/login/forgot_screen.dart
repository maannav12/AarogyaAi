import 'dart:ui';
import 'package:aarogya/login/login_screen.dart';
import 'package:aarogya/utils/app_theme.dart';
import 'package:aarogya/utils/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgotScreen extends StatelessWidget {
  const ForgotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.secondaryColor,
                  Color(0xFFE0F7FA), // Light Cyan
                ],
              ),
            ),
          ),

          // Glassmorphism Content
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Image.asset("assets/logo3.png"),
                    ),
                    const SizedBox(height: 30),

                    // Glass Container
                    GlassContainer(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Text(
                            "Forgot Password",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Enter your email to reset your password",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.onBackgroundColor.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Email Field
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                            ),
                            child: TextFormField(
                              style: const TextStyle(color: AppTheme.onBackgroundColor),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.primaryColor),
                                hintText: "Email",
                                hintStyle: TextStyle(color: AppTheme.onBackgroundColor.withOpacity(0.5)),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Reset Button
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: () {
                                // Implement reset logic
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: const Text(
                                "RESET PASSWORD",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Back to Login
                    TextButton(
                      onPressed: () => Get.off(() => const LoginScreen()),
                      child: const Text(
                        "Remember it? Login",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}