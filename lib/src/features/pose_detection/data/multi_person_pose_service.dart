import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart' as pose_sdk;
import 'package:path_provider/path_provider.dart';
import 'pose_models.dart';

/// A hybrid service that combines Object Detection (to find people) 
/// and Pose Detection (to get skeletons) for ALL detected individuals.
class MultiPersonPoseService {
  late final ObjectDetector _objectDetector;
  final pose_sdk.PoseDetector _poseDetector = pose_sdk.PoseDetector(
    options: pose_sdk.PoseDetectorOptions(model: pose_sdk.PoseDetectionModel.base),
  );

  MultiPersonPoseService() {
    _initializeObjectDetector();
  }

  void _initializeObjectDetector() {
    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: options);
  }

  Future<void> close() async {
    await _objectDetector.close();
    await _poseDetector.close();
  }

  /// Detects poses for all people found in the image.
  Future<List<Map<PoseLandmarkType, PoseLandmark>>> detect(pose_sdk.InputImage inputImage, Uint8List originalBytes) async {
    // Stage 1: Find all people in the frame
    final List<DetectedObject> foundObjects = await _objectDetector.processImage(inputImage);
    final people = foundObjects.where((obj) {
      // Direct match
      if (obj.labels.any((l) => l.text.toLowerCase() == 'person')) return true;
      
      // Heuristic for unlabeled objects: People are typically taller than wide.
      // If no label but it's a "standing" rectangle, it's likely the subject.
      if (obj.labels.isEmpty) {
        final ratio = obj.boundingBox.height / obj.boundingBox.width;
        return ratio > 1.2; // Stricter: filter out horizontal objects (desks, cars, etc.)
      }
      return false;
    }).toList();

    if (people.isEmpty) {
      // Fallback: Just run standard pose on the whole image
      final poses = await _poseDetector.processImage(inputImage);
      return poses.map((p) => _mapLandmarks(p.landmarks)).toList();
    }

    final List<Map<PoseLandmarkType, PoseLandmark>> allPersonLandmarks = [];

    // Stage 2: Process each person
    // To maintain "unnoticeable lag", we'll limit to first 3 people 
    // and use the full image pose as a context.
    
    // First, get the "global" pose (highest confidence person)
    final globalPoses = await _poseDetector.processImage(inputImage);
    if (globalPoses.isNotEmpty) {
      allPersonLandmarks.add(_mapLandmarks(globalPoses.first.landmarks));
    }

    // Capture the image once to work with it
    final codec = await ui.instantiateImageCodec(originalBytes);
    final frame = await codec.getNextFrame();
    final uiImage = frame.image;

    // For other people detected by object detector, we try to get their poses
    // if they aren't already covered by the global pose.
    for (int i = 0; i < people.length && allPersonLandmarks.length < 4; i++) {
        final box = people[i].boundingBox;
        
        // Skip if this box is likely the one already found by global pose
        // (Simplified overlap check)
        bool alreadyTracked = false;
        for (var landmarks in allPersonLandmarks) {
           final nose = landmarks[PoseLandmarkType.nose];
           if (nose != null && box.contains(ui.Offset(nose.x, nose.y))) {
             alreadyTracked = true;
             break;
           }
        }
        if (alreadyTracked) continue;

        // Run Pose on this specific person's region
        final croppedLandmarks = await _detectPoseInRegion(uiImage, box);
        if (croppedLandmarks.isNotEmpty) {
          allPersonLandmarks.add(croppedLandmarks);
        }
    }

    return allPersonLandmarks;
  }

  Future<Map<PoseLandmarkType, PoseLandmark>> _detectPoseInRegion(ui.Image image, ui.Rect rect) async {
    try {
      // 1. Crop the image to the person's bounding box
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      
      // Ensure rect is within image bounds
      final safeRect = ui.Rect.fromLTRB(
        math.max(0, rect.left),
        math.max(0, rect.top),
        math.min(image.width.toDouble(), rect.right),
        math.min(image.height.toDouble(), rect.bottom),
      );

      canvas.drawImageRect(
        image,
        safeRect,
        ui.Rect.fromLTWH(0, 0, safeRect.width, safeRect.height),
        ui.Paint(),
      );
      
      final picture = recorder.endRecording();
      final croppedUiImage = await picture.toImage(safeRect.width.toInt(), safeRect.height.toInt());
      final byteData = await croppedUiImage.toByteData(format: ui.ImageByteFormat.png);
      final croppedBytes = byteData!.buffer.asUint8List();

      // 2. Save temporarily to file for ML Kit InputImage (most stable way in Flutter)
      final tempDir = await getTemporaryDirectory();
      final cropFile = File('${tempDir.path}/crop_${DateTime.now().microsecondsSinceEpoch}.png');
      await cropFile.writeAsBytes(croppedBytes);

      // 3. Run Pose Detector on crop
      final inputImage = pose_sdk.InputImage.fromFile(cropFile);
      final poses = await _poseDetector.processImage(inputImage);
      
      if (poses.isEmpty) return {};

      // 4. Translate coordinates back to global
      final landmarks = _mapLandmarks(poses.first.landmarks);
      final translated = landmarks.map((type, landmark) {
        return MapEntry(type, PoseLandmark(
          type: type,
          x: landmark.x + safeRect.left,
          y: landmark.y + safeRect.top,
          z: landmark.z,
          likelihood: landmark.likelihood,
        ));
      });

      // Cleanup
      await cropFile.delete();
      
      return translated;
    } catch (e) {
      return {};
    }
  }

  Map<PoseLandmarkType, PoseLandmark> _mapLandmarks(Map<pose_sdk.PoseLandmarkType, pose_sdk.PoseLandmark> raw) {
    final Map<PoseLandmarkType, PoseLandmark> result = {};
    raw.forEach((type, landmark) {
       final myType = _mapType(type);
       if (myType != null) {
         result[myType] = PoseLandmark(
           type: myType,
           x: landmark.x,
           y: landmark.y,
           z: landmark.z,
           likelihood: landmark.likelihood,
         );
       }
    });
    return result;
  }

  PoseLandmarkType? _mapType(pose_sdk.PoseLandmarkType type) {
    // Standard mapping (same as MLKitPoseService)
    for (var val in PoseLandmarkType.values) {
      if (val.name == type.name) return val;
    }
    return null;
  }
}
