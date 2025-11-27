// TODO Implement this library.
import 'dart:io';
import 'package:aarogya/services/tflite_service.dart'; // Import the service you created
import 'package:aarogya/utils/app_theme.dart';
import 'package:aarogya/utils/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageDiagnosticPage extends StatefulWidget {
  const ImageDiagnosticPage({super.key});

  @override
  State<ImageDiagnosticPage> createState() => _ImageDiagnosticPageState();
}

class _ImageDiagnosticPageState extends State<ImageDiagnosticPage> {
  late TfliteService _tfliteService;
  final ImagePicker _picker = ImagePicker();
  String _modelType = 'mri'; 

  // Default model
  XFile? _image;
  Map<String, double>? _result;
  bool _isLoading = false;
  
  // State variable to hold error messages
  String? _error;

  @override
  void initState() {
    super.initState();
    _tfliteService = TfliteService();
    // Load the default model when the page opens
    _loadModel();
  }

  Future<void> _loadModel() async {
    setState(() {
      _isLoading = true;
      _error = null; // Clear previous errors
    });
    
    try {
      await _tfliteService.loadModel(_modelType);
    } catch (e) {
      // Catch errors during model loading and show them
      setState(() {
        _error = "Failed to load model: ${e.toString()}";
      });
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _selectModel(String? newModel) {
    if (newModel == null) return Future.value();
    setState(() {
      _modelType = newModel;
      _image = null; // Clear image
      _result = null; // Clear previous result
      _error = null; // Clear previous errors
    });
    // Load the new model
    return _loadModel();
  }

  Future<void> _pickImage(ImageSource source) async {
    // Clear old results and errors
    setState(() {
      _isLoading = true;
      _image = null;
      _result = null;
      _error = null;
    });

    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) {
        setState(() {
          _isLoading = false; // User cancelled picking
        });
        return;
      }
      
      setState(() {
        _image = image;
      });

      // Run inference
      final result = await _tfliteService.runInference(image);

      // Check if the service returned null (which means an error)
      if (result == null) {
        setState(() {
          _error = "Failed to get a prediction. Check debug console for details.";
        });
      }

      setState(() {
        _result = result;
        _isLoading = false;
      });

    } catch (e) {
      print("Failed to pick or process image: $e");
      // Catch any other errors and show them
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: AppTheme.onBackgroundColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Image Diagnostic',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onBackgroundColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Glass Container for Controls
                  GlassContainer(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- 1. Model Selection Dropdown ---
                        DropdownButtonFormField<String>(
                          value: _modelType,
                          decoration: InputDecoration(
                            labelText: 'Select Model Type',
                            labelStyle: TextStyle(color: AppTheme.onBackgroundColor.withOpacity(0.7)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.primaryColor),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.5),
                          ),
                          dropdownColor: Colors.white,
                          items: const [
                            DropdownMenuItem(value: 'mri', child: Text('Brain Tumor (MRI)')),
                            DropdownMenuItem(value: 'skin', child: Text('Skin Disease')),
                            DropdownMenuItem(value: 'xray', child: Text('Lung Disease (X-Ray)')),
                          ],
                          onChanged: _selectModel,
                        ),
                        const SizedBox(height: 20),

                        // --- 2. Image Picker Buttons ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(
                              icon: Icons.photo_library,
                              label: 'Gallery',
                              onPressed: () => _pickImage(ImageSource.gallery),
                            ),
                            const SizedBox(width: 16),
                            _buildActionButton(
                              icon: Icons.camera_alt,
                              label: 'Camera',
                              onPressed: () => _pickImage(ImageSource.camera),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- 3. Loading Indicator ---
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(color: AppTheme.primaryColor),
                      ),
                    ),

                  // --- NEW: ERROR DISPLAY ---
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      margin: const EdgeInsets.symmetric(vertical: 10.0),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: AppTheme.errorColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.errorColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Error: $_error",
                              style: const TextStyle(
                                color: AppTheme.errorColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // --- 4. Image Display ---
                  if (_image != null && !_isLoading && _error == null)
                    Column(
                      children: [
                        const Text(
                          'Selected Image',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onBackgroundColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16.0),
                            child: Image.file(
                              File(_image!.path),
                              height: 250,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),

                  // --- 5. Result Display ---
                  if (_result != null && !_isLoading)
                    GlassContainer(
                      padding: const EdgeInsets.all(20.0),
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.analytics_outlined, color: AppTheme.primaryColor),
                              SizedBox(width: 8),
                              Text(
                                'Diagnosis Result',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _buildResultRow('Prediction', '${_result!.keys.first}'),
                          const SizedBox(height: 12),
                          _buildResultRow(
                            'Confidence',
                            '${_result!.values.first.toStringAsFixed(2)}%',
                            isHighlight: true,
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.onBackgroundColor.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            color: isHighlight ? AppTheme.primaryColor : AppTheme.onBackgroundColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}