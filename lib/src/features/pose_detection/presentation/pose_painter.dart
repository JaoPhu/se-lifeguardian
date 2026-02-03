import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;

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

    // Translation helpers
    double translateX(double x, InputImageRotation rotation, Size size, Size absoluteImageSize) {
      final double scaleX = size.width / absoluteImageSize.width;
      final double scaleY = size.height / absoluteImageSize.height;
      final double scale = math.min(scaleX, scaleY);
      
      final double offsetX = (size.width - absoluteImageSize.width * scale) / 2;

      switch (rotation) {
        case InputImageRotation.rotation90deg:
          return x * size.width / absoluteImageSize.height;
        case InputImageRotation.rotation270deg:
          return size.width - x * size.width / absoluteImageSize.height;
        default:
          return x * scale + offsetX;
      }
    }

    double translateY(double y, InputImageRotation rotation, Size size, Size absoluteImageSize) {
      final double scaleX = size.width / absoluteImageSize.width;
      final double scaleY = size.height / absoluteImageSize.height;
      final double scale = math.min(scaleX, scaleY);
      
      final double offsetY = (size.height - absoluteImageSize.height * scale) / 2;

      switch (rotation) {
        case InputImageRotation.rotation90deg:
        case InputImageRotation.rotation270deg:
          return y * size.height / absoluteImageSize.width;
        default:
          return y * scale + offsetY;
      }
    }

    Offset translate(PoseLandmark landmark) {
      double x = translateX(landmark.x, rotation, size, absoluteImageSize);
      double y = translateY(landmark.y, rotation, size, absoluteImageSize);

      if (cameraLensDirection == CameraLensDirection.front) {
        switch (rotation) {
          case InputImageRotation.rotation90deg:
          case InputImageRotation.rotation270deg:
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
      
      canvas.drawLine(translate(p1), translate(p2), paint);
    }

    // Torso
    paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
    paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
    paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);

    // Arms
    paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
    paintLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
    paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
    paintLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);

    // Legs
    paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
    paintLine(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
    paintLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
    paintLine(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);

    // Draw joints
    for (final landmark in landmarks.values) {
       canvas.drawCircle(translate(landmark), 5, jointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.persons != persons ||
           oldDelegate.absoluteImageSize != absoluteImageSize ||
           oldDelegate.rotation != rotation;
  }
}
