import 'dart:ui';
import 'dart:typed_data';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart' as ml_kit;
import 'pose_detection_interface.dart';
import 'pose_models.dart';

class MLKitPoseService implements IPoseDetectionService {
  final _poseDetector = ml_kit.PoseDetector(options: ml_kit.PoseDetectorOptions(
    mode: ml_kit.PoseDetectionMode.stream,
    model: ml_kit.PoseDetectionModel.accurate
  ));

  @override
  Future<List<Map<PoseLandmarkType, PoseLandmark>>> detect(dynamic input, Uint8List originalBytes) async {
    if (input is! ml_kit.InputImage) {
      return [];
    }

    try {
      final List<ml_kit.Pose> poses = await _poseDetector.processImage(input);
      if (poses.isEmpty) return [];

      final List<Map<PoseLandmarkType, PoseLandmark>> results = [];

      for (final pose in poses) {
        final Map<PoseLandmarkType, PoseLandmark> landmarks = {};
        pose.landmarks.forEach((type, landmark) {
           final myType = _mapMLKitType(type);
           if (myType != null) {
             landmarks[myType] = PoseLandmark(
               type: myType,
               x: landmark.x,
               y: landmark.y,
               z: landmark.z, // ML Kit provides Z (depth)
               likelihood: landmark.likelihood,
             );
           }
        });
        if (landmarks.isNotEmpty) {
           results.add(landmarks);
        }
      }
      
      return results;
    } catch (e) {
      // debugPrint('ML Kit Error: $e');
      return [];
    }
  }

  PoseLandmarkType? _mapMLKitType(ml_kit.PoseLandmarkType type) {
    switch (type) {
      case ml_kit.PoseLandmarkType.nose: return PoseLandmarkType.nose;
      case ml_kit.PoseLandmarkType.leftEyeInner: return PoseLandmarkType.leftEyeInner;
      case ml_kit.PoseLandmarkType.leftEye: return PoseLandmarkType.leftEye;
      case ml_kit.PoseLandmarkType.leftEyeOuter: return PoseLandmarkType.leftEyeOuter;
      case ml_kit.PoseLandmarkType.rightEyeInner: return PoseLandmarkType.rightEyeInner;
      case ml_kit.PoseLandmarkType.rightEye: return PoseLandmarkType.rightEye;
      case ml_kit.PoseLandmarkType.rightEyeOuter: return PoseLandmarkType.rightEyeOuter;
      case ml_kit.PoseLandmarkType.leftEar: return PoseLandmarkType.leftEar;
      case ml_kit.PoseLandmarkType.rightEar: return PoseLandmarkType.rightEar;
      case ml_kit.PoseLandmarkType.leftMouth: return PoseLandmarkType.leftMouth;
      case ml_kit.PoseLandmarkType.rightMouth: return PoseLandmarkType.rightMouth;
      case ml_kit.PoseLandmarkType.leftShoulder: return PoseLandmarkType.leftShoulder;
      case ml_kit.PoseLandmarkType.rightShoulder: return PoseLandmarkType.rightShoulder;
      case ml_kit.PoseLandmarkType.leftElbow: return PoseLandmarkType.leftElbow;
      case ml_kit.PoseLandmarkType.rightElbow: return PoseLandmarkType.rightElbow;
      case ml_kit.PoseLandmarkType.leftWrist: return PoseLandmarkType.leftWrist;
      case ml_kit.PoseLandmarkType.rightWrist: return PoseLandmarkType.rightWrist;
      case ml_kit.PoseLandmarkType.leftPinky: return PoseLandmarkType.leftPinky;
      case ml_kit.PoseLandmarkType.rightPinky: return PoseLandmarkType.rightPinky;
      case ml_kit.PoseLandmarkType.leftIndex: return PoseLandmarkType.leftIndex;
      case ml_kit.PoseLandmarkType.rightIndex: return PoseLandmarkType.rightIndex;
      case ml_kit.PoseLandmarkType.leftThumb: return PoseLandmarkType.leftThumb;
      case ml_kit.PoseLandmarkType.rightThumb: return PoseLandmarkType.rightThumb;
      case ml_kit.PoseLandmarkType.leftHip: return PoseLandmarkType.leftHip;
      case ml_kit.PoseLandmarkType.rightHip: return PoseLandmarkType.rightHip;
      case ml_kit.PoseLandmarkType.leftKnee: return PoseLandmarkType.leftKnee;
      case ml_kit.PoseLandmarkType.rightKnee: return PoseLandmarkType.rightKnee;
      case ml_kit.PoseLandmarkType.leftAnkle: return PoseLandmarkType.leftAnkle;
      case ml_kit.PoseLandmarkType.rightAnkle: return PoseLandmarkType.rightAnkle;
      case ml_kit.PoseLandmarkType.leftHeel: return PoseLandmarkType.leftHeel;
      case ml_kit.PoseLandmarkType.rightHeel: return PoseLandmarkType.rightHeel;
      case ml_kit.PoseLandmarkType.leftFootIndex: return PoseLandmarkType.leftFootIndex;
      case ml_kit.PoseLandmarkType.rightFootIndex: return PoseLandmarkType.rightFootIndex;
      default: return null;
    }
  }

  @override
  Future<void> close() async {
    await _poseDetector.close();
  }
}
