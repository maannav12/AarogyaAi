import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:aarogya/medicine/medicine_detail_view.dart';
import 'package:aarogya/medicine/medicine_model.dart';
import 'package:aarogya/services/medicine_api_service.dart';

class MedicineController extends GetxController {
  final RxString statusMessage = "Scan a medicine to get details".obs;
  final Rxn<MedicineModel> foundMedicine = Rxn<MedicineModel>();
  final RxBool isAnalyzing = false.obs;
  final RxDouble progressValue = 0.0.obs;
  final RxString currentImagePath = "".obs; // ✅ Track selected image

  final ImagePicker _picker = ImagePicker();
  final FlutterTts _flutterTts = FlutterTts();
  final MedicineApiService _apiService = MedicineApiService();

  // ✅ Restored Translator
  final OnDeviceTranslator _translator = OnDeviceTranslator(
    sourceLanguage: TranslateLanguage.english,
    targetLanguage: TranslateLanguage.hindi,
  );

  @override
  void onInit() {
    super.onInit();
    _downloadTranslationModel();
    _flutterTts.setLanguage("hi-IN");
  }

  Future<void> _downloadTranslationModel() async {
    try {
      var modelManager = OnDeviceTranslatorModelManager();
      if (!await modelManager.isModelDownloaded(TranslateLanguage.hindi.bcpCode)) {
        await modelManager.downloadModel(TranslateLanguage.hindi.bcpCode);
      }
    } catch (e) {
      print("Error downloading translation model: $e");
    }
  }

  Future<void> scanAndAnalyze(ImageSource source) async {
    try {
      progressValue.value = 0.0;
      currentImagePath.value = "";
      statusMessage.value = source == ImageSource.camera ? "Opening camera..." : "Opening gallery...";
      isAnalyzing.value = true;

      progressValue.value = 0.1;
      final XFile? file = await _picker.pickImage(source: source);
      if (file == null) {
        statusMessage.value = "No image selected.";
        isAnalyzing.value = false;
        progressValue.value = 0.0;
        return;
      }

      currentImagePath.value = file.path;

      progressValue.value = 0.4;
      statusMessage.value = "Analyzing medicine...";
      
      final MedicineModel? medicine = await _apiService.analyzeMedicine(File(file.path));

      if (medicine != null) {
        foundMedicine.value = medicine;
        progressValue.value = 0.7;
        statusMessage.value = "Found medicine information!";

        // Translate English to Hindi
        try {
          statusMessage.value = "Translating to Hindi...";
          
          String usageHi = await _translator.translateText(medicine.usageInfo)
              .timeout(Duration(seconds: 10), onTimeout: () => medicine.usageInfo);
          String warningHi = await _translator.translateText(medicine.warningInfo)
              .timeout(Duration(seconds: 10), onTimeout: () => medicine.warningInfo);
          
          await _speakDetails(
            medicine.medicineName,
            usageHi,
            "",
            warningHi,
          );
        } catch (e) {
          print("Translation error: $e");
          await _speakDetails(
            medicine.medicineName,
            medicine.usageInfo,
            "",
            medicine.warningInfo,
          );
        }

        progressValue.value = 1.0;
        statusMessage.value = "Analysis Complete ✅";

        Get.to(() => MedicineDetailView(imagePath: file.path));
      } else {
        statusMessage.value = "Medicine not recognized or API error.";
        await _speak("दवा नहीं पहचानी गई।");
        progressValue.value = 0.0;
      }
    } catch (e) {
      statusMessage.value = "Error: $e";
      progressValue.value = 0.0;
      print("Error in scanAndAnalyze: $e");
    } finally {
      isAnalyzing.value = false;
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage("hi-IN");
    await _flutterTts.speak(text);
  }

  Future<void> _speakDetails(String name, String usage, String dosage, String warnings) async {
    await _flutterTts.stop();
    await _flutterTts.setLanguage("hi-IN");
    
    await _flutterTts.speak("दवा का नाम: $name");
    await Future.delayed(Duration(milliseconds: 1500));
    await _flutterTts.speak("इसका उपयोग: $usage");
    await Future.delayed(Duration(milliseconds: 1500));
    await _flutterTts.speak("खुराक: $dosage");
    await Future.delayed(Duration(milliseconds: 1500));
    await _flutterTts.speak("चेतावनी और दुष्प्रभाव: $warnings");
  }

  @override
  void onClose() {
    _translator.close();
    super.onClose();
  }
}
