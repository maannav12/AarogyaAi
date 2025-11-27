import 'dart:io';
import 'package:aarogya/utils/app_theme.dart';
import 'package:aarogya/utils/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aarogya/services/render_api_service.dart';

class MriScanPage extends StatefulWidget {
  const MriScanPage({super.key});

  @override
  State<MriScanPage> createState() => _MriScanPageState();
}

class _MriScanPageState extends State<MriScanPage> {
  final RenderApiService _apiService = RenderApiService();
  final ImagePicker _picker = ImagePicker();
  
  String _selectedModel = 'mri'; // Default
  File? _image;
  Map<String, dynamic>? _result;
  bool _isLoading = false;
  String? _error;

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 50, // Compress image to 50% quality to reduce size
        maxWidth: 1024,   // Limit width to 1024px
        maxHeight: 1024,  // Limit height to 1024px
      );
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
        
        // Automatically scan after picking
        await _scanImage();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error picking image: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _scanImage() async {
    if (_image == null) return;

    try {
      final result = await _apiService.uploadImage(_image!, _selectedModel);
      setState(() {
        _result = result;
        _isLoading = false;
      });
      
      if (result == null) {
         setState(() {
          _error = 'Failed to analyze image. Please try again.';
        });
      }

    } catch (e) {
      setState(() {
        _error = 'Error scanning image: $e';
        _isLoading = false;
      });
    }
  }

  void _reset() {
    setState(() {
      _image = null;
      _result = null;
      _error = null;
    });
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'AI Diagnostics',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onBackgroundColor,
                          ),
                        ),
                        if (_image != null)
                          IconButton(
                            icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
                            onPressed: _reset,
                          )
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Model Selection
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GlassContainer(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Scan Type',
                            style: TextStyle(
                              color: AppTheme.onBackgroundColor.withOpacity(0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedModel,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
                                dropdownColor: Colors.white,
                                items: const [
                                  DropdownMenuItem(value: 'mri', child: Text('Brain Tumor (MRI)')),
                                  DropdownMenuItem(value: 'xray', child: Text('Lung Disease (X-Ray)')),
                                  DropdownMenuItem(value: 'skin', child: Text('Skin Disease')),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedModel = value;
                                      _reset();
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Main Content
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // Image Display Area
                        GestureDetector(
                          onTap: () {
                            if (_image == null) _showImageSourceDialog();
                          },
                          child: Container(
                            height: 300,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  spreadRadius: 2,
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                              border: _image == null 
                                ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 2, style: BorderStyle.solid)
                                : null,
                            ),
                            child: _image != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.file(_image!, fit: BoxFit.cover),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo_outlined,
                                        size: 60,
                                        color: AppTheme.primaryColor.withOpacity(0.5),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Tap to upload image',
                                        style: TextStyle(
                                          color: AppTheme.primaryColor.withOpacity(0.7),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Loading State
                        if (_isLoading)
                          const Column(
                            children: [
                              CircularProgressIndicator(color: AppTheme.primaryColor),
                              SizedBox(height: 16),
                              Text('Analyzing image...', style: TextStyle(color: AppTheme.onBackgroundColor)),
                            ],
                          ),

                        // Error State
                        if (_error != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.errorColor),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: AppTheme.errorColor),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(color: AppTheme.errorColor),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Result State
                        if (_result != null && !_isLoading)
                          GlassContainer(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                const Text(
                                  'Analysis Result',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const Divider(height: 30),
                                // Dynamic display of results based on API response
                                // Assuming simple key-value pairs or a 'prediction' field
                                if (_result!.containsKey('prediction'))
                                   Text(
                                    _result!['prediction'].toString(),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.onBackgroundColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  )
                                else
                                  ..._result!.entries.map((e) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          e.key,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.onBackgroundColor.withOpacity(0.6),
                                          ),
                                        ),
                                        Text(
                                          e.value.toString(),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.onBackgroundColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )).toList(),
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

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Image Source',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.onBackgroundColor),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildSourceOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
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
            child: Icon(icon, size: 30, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.onBackgroundColor)),
        ],
      ),
    );
  }
}
