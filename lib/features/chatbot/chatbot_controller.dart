import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../services/user_health_service.dart';

class ChatbotController extends GetxController {
  final UserHealthService _healthService = Get.find<UserHealthService>();
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isTyping = false.obs;
  final RxBool isListening = false.obs;
  final RxBool isSpeaking = false.obs;
  final Rxn<XFile> selectedImage = Rxn<XFile>(); // Track selected image

  late final GenerativeModel _model;
  late final ChatSession _chatSession;
  
  final SpeechToText _speechToText = SpeechToText();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  final ImagePicker _picker = ImagePicker();

  // API Keys
  // API Keys
  static String get _geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static String get _googleCloudTtsApiKey => dotenv.env['GOOGLE_CLOUD_TTS_API_KEY'] ?? '';

  final ChatUser currentUser = ChatUser(
    id: '1',
    firstName: 'User',
  );

  final ChatUser geminiUser = ChatUser(
    id: '2',
    firstName: 'Dr. AI',
    profileImage: 'https://cdn-icons-png.flaticon.com/512/3774/3774299.png',
  );

  @override
  void onInit() {
    super.onInit();
    _initializeGemini();
    _initializeSpeech();
    _initializeTts();
  }

  void _initializeGemini() {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
      ),
    );
    _chatSession = _model.startChat(history: [
      Content.text(
          "You are Dr. AI, a highly experienced Senior Medical Consultant. "
          "Your goal is to analyze medical queries and reports with professional precision and empathy. "
          "IMPORTANT: Respond in the SAME language the user asks in (English or Hindi). "
          "If the user shares a medical report (image), do NOT just read the text. "
          "Instead, interpret the medical significance of the values. "
          "Structure your response like a real doctor's consultation: "
          "1. 📋 **Summary**: What is this report about? "
          "2. 🔍 **Key Findings**: Highlight normal vs abnormal values. "
          "3. ⚠️ **Concerns**: Clearly flag any critical issues. "
          "4. 💡 **Interpretation**: Explain what these results mean for the patient's health in simple terms. "
          "5. 🩺 **Advice**: Suggest next steps, lifestyle changes, or immediate medical attention if needed. "
          "Always clarify you are an AI. If there is a medical emergency, advise calling emergency services immediately.\n\n"
          "User Profile Context:\n${_healthService.userProfile.value.getProfileSummary()}"),
    ]);
  }

  Future<void> _initializeSpeech() async {
    await _speechToText.initialize();
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        selectedImage.value = image;
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to pick image: $e");
    }
  }

  void clearImage() {
    selectedImage.value = null;
  }

  Future<void> sendMessage(ChatMessage chatMessage) async {
    messages.insert(0, chatMessage);
    isTyping.value = true;

    try {
      GenerateContentResponse response;
      
      bool isReportAnalysis = selectedImage.value != null;
      
      if (selectedImage.value != null) {
        // Multimodal request (Text + Image)
        final imageBytes = await selectedImage.value!.readAsBytes();
        final prompt = chatMessage.text.isEmpty 
            ? "Act as a senior doctor. Analyze this medical report in detail. "
              "Identify the test type, check for any abnormal values (high/low), "
              "explain what they indicate medically, and provide actionable health advice. "
              "If everything is normal, reassure the patient.\n\n"
              "Structure your response:\n"
              "1. 📋 **Summary**\n"
              "2. 🔍 **Key Findings**\n"
              "3. ⚠️ **Concerns**\n"
              "4. 💡 **Interpretation**\n"
              "5. 🩺 **Advice**\n"
              "6. 🏁 **Final Conclusion**: A concise 1-2 sentence summary of the overall status." 
            : "${chatMessage.text}\n\n(Context: Analyze this attached medical report as a doctor. Provide a structured analysis with a Final Conclusion at the end.)";

        // Create a new chat message for the UI if text was empty
        if (chatMessage.text.isEmpty) {
           // We already inserted the message, but it might have been empty text with image.
           // DashChat handles images in message, so we are good.
        }

        final content = Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ]);

        response = await _model.generateContent([content]);
        
        // Clear image after sending
        selectedImage.value = null;
      } else {
        // Text-only request
        response = await _chatSession.sendMessage(
          Content.text(chatMessage.text),
        );
      }

      final text = response.text;
      if (text != null) {
        final botMessage = ChatMessage(
          user: geminiUser,
          createdAt: DateTime.now(),
          text: text,
        );
        messages.insert(0, botMessage);
        
        // Save chat interaction
        _healthService.saveChatInteraction(chatMessage.text, text);
        
        // Speak ONLY if it's not a report analysis
        if (!isReportAnalysis) {
          await _speakWithGoogleTts(text);
        }
      }
    } catch (e) {
      String errorMessage = "I'm sorry, I encountered an error. Please try again.";
      
      // Check for specific error types
      if (e.toString().contains('Resource exhausted') || 
          e.toString().contains('429') ||
          e.toString().contains('quota')) {
        errorMessage = "⚠️ API quota limit reached. This usually means:\n\n"
                      "1. You're using a free API key with daily limits\n"
                      "2. Too many requests in a short time\n\n"
                      "💡 Solutions:\n"
                      "• Wait a few minutes and try again\n"
                      "• Check if your API key is valid at https://aistudio.google.com/apikey\n"
                      "• Consider upgrading to a paid plan for higher limits";
      } else if (e.toString().contains('API key') || 
                 e.toString().contains('leaked') ||
                 e.toString().contains('invalid')) {
        errorMessage = "🔑 API Key Error!\n\n"
                      "Your API key appears to be invalid or has been blocked.\n\n"
                      "Please:\n"
                      "1. Go to https://aistudio.google.com/apikey\n"
                      "2. Create a NEW API key\n"
                      "3. Update it in the .env file\n"
                      "4. Restart the app";
      }
      
      Get.snackbar(
        "Error", 
        errorMessage,
        duration: const Duration(seconds: 10),
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade900,
      );
      
      messages.insert(
        0,
        ChatMessage(
          user: geminiUser,
          createdAt: DateTime.now(),
          text: errorMessage,
        ),
      );
    } finally {
      isTyping.value = false;
    }
  }

  Future<void> _speakWithGoogleTts(String text) async {
    try {
      isSpeaking.value = true;
      
      // Detect language (simple: check if contains Hindi characters)
      bool isHindi = RegExp(r'[\u0900-\u097F]').hasMatch(text);
      
      // Select best voice based on language
      String voiceName = isHindi 
          ? 'hi-IN-Neural2-A'  // Female Hindi voice (ultra realistic)
          : 'en-US-Neural2-F'; // Female English voice (ultra realistic)
      
      String languageCode = isHindi ? 'hi-IN' : 'en-US';

      final requestBody = {
        'input': {'text': text},
        'voice': {
          'languageCode': languageCode,
          'name': voiceName,
        },
        'audioConfig': {
          'audioEncoding': 'MP3',
          'pitch': 0,
          'speakingRate': 1.0,
        },
      };

      final response = await http.post(
        Uri.parse('https://texttospeech.googleapis.com/v1/text:synthesize?key=$_googleCloudTtsApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final audioContent = data['audioContent'];
        
        // Save audio to temporary file
        final bytes = base64.decode(audioContent);
        final tempDir = await getTemporaryDirectory();
        final audioFile = File('${tempDir.path}/tts_audio_${DateTime.now().millisecondsSinceEpoch}.mp3');
        await audioFile.writeAsBytes(bytes);

        // Play audio
        await _audioPlayer.play(DeviceFileSource(audioFile.path));
        
        // Wait for audio to complete
        await _audioPlayer.onPlayerComplete.first;
        
        // Clean up
        if (await audioFile.exists()) {
          await audioFile.delete();
        }
      } else {
        print('TTS API Error: ${response.statusCode} - ${response.body}');
        // Fallback to basic TTS if API fails
        await _speakFallback(text, isHindi);
      }
    } catch (e) {
      print('TTS Error: $e');
      // Fallback to basic TTS
      bool isHindi = RegExp(r'[\u0900-\u097F]').hasMatch(text);
      await _speakFallback(text, isHindi);
    } finally {
      isSpeaking.value = false;
    }
  }

  Future<void> _speakFallback(String text, bool isHindi) async {
    await _flutterTts.setLanguage(isHindi ? "hi-IN" : "en-US");
    await _flutterTts.speak(text);
  }

  Future<void> startListening() async {
    if (!_speechToText.isAvailable) {
      await _initializeSpeech();
    }

    if (_speechToText.isAvailable) {
      isListening.value = true;
      _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            isListening.value = false;
            final message = ChatMessage(
              user: currentUser,
              createdAt: DateTime.now(),
              text: result.recognizedWords,
            );
            sendMessage(message);
          }
        },
        // Support both English and Hindi
        localeId: 'en_IN', // This supports both English and Hindi
      );
    } else {
      Get.snackbar("Error", "Speech recognition not available");
    }
  }

  void stopListening() {
    _speechToText.stop();
    isListening.value = false;
  }
  
  @override
  void onClose() {
    _audioPlayer.dispose();
    _flutterTts.stop();
    super.onClose();
  }
}
