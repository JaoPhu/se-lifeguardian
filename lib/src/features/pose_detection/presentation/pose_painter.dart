import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart' hide PoseLandmark, PoseLandmarkType;
import '../data/pose_models.dart';

class PersonPose {
  final int id;
  final Map<PoseLandmarkType, PoseLandmark> landmarks;
  final Color color;
  final bool isLaying;
  final bool isSitting;
  final bool isSlouching;
  final bool isWalking;
  final bool isFalling;

  PersonPose({
    required this.id,
    required this.landmarks,
    required this.color,
    this.isLaying = false,
    this.isSitting = false,
    this.isSlouching = false,
    this.isWalking = false,
    this.isFalling = false,
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



    // Standardize coordinate translation to match the camera feed exactly
    // detailed logic adapted from ML Kit Quickstart (Research Standard)
    
    double translateX(double x, double y, InputImageRotation rotation) {
       // For portrait (90/270), the image buffer's X/Y are swapped relative to the screen
       if (Platform.isIOS) {
          switch (rotation) {
            case InputImageRotation.rotation90deg:
            case InputImageRotation.rotation270deg:
               // In portrait on iOS, the buffer Y corresponds to screen X
               // Y ranges from 0 to absoluteImageSize.height, so we divide by height
               return y * size.width / absoluteImageSize.height;
            default:
               return x * size.width / absoluteImageSize.width;
          }
       } else {
          switch (rotation) {
            case InputImageRotation.rotation90deg:
            case InputImageRotation.rotation270deg:
               return x * size.width / absoluteImageSize.height;
            default:
               return x * size.width / absoluteImageSize.width;
          }
       }
    }

    double translateY(double x, double y, InputImageRotation rotation) {
       if (Platform.isIOS) {
          switch (rotation) {
            case InputImageRotation.rotation90deg:
            case InputImageRotation.rotation270deg:
               // In portrait on iOS, the buffer X corresponds to screen Y
               // X ranges from 0 to absoluteImageSize.width, so we divide by width
               return x * size.height / absoluteImageSize.width;
            default:
               return y * size.height / absoluteImageSize.height;
          }
       } else {
          switch (rotation) {
            case InputImageRotation.rotation90deg:
            case InputImageRotation.rotation270deg:
               return y * size.height / absoluteImageSize.width;
            default:
               return y * size.height / absoluteImageSize.height;
          }
       }
    }

    Offset translate(PoseLandmark landmark) {
      final double x = landmark.x;
      final double y = landmark.y;
      
      double tx = translateX(x, y, rotation);
      final double ty = translateY(x, y, rotation);

      if (cameraLensDirection == CameraLensDirection.front) {
        // Mirror X-axis for front (selfie) camera
        tx = size.width - tx;
      }
      
      return Offset(tx, ty);
    }

    // Draw connections (skeleton) with 3D Depth awareness
    void paintLine(PoseLandmarkType type1, PoseLandmarkType type2) {
      final p1 = landmarks[type1];
      final p2 = landmarks[type2];
      if (p1 == null || p2 == null) return;
      
      const double threshold = 0.5;
      if (p1.likelihood < threshold || p2.likelihood < threshold) return;
      
      // Calculate avg depth for line thickness (closer = thicker)
      // ML Kit Z: Smaller is closer. 
      // We normalize around 0 (hips). Values typically range from -500 to 500
      final avgZ = (p1.z + p2.z) / 2;
      final depthFactor = (1.0 - (avgZ / 1000.0)).clamp(0.5, 2.0);
      
      final linePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0 * depthFactor
        ..color = color.withValues(alpha: (0.3 + 0.7 * depthFactor).clamp(0.0, 1.0));
      
      canvas.drawLine(translate(p1), translate(p2), linePaint);
    }

    // --- Connections (Same as before but with depth paint) ---
    paintLine(PoseLandmarkType.nose, PoseLandmarkType.leftEyeInner);
    paintLine(PoseLandmarkType.leftEyeInner, PoseLandmarkType.leftEye);
    paintLine(PoseLandmarkType.leftEye, PoseLandmarkType.leftEyeOuter);
    paintLine(PoseLandmarkType.leftEyeOuter, PoseLandmarkType.leftEar);
    paintLine(PoseLandmarkType.nose, PoseLandmarkType.rightEyeInner);
    paintLine(PoseLandmarkType.rightEyeInner, PoseLandmarkType.rightEye);
    paintLine(PoseLandmarkType.rightEye, PoseLandmarkType.rightEyeOuter);
    paintLine(PoseLandmarkType.rightEyeOuter, PoseLandmarkType.rightEar);
    paintLine(PoseLandmarkType.leftMouth, PoseLandmarkType.rightMouth);

    paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
    paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
    paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);

    paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
    paintLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
    paintLine(PoseLandmarkType.leftWrist, PoseLandmarkType.leftThumb);
    paintLine(PoseLandmarkType.leftWrist, PoseLandmarkType.leftIndex);
    paintLine(PoseLandmarkType.leftWrist, PoseLandmarkType.leftPinky);
    paintLine(PoseLandmarkType.leftIndex, PoseLandmarkType.leftPinky);

    paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
    paintLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);
    paintLine(PoseLandmarkType.rightWrist, PoseLandmarkType.rightThumb);
    paintLine(PoseLandmarkType.rightWrist, PoseLandmarkType.rightIndex);
    paintLine(PoseLandmarkType.rightWrist, PoseLandmarkType.rightPinky);
    paintLine(PoseLandmarkType.rightIndex, PoseLandmarkType.rightPinky);

    paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
    paintLine(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
    paintLine(PoseLandmarkType.leftAnkle, PoseLandmarkType.leftHeel);
    paintLine(PoseLandmarkType.leftAnkle, PoseLandmarkType.leftFootIndex);
    paintLine(PoseLandmarkType.leftHeel, PoseLandmarkType.leftFootIndex);

    paintLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
    paintLine(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);
    paintLine(PoseLandmarkType.rightAnkle, PoseLandmarkType.rightHeel);
    paintLine(PoseLandmarkType.rightAnkle, PoseLandmarkType.rightFootIndex);
    paintLine(PoseLandmarkType.rightHeel, PoseLandmarkType.rightFootIndex);

    // Draw joints with Depth (Z-aware)
    for (final entry in landmarks.entries) {
      final type = entry.key;
      final landmark = entry.value;
      if (landmark.likelihood < 0.5) continue;
      
      final pos = translate(landmark);
      final zFactor = (1.0 - (landmark.z / 1000.0)).clamp(0.5, 2.5);
      
      // Joint color darker if further away
      final depthColor = ui.Color.lerp(Colors.black, color, (0.4 + 0.6 * zFactor).clamp(0.0, 1.0)) ?? color;

      canvas.drawCircle(pos, 3.5 * zFactor, Paint()..color = depthColor);
      
      // Glow effect also scales with depth
      canvas.drawCircle(
        pos, 
        8 * zFactor, 
        Paint()..color = color.withValues(alpha: (0.15 * zFactor).clamp(0.0, 0.4))..style = PaintingStyle.fill
      );

      // --- Subtle Anatomical Labels for 3D orientation ---
      if (type == PoseLandmarkType.leftShoulder || 
          type == PoseLandmarkType.rightShoulder ||
          type == PoseLandmarkType.leftHip ||
          type == PoseLandmarkType.rightHip) {
        
        final textPainter = TextPainter(
          text: TextSpan(
            text: type.name.split('.').last.substring(0, 1).toUpperCase() + type.name.split('.').last.substring(1),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 9 * zFactor.clamp(0.8, 1.2),
              fontWeight: FontWeight.w600,
              shadows: const [Shadow(blurRadius: 2, color: Colors.black)],
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(pos.dx + 10, pos.dy - 10));
      }
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.persons != persons ||
           oldDelegate.absoluteImageSize != absoluteImageSize ||
           oldDelegate.rotation != rotation;
  }
}
