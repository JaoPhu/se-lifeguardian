import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PersonPose {
  final Map<PoseLandmarkType, PoseLandmark> landmarks;
  final Color color;
  final bool isLaying;
  final bool isWalking;

  PersonPose({
    required this.landmarks,
    required this.color,
    this.isLaying = false,
    this.isWalking = false,
  });
}

class PosePainter extends CustomPainter {
  PosePainter(
    this.persons,
    this.absoluteImageSize,
    this.rotation,
    this.cameraLensDirection,
  );

  final List<PersonPose> persons;
  final Size absoluteImageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (persons.isEmpty) return;

    for (final person in persons) {
      _paintPerson(canvas, size, person);
    }
  }

  void _paintPerson(Canvas canvas, Size size, PersonPose person) {
    final landmarks = person.landmarks;
    final color = person.color;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = color;

    // Use unified color for all parts as requested
    final jointPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    double translateX(double x) {
      if (rotation == InputImageRotation.rotation90deg || rotation == InputImageRotation.rotation270deg) {
        return x * size.width / absoluteImageSize.height;
      } else {
        return x * size.width / absoluteImageSize.width;
      }
    }

    double translateY(double y) {
      if (rotation == InputImageRotation.rotation90deg || rotation == InputImageRotation.rotation270deg) {
        return y * size.height / absoluteImageSize.width;
      } else {
        return y * size.height / absoluteImageSize.height;
      }
    }

    Offset translate(PoseLandmark landmark) {
      double x = translateX(landmark.x);
      double y = translateY(landmark.y);

      if (cameraLensDirection == CameraLensDirection.front) {
        switch (rotation) {
          case InputImageRotation.rotation90deg:
          case InputImageRotation.rotation270deg:
            // For 90/270, the x-axis in buffer might need different mirroring
            // but standard MLKit usually mirrors at the end if front-facing
            x = size.width - x;
            break;
          default:
            x = size.width - x;
            break;
        }
      }
      return Offset(x, y);
    }

    // Draw connections (skeleton)
    void paintLine(PoseLandmarkType type1, PoseLandmarkType type2) {
      final p1 = landmarks[type1];
      final p2 = landmarks[type2];
      if (p1 == null || p2 == null) return;
      
      // Use standard likelihood threshold for stable visualization
      const double threshold = 0.5;
      if (p1.likelihood < threshold || p2.likelihood < threshold) return;
      
      canvas.drawLine(translate(p1), translate(p2), paint);
    }

    // --- Face (High Fidelity Details) ---
    paintLine(PoseLandmarkType.nose, PoseLandmarkType.leftEyeInner);
    paintLine(PoseLandmarkType.leftEyeInner, PoseLandmarkType.leftEye);
    paintLine(PoseLandmarkType.leftEye, PoseLandmarkType.leftEyeOuter);
    paintLine(PoseLandmarkType.leftEyeOuter, PoseLandmarkType.leftEar);
    paintLine(PoseLandmarkType.nose, PoseLandmarkType.rightEyeInner);
    paintLine(PoseLandmarkType.rightEyeInner, PoseLandmarkType.rightEye);
    paintLine(PoseLandmarkType.rightEye, PoseLandmarkType.rightEyeOuter);
    paintLine(PoseLandmarkType.rightEyeOuter, PoseLandmarkType.rightEar);
    paintLine(PoseLandmarkType.leftMouth, PoseLandmarkType.rightMouth);

    // --- Torso & Shoulders ---
    paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
    paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
    paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);

    // --- Left Arm & Hand ---
    paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
    paintLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
    paintLine(PoseLandmarkType.leftWrist, PoseLandmarkType.leftThumb);
    paintLine(PoseLandmarkType.leftWrist, PoseLandmarkType.leftIndex);
    paintLine(PoseLandmarkType.leftWrist, PoseLandmarkType.leftPinky);
    paintLine(PoseLandmarkType.leftIndex, PoseLandmarkType.leftPinky);

    // --- Right Arm & Hand ---
    paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
    paintLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);
    paintLine(PoseLandmarkType.rightWrist, PoseLandmarkType.rightThumb);
    paintLine(PoseLandmarkType.rightWrist, PoseLandmarkType.rightIndex);
    paintLine(PoseLandmarkType.rightWrist, PoseLandmarkType.rightPinky);
    paintLine(PoseLandmarkType.rightIndex, PoseLandmarkType.rightPinky);

    // --- Left Leg & Foot ---
    paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
    paintLine(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
    paintLine(PoseLandmarkType.leftAnkle, PoseLandmarkType.leftHeel);
    paintLine(PoseLandmarkType.leftAnkle, PoseLandmarkType.leftFootIndex);
    paintLine(PoseLandmarkType.leftHeel, PoseLandmarkType.leftFootIndex);

    // --- Right Leg & Foot ---
    paintLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
    paintLine(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);
    paintLine(PoseLandmarkType.rightAnkle, PoseLandmarkType.rightHeel);
    paintLine(PoseLandmarkType.rightAnkle, PoseLandmarkType.rightFootIndex);
    paintLine(PoseLandmarkType.rightHeel, PoseLandmarkType.rightFootIndex);

    // Draw joints
    for (final landmark in landmarks.values) {
      if (landmark.likelihood < 0.5) continue;
      canvas.drawCircle(translate(landmark), 3.5, jointPaint);
      
      // Add subtle glow to joints
      canvas.drawCircle(
        translate(landmark), 
        6, 
        Paint()..color = color.withValues(alpha: 0.2)..style = PaintingStyle.fill
      );
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.persons != persons ||
           oldDelegate.absoluteImageSize != absoluteImageSize ||
           oldDelegate.rotation != rotation;
  }
}
