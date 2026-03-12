import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart' hide PoseLandmark, PoseLandmarkType;
import '../data/pose_models.dart';

class PersonPose {
  final int id;
  final Map<PoseLandmarkType, PoseLandmark> landmarks;
  final Color color;
  final String activity;
  final bool isLaying;
  final bool isSitting;
  final bool isSlouching;
  final bool isWalking;
  final bool isFalling;
  final bool isExercise;

  PersonPose({
    required this.id,
    required this.landmarks,
    required this.color,
    this.activity = 'unknown',
    this.isLaying = false,
    this.isSitting = false,
    this.isSlouching = false,
    this.isWalking = false,
    this.isFalling = false,
    this.isExercise = false,
  });
}

enum CameraLensDirection { front, back, external }

class PosePainter extends CustomPainter {
  PosePainter(
    this.persons,
    this.absoluteImageSize,
    this.rotation,
  );

  final List<PersonPose> persons;
  final Size absoluteImageSize;
  final InputImageRotation rotation;

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

    double translateX(double x, double y, InputImageRotation rotation) {
       if (Platform.isIOS) {
          switch (rotation) {
            case InputImageRotation.rotation90deg:
            case InputImageRotation.rotation270deg:
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
      return Offset(translateX(landmark.x, landmark.y, rotation), translateY(landmark.x, landmark.y, rotation));
    }

    void paintLine(PoseLandmarkType type1, PoseLandmarkType type2) {
      final p1 = landmarks[type1];
      final p2 = landmarks[type2];
      if (p1 == null || p2 == null) return;
      
      const double threshold = 0.5;
      if (p1.likelihood < threshold || p2.likelihood < threshold) return;
      
      final avgZ = (p1.z + p2.z) / 2;
      final depthFactor = (1.0 - (avgZ / 1000.0)).clamp(0.5, 2.0);
      
      final linePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0 * depthFactor
        ..color = color.withValues(alpha: (0.3 + 0.7 * depthFactor).clamp(0.0, 1.0));
      
      canvas.drawLine(translate(p1), translate(p2), linePaint);
    }

    // Connections
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
    paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
    paintLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);
    paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
    paintLine(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
    paintLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
    paintLine(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);

    // Joints
    for (final entry in landmarks.entries) {
      final type = entry.key;
      final landmark = entry.value;
      if (landmark.likelihood < 0.5) continue;
      
      final pos = translate(landmark);
      final zFactor = (1.0 - (landmark.z / 1000.0)).clamp(0.5, 2.5);
      final depthColor = ui.Color.lerp(Colors.black, color, (0.4 + 0.6 * zFactor).clamp(0.0, 1.0)) ?? color;

      canvas.drawCircle(pos, 3.5 * zFactor, Paint()..color = depthColor);
      canvas.drawCircle(pos, 8 * zFactor, Paint()..color = color.withValues(alpha: (0.15 * zFactor).clamp(0.0, 0.4))..style = PaintingStyle.fill);

      if (type == PoseLandmarkType.leftShoulder || type == PoseLandmarkType.rightShoulder || type == PoseLandmarkType.leftHip || type == PoseLandmarkType.rightHip) {
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

    // --- Activity Label (Direct AI output) ---
    final center = _getPersonCenter(landmarks);
    if (center != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: person.activity.toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            backgroundColor: color.withValues(alpha: 0.8),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final pos = translate(landmarks[PoseLandmarkType.nose] ?? landmarks.values.first);
      textPainter.paint(canvas, Offset(pos.dx - textPainter.width / 2, pos.dy - 30));
    }
  }

  Offset? _getPersonCenter(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final lHip = landmarks[PoseLandmarkType.leftHip];
    final rHip = landmarks[PoseLandmarkType.rightHip];
    final lSho = landmarks[PoseLandmarkType.leftShoulder];
    final rSho = landmarks[PoseLandmarkType.rightShoulder];
    
    double sumX = 0;
    double sumY = 0;
    int count = 0;
    for (var l in [lHip, rHip, lSho, rSho]) {
      if (l != null) {
        sumX += l.x;
        sumY += l.y;
        count++;
      }
    }
    return count > 0 ? Offset(sumX / count, sumY / count) : null;
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.persons != persons ||
           oldDelegate.absoluteImageSize != absoluteImageSize ||
           oldDelegate.rotation != rotation;
  }
}
