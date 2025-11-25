import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class TfliteService {
  Interpreter? _interpreter;
  List<String> _labels = [];

  // Load the selected model and labels
  Future<void> loadModel(String modelType, ) async {
    // Clear previous model/labels
    if (_interpreter != null) {
      _interpreter!.close();
      _interpreter = null;
    }
    _labels.clear();

    String modelPath, labelsPath;

    if (modelType == 'mri') {
      modelPath = 'assets/models/mri_classifier.tflite';
      labelsPath = 'assets/models/mri_labels.txt';
    } else if (modelType == 'skin') {
      modelPath = 'assets/models/skin_classifier.tflite';
      labelsPath = 'assets/models/skin_labels.txt';
    } else { // xray
      modelPath = 'assets/models/xray_classifier.tflite';
      labelsPath = 'assets/models/xray_labels.txt';
    }

    try {
      // Load model
      _interpreter = await Interpreter.fromAsset(modelPath);
      
      // Load labels
      final labelsData = await rootBundle.loadString(labelsPath);
      _labels = labelsData.split('\n').where((label) => label.isNotEmpty).toList();
      
      print("✅ $modelType Model & Labels Loaded");
      
    } catch (e) {
      print("❌ Error loading model: $e");
    }
  }

  // Pre-process the image and run inference
  Future<Map<String, double>?> runInference(XFile imageFile) async {
    if (_interpreter == null) {
      print("❌ Interpreter not loaded");
      return null;
    }

    // 1. Read and Decode Image
    final bytes = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(bytes);
    if (originalImage == null) return null;

    // 2. Resize to 224x224 (as per your app.py)
    img.Image resizedImage = img.copyResize(originalImage, width: 224, height: 224);

    // 3. Convert to Float32List and Normalize to [-1, 1]
    // This matches efficientnet_v2.preprocess_input
    var input = Float32List(1 * 224 * 224 * 3);
    var buffer = input.buffer.asByteData();
    int pixelIndex = 0;
    
    for (var y = 0; y < 224; y++) {
      for (var x = 0; x < 224; x++) {
        var pixel = resizedImage.getPixel(x, y);
        // Normalize from [0, 255] to [-1, 1]
        input[pixelIndex++] = (pixel.r - 127.5) / 127.5;
        input[pixelIndex++] = (pixel.g - 127.5) / 127.5;
        input[pixelIndex++] = (pixel.b - 127.5) / 127.5;
      }
    }
    
    // Reshape to [1, 224, 224, 3]
    var shapedInput = input.reshape([1, 224, 224, 3]);

    // 4. Prepare Output
    // The output shape will be [1, N] where N is the number of classes
    var output = List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);

    // 5. Run Inference
    try {
      _interpreter!.run(shapedInput, output);
    } catch (e) {
      print("❌ Error running inference: $e");
      return null;
    }
    
    // 6. Post-process Output
    var results = output[0] as List<double>;
    int maxIndex = results.indexWhere((element) => element == results.reduce((a, b) => a > b ? a : b));
    
    String predictedClass = _labels[maxIndex];
    double confidence = results[maxIndex] * 100.0;

    print("✅ Prediction: $predictedClass, Confidence: $confidence%");
    return {predictedClass: confidence};
  }

  // Dispose resources
  void dispose() {
    if (_interpreter != null) {
      _interpreter!.close();
      _interpreter = null;
    }
  }
}
