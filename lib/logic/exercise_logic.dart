// lib/logic/exercise_logic.dart
import 'dart:math';

enum ExerciseState { neutral, starting, middle, completed }

class ExerciseLogic {
  final Map<String, Map<String, double>> thresholds = {
    'tree_pose': {
      'knee_bend': 25.0,
      'balance_duration': 3.0, // Increased for better stability check
      'hip_variance': 15.0,
    },
    'squat': {
      'down': 100.0,
      'up': 160.0, // Stricter up
      'knee_alignment': 20.0, // Stricter alignment
    },
    'pushup': {
      'down': 90.0, // Deeper pushup
      'up': 160.0,
      'hip_variance': 15.0,
    },
    'jumping_jack': {
      'down': 30.0,
      'up': 150.0, // Arms higher
    }
  };

  ExerciseState exerciseState = ExerciseState.neutral;
  int repCount = 0;
  DateTime? poseStartTime;
  DateTime? lastStateChangeTime;
  static const Duration stateDebounceTime = Duration(milliseconds: 300);

  double _getAngle(Map<String, double> angles, String name) {
    return angles[name] ?? 0.0;
  }

  void reset() {
    repCount = 0;
    exerciseState = ExerciseState.neutral;
    poseStartTime = null;
    lastStateChangeTime = null;
  }

  bool countReps(String exercise, Map<String, double> angles) {
    DateTime currentTime = DateTime.now();
    
    // Debounce state changes
    if (lastStateChangeTime != null && 
        currentTime.difference(lastStateChangeTime!) < stateDebounceTime) {
      return false;
    }

    bool repCompleted = false;

    switch (exercise) {
      case 'tree_pose':
        // Tree pose is time-based, not rep-based in the traditional sense
        // Logic handled in getFormFeedback mostly, but we can track "successful holds" here
        break;
        
      case 'squat':
        double rightKnee = _getAngle(angles, 'right_knee');
        double leftKnee = _getAngle(angles, 'left_knee');
        if (rightKnee > 0 && leftKnee > 0) {
          double kneeAngle = (rightKnee + leftKnee) / 2;
          
          if (exerciseState == ExerciseState.neutral || exerciseState == ExerciseState.starting) {
             if (kneeAngle > thresholds['squat']!['up']!) {
               exerciseState = ExerciseState.starting;
             }
             if (kneeAngle < thresholds['squat']!['down']!) {
               exerciseState = ExerciseState.middle;
               lastStateChangeTime = currentTime;
             }
          } else if (exerciseState == ExerciseState.middle) {
            if (kneeAngle > thresholds['squat']!['up']!) {
              exerciseState = ExerciseState.starting;
              repCount++;
              repCompleted = true;
              lastStateChangeTime = currentTime;
            }
          }
        }
        break;
        
      case 'pushup':
        double rightElbow = _getAngle(angles, 'right_elbow');
        double leftElbow = _getAngle(angles, 'left_elbow');
        if (rightElbow > 0 && leftElbow > 0) {
          double elbowAngle = (rightElbow + leftElbow) / 2;
          
          if (exerciseState == ExerciseState.neutral || exerciseState == ExerciseState.starting) {
            if (elbowAngle > thresholds['pushup']!['up']!) {
              exerciseState = ExerciseState.starting;
            }
            if (elbowAngle < thresholds['pushup']!['down']!) {
              exerciseState = ExerciseState.middle;
              lastStateChangeTime = currentTime;
            }
          } else if (exerciseState == ExerciseState.middle) {
            if (elbowAngle > thresholds['pushup']!['up']!) {
              exerciseState = ExerciseState.starting;
              repCount++;
              repCompleted = true;
              lastStateChangeTime = currentTime;
            }
          }
        }
        break;
        
      case 'jumping_jack':
        double rightShoulder = _getAngle(angles, 'right_shoulder');
        double leftShoulder = _getAngle(angles, 'left_shoulder');
        if (rightShoulder > 0 && leftShoulder > 0) {
          double shoulderAngle = (rightShoulder + leftShoulder) / 2;
          
          if (exerciseState == ExerciseState.neutral || exerciseState == ExerciseState.starting) {
            if (shoulderAngle < thresholds['jumping_jack']!['down']!) {
              exerciseState = ExerciseState.starting; // Arms down
            }
            if (shoulderAngle > thresholds['jumping_jack']!['up']!) {
              exerciseState = ExerciseState.middle; // Arms up
              lastStateChangeTime = currentTime;
            }
          } else if (exerciseState == ExerciseState.middle) {
            if (shoulderAngle < thresholds['jumping_jack']!['down']!) {
              exerciseState = ExerciseState.starting;
              repCount++;
              repCompleted = true;
              lastStateChangeTime = currentTime;
            }
          }
        }
        break;
    }
    return repCompleted;
  }

  Map<String, dynamic> getFormFeedback(
      String exercise, 
      Map<String, double> angles, 
      double poseConfidence, 
      List<String> missingLandmarks) {
    
    int confidence = (poseConfidence * 100).round();
    List<String> feedback = [];

    // 1. Visibility Check (Highest Priority)
    if (missingLandmarks.isNotEmpty) {
      if (missingLandmarks.length > 3) {
        feedback.add("Whole body not visible");
      } else {
        feedback.add("${missingLandmarks.join(', ')} not visible");
      }
      // If critical parts are missing, we can't judge form
      return {'confidence': 0, 'feedback': feedback}; 
    }

    // 2. Confidence Check
    if (poseConfidence < 0.6) {
      feedback.add("Improve lighting or stand still");
      return {'confidence': confidence, 'feedback': feedback};
    }

    void addFeedback(String msg) {
      if (!feedback.contains(msg)) {
        feedback.add(msg);
      }
    }

    // 3. Form Check
    switch (exercise) {
      case 'tree_pose':
        double rightKnee = _getAngle(angles, 'right_knee');
        double leftKnee = _getAngle(angles, 'left_knee');
        double rightHip = _getAngle(angles, 'right_hip');
        double leftHip = _getAngle(angles, 'left_hip');
        
        // Determine which leg is raised (the one with smaller knee angle)
        bool rightLegRaised = rightKnee < leftKnee;
        double raisedKneeAngle = rightLegRaised ? rightKnee : leftKnee;
        double standingKneeAngle = rightLegRaised ? leftKnee : rightKnee;
        
        if (standingKneeAngle < 160) {
           addFeedback("Straighten standing leg");
        }
        
        if (raisedKneeAngle > 45) { // Threshold for "bent enough"
           addFeedback("Bend raised knee more");
        }

        double hipDiff = (rightHip - leftHip).abs();
        if (hipDiff > thresholds['tree_pose']!['hip_variance']!) {
          addFeedback("Keep hips level");
        }
        
        // Tree pose holding logic
        if (feedback.isEmpty) {
           if (poseStartTime == null) {
             poseStartTime = DateTime.now();
             addFeedback("Hold position...");
           } else {
             final duration = DateTime.now().difference(poseStartTime!).inSeconds;
             if (duration < thresholds['tree_pose']!['balance_duration']!) {
                addFeedback("Hold... ${thresholds['tree_pose']!['balance_duration']!.toInt() - duration}s");
             } else {
                addFeedback("Great balance!");
                // Could increment a "hold count" here if desired
             }
           }
        } else {
          poseStartTime = null; // Reset timer if form breaks
        }
        break;
        
      case 'squat':
        double rightKnee = _getAngle(angles, 'right_knee');
        double leftKnee = _getAngle(angles, 'left_knee');
        double kneeAngle = (rightKnee + leftKnee) / 2;
        double kneeDiff = (rightKnee - leftKnee).abs();

        if (exerciseState == ExerciseState.middle) { // Down position
           if (kneeAngle > thresholds['squat']!['down']!) {
             addFeedback("Go lower");
           }
        }
        
        if (kneeDiff > thresholds['squat']!['knee_alignment']!) {
          addFeedback("Keep knees symmetric");
        }
        
        // Check for knees caving in (requires hip/ankle context, simplified here as knee alignment)
        break;
        
      case 'pushup':
        double rightElbow = _getAngle(angles, 'right_elbow');
        double leftElbow = _getAngle(angles, 'left_elbow');
        double rightHip = _getAngle(angles, 'right_hip');
        double leftHip = _getAngle(angles, 'left_hip');
        
        double hipAngle = (rightHip + leftHip) / 2;
        
        if (hipAngle < 150) {
          addFeedback("Don't sag hips");
        } else if (hipAngle > 200) { // Hyperextension check (approx)
          addFeedback("Lower hips");
        }

        if (exerciseState == ExerciseState.middle) {
           double elbowAngle = (rightElbow + leftElbow) / 2;
           if (elbowAngle > thresholds['pushup']!['down']!) {
             addFeedback("Chest lower");
           }
        }
        break;
        
      case 'jumping_jack':
        double rightShoulder = _getAngle(angles, 'right_shoulder');
        double leftShoulder = _getAngle(angles, 'left_shoulder');
        double shoulderAngle = (rightShoulder + leftShoulder) / 2;
        
        if (exerciseState == ExerciseState.middle) { // Arms up
           if (shoulderAngle < thresholds['jumping_jack']!['up']!) {
             addFeedback("Clap hands overhead");
           }
        } else if (exerciseState == ExerciseState.starting) { // Arms down
           if (shoulderAngle > thresholds['jumping_jack']!['down']!) {
             addFeedback("Arms all the way down");
           }
        }
        break;
    }

    if (feedback.isEmpty) {
      addFeedback("Perfect form!");
      confidence = 100;
    } else {
      // Reduce confidence based on number of errors
      confidence = max(0, confidence - (feedback.length * 20));
    }

    return {'confidence': confidence, 'feedback': feedback};
  }
}