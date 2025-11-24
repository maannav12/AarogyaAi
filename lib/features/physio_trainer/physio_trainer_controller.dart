// lib/features/physio_trainer/physio_trainer_controller.dart
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For compute
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:aarogya/logic/exercise_logic.dart';
import 'package:aarogya/logic/pose_utils.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';

class PhysioTrainerController extends GetxController {
  CameraController? cameraController;
  late PoseDetector poseDetector;
  late ExerciseLogic exerciseLogic;
  late FlutterTts flutterTts;

  final RxBool isCameraInitialized = false.obs;
  bool isDetectingPoses = false;
  bool _isDisposed = false;
  
  // Frame throttling for better performance - prevent buffer overflow
  DateTime? _lastProcessedFrame;
  static const Duration _frameThrottleDuration = Duration(milliseconds: 1000); // Process 1 fps to prevent buffer overflow

  final RxInt repCount = 0.obs;
  final RxString feedbackText = "Initializing camera...".obs;
  final RxInt formScore = 100.obs;
  final RxString currentExercise = "squat".obs;
  final RxList<Pose> poses = <Pose>[].obs;
  final RxBool showSkeleton = true.obs;
  final RxBool isPaused = false.obs;
  
  final List<String> availableExercises = [
    "squat",
    "pushup",
    "tree_pose",
    "jumping_jack",
  ];

  Size? _imageSize;

  @override
  void onInit() {
    super.onInit();
    _initializePoseDetector();
    exerciseLogic = ExerciseLogic();
    _initializeTTS();
  }

  void _initializePoseDetector() {
    poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        model: PoseDetectionModel.base, // Use base model for better performance
        mode: PoseDetectionMode.stream,
      ),
    );
  }

  Future<void> _initializeTTS() async {
    flutterTts = FlutterTts();
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  @override
  void onReady() {
    super.onReady();
    // Don't auto-start camera - wait for manual init
    // _initializeCamera();
  }
  
  // Call this when page becomes visible
  Future<void> startCamera() async {
    if (!isCameraInitialized.value) {
      await _initializeCamera();
    }
  }

  @override
  void onClose() {
    _isDisposed = true;
    isDetectingPoses = false;
    try {
      cameraController?.stopImageStream();
    } catch (_) {}
    try {
      cameraController?.dispose();
    } catch (_) {}
    try {
      poseDetector.close();
    } catch (_) {}
    try {
      flutterTts.stop();
    } catch (_) {}
    super.onClose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        feedbackText.value = "No cameras available";
        return;
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      cameraController = CameraController(
        frontCamera,
        ResolutionPreset.low, // Use low resolution to prevent crashes
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await cameraController!.initialize();
      isCameraInitialized.value = true;
      feedbackText.value = "Camera ready. Position yourself in frame.";
      await Future.delayed(Duration(seconds: 1));
      cameraController!.startImageStream(_processCameraImage);
    } catch (e) {
      feedbackText.value = "Error initializing camera: $e";
    }
  }

  Future<void> switchCameraLens() async {
    if (cameraController == null || !isCameraInitialized.value) return;
    
    try {
      final cameras = await availableCameras();
      final currentLens = cameraController!.description.lensDirection;
      final desiredLens = currentLens == CameraLensDirection.front
          ? CameraLensDirection.back
          : CameraLensDirection.front;

      final newCamera = cameras.firstWhere(
        (c) => c.lensDirection == desiredLens,
        orElse: () => cameras.first,
      );

      // Stop and dispose existing controller
      await cameraController?.stopImageStream();
      await cameraController?.dispose();

      cameraController = CameraController(
        newCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await cameraController!.initialize();
      isCameraInitialized.value = true;
      cameraController!.startImageStream(_processCameraImage);
      feedbackText.value =
          "Switched to ${desiredLens == CameraLensDirection.front ? 'front' : 'back'} camera";
    } catch (e) {
      feedbackText.value = "Error switching camera: $e";
    }
  }

  bool get isFrontCamera =>
      cameraController?.description.lensDirection == CameraLensDirection.front;

  void togglePause() {
    isPaused.value = !isPaused.value;
    if (isPaused.value) {
      feedbackText.value = "Paused";
    } else {
      feedbackText.value = "Resumed";
    }
  }

  void selectExercise(String exercise) {
    if (availableExercises.contains(exercise)) {
      currentExercise.value = exercise;
      exerciseLogic.reset();
      repCount.value = 0;
      formScore.value = 100;
      feedbackText.value = "Starting ${exercise.replaceAll('_', ' ')}";
      flutterTts.speak("Starting ${exercise.replaceAll('_', ' ')}");
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    // Early exit checks - must be first to prevent buffer overflow
    // CRITICAL: Return immediately if already processing or disposed to prevent buffer overflow
    if (_isDisposed || isDetectingPoses || isPaused.value || cameraController == null) {
      return;
    }
    
    // Frame throttling for performance - prevent infinite loop and buffer overflow
    final now = DateTime.now();
    if (_lastProcessedFrame != null &&
        now.difference(_lastProcessedFrame!) < _frameThrottleDuration) {
      return; // Skip this frame to prevent buffer overflow
    }
    
    // Set flag BEFORE async operations to prevent race conditions
    isDetectingPoses = true;
    _lastProcessedFrame = now;
    _imageSize = Size(image.width.toDouble(), image.height.toDouble());

    // Process asynchronously to avoid blocking main thread
    // Fire and forget - don't await to prevent blocking the camera stream
    _processFrameAsync(image).catchError((_) {
      // Silently handle errors to prevent crashes
      isDetectingPoses = false;
    });
  }

  Future<void> _processFrameAsync(CameraImage image) async {
    try {
      // Add delay to give system time to breathe and prevent main thread blocking
      // Increased delay to help with buffer management
      await Future.delayed(Duration(milliseconds: 200));
      
      if (_isDisposed) {
        isDetectingPoses = false;
        return;
      }

      // Convert camera image to InputImage format (CPU intensive)
      // Wrap in Future to allow other tasks to run
      final inputImage = await Future.microtask(() => _convertCameraImageToInputImageSync(image));
      
      // Check again after async operation
      if (_isDisposed || inputImage == null) {
        isDetectingPoses = false;
        return;
      }

      // Process pose detection (also CPU intensive)
      List<Pose> detectedPoses;
      try {
        detectedPoses = await poseDetector.processImage(inputImage);
      } catch (e) {
        // Pose detection failed - likely image format issue
        debugPrint('Pose detection error: $e');
        isDetectingPoses = false;
        return;
      }
      
      // Check again after async operation
      if (_isDisposed) {
        isDetectingPoses = false;
        return;
      }
      
      // Update UI on main thread - use scheduleMicrotask to ensure it's on the main thread
      await Future.microtask(() {
        if (!_isDisposed) {
          poses.value = detectedPoses;

          if (detectedPoses.isNotEmpty) {
            final pose = detectedPoses.first;
            final angles = PoseUtils.calculateAllAngles(pose);

            // Define required landmarks based on exercise
            List<PoseLandmarkType> requiredLandmarks = [];
            switch (currentExercise.value) {
              case 'squat':
              case 'tree_pose':
                requiredLandmarks = [
                  PoseLandmarkType.leftHip, PoseLandmarkType.rightHip,
                  PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee,
                  PoseLandmarkType.leftAnkle, PoseLandmarkType.rightAnkle
                ];
                break;
              case 'pushup':
                requiredLandmarks = [
                  PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder,
                  PoseLandmarkType.leftElbow, PoseLandmarkType.rightElbow,
                  PoseLandmarkType.leftHip, PoseLandmarkType.rightHip
                ];
                break;
              case 'jumping_jack':
                requiredLandmarks = [
                  PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder,
                  PoseLandmarkType.leftElbow, PoseLandmarkType.rightElbow,
                  PoseLandmarkType.leftWrist, PoseLandmarkType.rightWrist
                ];
                break;
            }

            // Calculate confidence and visibility
            double poseConfidence = PoseUtils.calculatePoseConfidence(pose, requiredLandmarks);
            List<String> missingLandmarks = PoseUtils.checkBodyVisibility(pose, requiredLandmarks);

            // Get form feedback with new parameters
            final feedbackResult = exerciseLogic.getFormFeedback(
              currentExercise.value,
              angles,
              poseConfidence,
              missingLandmarks,
            );
            
            formScore.value = feedbackResult['confidence'] as int;
            List<String> feedbackMessages = feedbackResult['feedback'] as List<String>;
            
            if (feedbackMessages.isNotEmpty) {
              feedbackText.value = feedbackMessages.join('\n');
            }

            // Count reps only if visible and confident
            if (missingLandmarks.isEmpty && poseConfidence > 0.6) {
              bool repCompleted = exerciseLogic.countReps(
                currentExercise.value,
                angles,
              );
              repCount.value = exerciseLogic.repCount;

              // Announce rep completion (non-blocking)
              if (repCompleted) {
                flutterTts.speak("Rep ${repCount.value}").catchError((_) {});
              }
            }
          } else {
            // Only update feedback if it's been a while since last update to avoid flickering
            if (!feedbackText.value.contains("No person detected")) {
              feedbackText.value = "No person detected. Make sure you are fully in frame.";
            }
            formScore.value = 0;
          }
        }
      });
    } catch (e) {
      // Silently handle errors - don't update UI on every error
      // This prevents infinite error loops
    } finally {
      // ALWAYS reset the flag, even if there was an error
      isDetectingPoses = false;
    }
  }

  // Production-ready YUV420 to NV21 conversion
  // This is the CRITICAL function - must be perfect for ML Kit to work
  InputImage? _convertCameraImageToInputImageSync(CameraImage image) {
    try {
      if (cameraController == null) return null;
      
      final camera = cameraController!.description;
      final int width = image.width;
      final int height = image.height;
      
      // Ensure image size is set
      if (_imageSize == null) {
        _imageSize = Size(width.toDouble(), height.toDouble());
      }

      Uint8List bytes;
      InputImageFormat inputImageFormat;

      if (image.planes.length == 3) {
        // YUV420 format - convert to NV21 (Y plane + interleaved VU plane)
        final yPlane = image.planes[0];
        final uPlane = image.planes[1];
        final vPlane = image.planes[2];

        // Validate planes have data
        if (yPlane.bytes.isEmpty || uPlane.bytes.isEmpty || vPlane.bytes.isEmpty) {
          debugPrint('Empty image planes detected');
          return null;
        }

        final yRowStride = yPlane.bytesPerRow;
        final yPixelStride = yPlane.bytesPerPixel ?? 1;
        final uRowStride = uPlane.bytesPerRow;
        final uPixelStride = uPlane.bytesPerPixel ?? 1;
        final vRowStride = vPlane.bytesPerRow;
        final vPixelStride = vPlane.bytesPerPixel ?? 1;

        // NV21 format: width * height bytes for Y, then (width * height / 4) * 2 for VU
        final int nv21Size = width * height + (width * height ~/ 2);
        bytes = Uint8List(nv21Size);

        // Copy Y plane (luminance) - handle row stride correctly
        final yBytes = yPlane.bytes;
        int yDstIndex = 0;
        for (int row = 0; row < height; row++) {
          final int ySrcIndex = row * yRowStride;
          final int copyLength = (width * yPixelStride).clamp(0, yBytes.length - ySrcIndex);
          if (copyLength > 0 && ySrcIndex < yBytes.length) {
            // Copy pixel by pixel if stride != width
            if (yPixelStride == 1 && yRowStride == width) {
              // Fast path: direct copy
              bytes.setRange(yDstIndex, yDstIndex + width, yBytes, ySrcIndex);
            } else {
              // Slow path: handle stride
              for (int col = 0; col < width && (ySrcIndex + col * yPixelStride) < yBytes.length; col++) {
                bytes[yDstIndex + col] = yBytes[ySrcIndex + col * yPixelStride];
              }
            }
          }
          yDstIndex += width;
        }

        // Interleave V and U planes into NV21 format (VU interleaved)
        // Chroma is subsampled: half width and half height
        final int chromaWidth = width ~/ 2;
        final int chromaHeight = height ~/ 2;
        final uBytes = uPlane.bytes;
        final vBytes = vPlane.bytes;
        int uvDstIndex = width * height; // Start after Y plane

        for (int row = 0; row < chromaHeight; row++) {
          final int uSrcRowStart = row * uRowStride;
          final int vSrcRowStart = row * vRowStride;
          
          for (int col = 0; col < chromaWidth; col++) {
            // Get U and V values from their respective planes with proper bounds checking
            final int uSrcIndex = uSrcRowStart + col * uPixelStride;
            final int vSrcIndex = vSrcRowStart + col * vPixelStride;
            
            // NV21 format: V first, then U (VU interleaved)
            // Use bounds checking to prevent index errors
            if (vSrcIndex >= 0 && vSrcIndex < vBytes.length) {
              bytes[uvDstIndex] = vBytes[vSrcIndex];
            } else {
              bytes[uvDstIndex] = 128; // Default V value (neutral chroma)
            }
            uvDstIndex++;
            
            if (uSrcIndex >= 0 && uSrcIndex < uBytes.length) {
              bytes[uvDstIndex] = uBytes[uSrcIndex];
            } else {
              bytes[uvDstIndex] = 128; // Default U value (neutral chroma)
            }
            uvDstIndex++;
          }
        }
        
        inputImageFormat = InputImageFormat.nv21;
      } else if (image.planes.length == 1) {
        // Single plane - could be grayscale or packed format
        final plane = image.planes[0];
        bytes = Uint8List.fromList(plane.bytes);
        inputImageFormat = (plane.bytesPerPixel ?? 0) == 4
            ? InputImageFormat.bgra8888
            : InputImageFormat.nv21;
      } else {
        // Fallback: concatenate all planes
        final WriteBuffer allBytes = WriteBuffer();
        for (final Plane plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        bytes = allBytes.done().buffer.asUint8List();
        inputImageFormat = InputImageFormat.nv21;
      }

      // Calculate rotation based on sensor orientation
      // For front camera, we may need to adjust rotation
      InputImageRotation imageRotation;
      final sensorOrientation = camera.sensorOrientation;
      
      // Map sensor orientation to InputImageRotation
      // Sensor orientation is the clockwise rotation needed to display correctly
      switch (sensorOrientation) {
        case 90:
          imageRotation = InputImageRotation.rotation90deg;
          break;
        case 180:
          imageRotation = InputImageRotation.rotation180deg;
          break;
        case 270:
          imageRotation = InputImageRotation.rotation270deg;
          break;
        default:
          imageRotation = InputImageRotation.rotation0deg;
      }

      // Create InputImage with proper metadata
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: imageRotation,
          format: inputImageFormat,
          bytesPerRow: width, // For NV21, bytesPerRow should be width for Y plane
        ),
      );
    } catch (e) {
      // Log error for debugging but don't crash
      debugPrint('Image conversion error: $e');
      return null;
    }
  }

  void switchExercise() {
    final currentIndex = availableExercises.indexOf(currentExercise.value);
    final nextIndex = (currentIndex + 1) % availableExercises.length;
    selectExercise(availableExercises[nextIndex]);
  }

  void resetExercise() {
    exerciseLogic.reset();
    repCount.value = 0;
    formScore.value = 100;
    feedbackText.value = "Reset. Ready for ${currentExercise.value.replaceAll('_', ' ')}";
  }

  Size get imageSize => _imageSize ?? Size(720, 1280);
}
