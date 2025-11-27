import 'dart:io';
import 'package:aarogya/features/chatbot/chatbot_controller.dart';
import 'package:aarogya/utils/app_theme.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ChatbotPage extends StatelessWidget {
  ChatbotPage({super.key});

  final ChatbotController controller = Get.put(ChatbotController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Dr. AI Assistant",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Obx(
        () => Stack(
          children: [
            // Background
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
            
            DashChat(
              currentUser: controller.currentUser,
              onSend: controller.sendMessage,
              messages: controller.messages.toList(),
              typingUsers: controller.isTyping.value ? [controller.geminiUser] : [],
              inputOptions: InputOptions(
                alwaysShowSend: true,
                sendOnEnter: true,
                leading: [
                  IconButton(
                    onPressed: () => _showAttachmentOptions(context),
                    icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor, size: 28),
                  ),
                ],
                trailing: [
                  IconButton(
                    onPressed: controller.isListening.value
                        ? controller.stopListening
                        : controller.startListening,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: controller.isListening.value ? Colors.redAccent : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        controller.isListening.value ? Icons.mic : Icons.mic_none,
                        color: controller.isListening.value ? Colors.white : AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                  ),
                ],
                inputDecoration: InputDecoration(
                  hintText: "Ask Dr. AI...",
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                ),
              ),
              messageOptions: MessageOptions(
                currentUserContainerColor: AppTheme.primaryColor,
                currentUserTextColor: Colors.white,
                containerColor: Colors.white,
                textColor: Colors.black87,
                showOtherUsersAvatar: true,
                showCurrentUserAvatar: false,
                avatarBuilder: (user, onPress, onLongPress) {
                  if (user.profileImage != null) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(user.profileImage!),
                        backgroundColor: Colors.white,
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Text(
                        user.firstName?[0] ?? '?',
                        style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
                messageDecorationBuilder: (message, previousMessage, nextMessage) {
                  bool isCurrentUser = message.user.id == controller.currentUser.id;
                  return BoxDecoration(
                    color: isCurrentUser ? AppTheme.primaryColor : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: isCurrentUser ? const Radius.circular(20) : const Radius.circular(0),
                      bottomRight: isCurrentUser ? const Radius.circular(0) : const Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  );
                },
              ),
            ),
            
            // Image Preview Overlay
            if (controller.selectedImage.value != null)
              Positioned(
                bottom: 80,
                left: 20,
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.primaryColor, width: 3),
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: FileImage(File(controller.selectedImage.value!.path)),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: -8,
                      right: -8,
                      child: GestureDetector(
                        onTap: controller.clearImage,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Attach Image',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onBackgroundColor,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSourceOption(
                      context,
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () {
                        controller.pickImage(ImageSource.gallery);
                        Navigator.pop(context);
                      },
                    ),
                    _buildSourceOption(
                      context,
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () {
                        controller.pickImage(ImageSource.camera);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSourceOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppTheme.onBackgroundColor,
            ),
          ),
        ],
      ),
    );
  }
}
