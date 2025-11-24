import 'dart:io';
import 'package:aarogya/features/chatbot/chatbot_controller.dart';
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
      appBar: AppBar(
        title: const Text("Dr. AI Assistant"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Obx(
        () => Stack(
          children: [
            DashChat(
              currentUser: controller.currentUser,
              onSend: controller.sendMessage,
              messages: controller.messages.toList(),
              typingUsers: controller.isTyping.value ? [controller.geminiUser] : [],
              inputOptions: InputOptions(
                alwaysShowSend: true,
                leading: [
                  IconButton(
                    onPressed: () => _showAttachmentOptions(context),
                    icon: const Icon(Icons.attach_file, color: Colors.blue),
                  ),
                ],
                trailing: [
                  IconButton(
                    onPressed: controller.isListening.value
                        ? controller.stopListening
                        : controller.startListening,
                    icon: Icon(
                      controller.isListening.value ? Icons.mic : Icons.mic_none,
                      color: controller.isListening.value ? Colors.red : Colors.blue,
                    ),
                  ),
                ],
                inputDecoration: InputDecoration(
                  hintText: "Ask me anything...",
                  filled: true,
                  fillColor: Colors.grey[100]!,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
              ),
              messageOptions: MessageOptions(
                currentUserContainerColor: Colors.blueAccent,
                currentUserTextColor: Colors.white,
                containerColor: Colors.grey[200]!,
                textColor: Colors.black,
                avatarBuilder: (user, onPress, onLongPress) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(user.profileImage!),
                    ),
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
                        border: Border.all(color: Colors.blue, width: 2),
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: FileImage(File(controller.selectedImage.value!.path)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: -10,
                      right: -10,
                      child: IconButton(
                        onPressed: controller.clearImage,
                        icon: const Icon(Icons.close, color: Colors.red),
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
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                controller.pickImage(ImageSource.gallery);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                controller.pickImage(ImageSource.camera);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
