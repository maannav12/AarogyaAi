// lib/features/physio_trainer/physio_trainer_page.dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'physio_trainer_controller.dart';
import 'widgets/skeleton_painter.dart';

class PhysioTrainerPage extends GetView<PhysioTrainerController> {
  PhysioTrainerPage({super.key});

  @override
  Widget build(BuildContext context) {
    //Start camera when page is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.isCameraInitialized.value == false) {
        controller.startCamera();
      }
    });
    
    return Scaffold(
      backgroundColor: Colors.black, // Ensure black background
      appBar: AppBar(
        title: Text("Physio Trainer"),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          Obx(() => IconButton(
                icon: Icon(controller.isPaused.value ? Icons.play_arrow : Icons.pause),
                onPressed: controller.togglePause,
                tooltip: controller.isPaused.value ? "Resume" : "Pause",
              )),
        ],
      ),
      body: Obx(() {
        if (!controller.isCameraInitialized.value ||
            controller.cameraController == null) {
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 20),
                  Text(
                    controller.feedbackText.value,
                    style: TextStyle(fontSize: 16, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        return Container(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Camera Preview
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller.imageSize.width,
                    height: controller.imageSize.height,
                    child: CameraPreview(controller.cameraController!),
                  ),
                ),
              ),

            // Skeleton Overlay
            Obx(
              () => controller.showSkeleton.value
                  ? CustomPaint(
                      painter: SkeletonPainter(
                        poses: controller.poses,
                        imageSize: controller.imageSize,
                        mirror: controller.isFrontCamera,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // Top Info Panel
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Exercise Name with Selection
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Obx(
                            () => Text(
                              "Exercise: ${controller.currentExercise.value.replaceAll('_', ' ').toUpperCase()}",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.swap_horiz, color: Colors.white),
                          onPressed: controller.switchExercise,
                          tooltip: "Switch Exercise",
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    // Exercise Mode Selector
                    Container(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: controller.availableExercises.length,
                        itemBuilder: (context, index) {
                          final exercise = controller.availableExercises[index];
                          return Obx(() {
                            final isSelected = controller.currentExercise.value == exercise;
                            return Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(
                                  exercise.replaceAll('_', ' '),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected ? Colors.white : Colors.black87,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    controller.selectExercise(exercise);
                                  }
                                },
                                selectedColor: Colors.blue,
                                backgroundColor: Colors.white70,
                              ),
                            );
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Stats Panel (Left Side)
            Positioned(
              top: 140,
              left: 20,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(
                      () => Row(
                        children: [
                          Icon(Icons.repeat, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Reps: ${controller.repCount.value}",
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    Obx(() {
                      int score = controller.formScore.value;
                      Color scoreColor = score > 80
                          ? Colors.green
                          : (score > 50 ? Colors.orange : Colors.red);
                      return Row(
                        children: [
                          Icon(Icons.star, color: scoreColor, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Form: $score%",
                            style: TextStyle(
                              color: scoreColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Feedback Text (Bottom)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orangeAccent, width: 2),
                ),
                child: Obx(
                  () => Text(
                    controller.feedbackText.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // Control Buttons (Bottom)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Skeleton Toggle
                  Obx(
                    () => FloatingActionButton(
                      heroTag: 'skeletonToggle',
                      backgroundColor: controller.showSkeleton.value
                          ? Colors.green
                          : Colors.grey,
                      onPressed: () {
                        controller.showSkeleton.value =
                            !controller.showSkeleton.value;
                      },
                      child: Icon(Icons.accessibility_new),
                      tooltip: controller.showSkeleton.value
                          ? "Hide Skeleton"
                          : "Show Skeleton",
                    ),
                  ),
                  // Reset Button
                  FloatingActionButton(
                    heroTag: 'reset',
                    backgroundColor: Colors.orange,
                    onPressed: controller.resetExercise,
                    child: Icon(Icons.refresh),
                    tooltip: "Reset Exercise",
                  ),
                  // Camera Switch
                  FloatingActionButton(
                    heroTag: 'cameraSwitch',
                    backgroundColor: Colors.purpleAccent,
                    onPressed: () async {
                      await controller.switchCameraLens();
                    },
                    child: Icon(Icons.switch_camera),
                    tooltip: "Switch Camera",
                  ),
                ],
              ),
            ),
          ],
        ),
        );
      }),
    );
  }
}
