import 'dart:math' as math;

import 'dart:typed_data';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart' as ml_kit;

import 'pose_models.dart';
import '../logic/kalman_filter.dart';
import '../logic/physics_engine.dart';

class TrackedPerson {
  Map<PoseLandmarkType, PoseLandmark> smoothedLandmarks = {};
  math.Point<double> centroid = const math.Point(0, 0);
  math.Point<double> velocity = const math.Point(0, 0); // Legacy: derived from centroid
  
  // New AI Components
  final Map<PoseLandmarkType, PointKalmanFilter> _landmarkFilters = {};
  final PhysicsEngine _physicsEngine = PhysicsEngine();
  Map<PoseLandmarkType, PhysicsData> landmarkPhysics = {};

  int missedCount = 0;
  int seenCount = 0;
  final int id;

  TrackedPerson(this.id, Map<PoseLandmarkType, PoseLandmark> initialLandmarks) {
    smoothedLandmarks = Map<PoseLandmarkType, PoseLandmark>.from(initialLandmarks);
    _updateCentroid();
  }

  void update(Map<PoseLandmarkType, PoseLandmark> rawLandmarks, double factor) {

    final Map<PoseLandmarkType, PoseLandmark> filteredLandmarks = {};

    // 1. Apply Kalman Filter
    rawLandmarks.forEach((PoseLandmarkType type, PoseLandmark landmark) {
       final filter = _landmarkFilters.putIfAbsent(type, () => PointKalmanFilter());
       final filtered = filter.filter(landmark.x, landmark.y);
       
       filteredLandmarks[type] = PoseLandmark(
         type: type,
         x: filtered[0],
         y: filtered[1],
         z: landmark.z,
         likelihood: landmark.likelihood,
       );
    });

    // Update smoothed landmarks with the result
    smoothedLandmarks = filteredLandmarks;

    // 2. Update Physics Engine
    // Pass filtered landmarks for smoother velocity calculation (less noise derivative)
    landmarkPhysics = _physicsEngine.update(filteredLandmarks);
  }

  /// Predict next position based on velocity (Dead Reckoning)
  void predict() {
    centroid = math.Point(centroid.x + velocity.x, centroid.y + velocity.y);
    
    // Shift all landmarks by velocity to keep skeleton consistent during occlusion
    smoothedLandmarks = smoothedLandmarks.map((PoseLandmarkType type, PoseLandmark landmark) {
      return MapEntry(type, PoseLandmark(
        type: type,
        x: landmark.x + velocity.x,
        y: landmark.y + velocity.y,
        z: landmark.z,
        likelihood: landmark.likelihood * 0.9, // Diminish likelihood while occluded
      ));
    });
    
    missedCount++;
  }

  void _updateCentroid() {
    final leftHip = smoothedLandmarks[PoseLandmarkType.leftHip];
    final rightHip = smoothedLandmarks[PoseLandmarkType.rightHip];
    final leftShoulder = smoothedLandmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = smoothedLandmarks[PoseLandmarkType.rightShoulder];
    
    double sumX = 0;
    double sumY = 0;
    int count = 0;

    for (var l in [leftHip, rightHip, leftShoulder, rightShoulder]) {
      if (l != null) {
        sumX += l.x;
        sumY += l.y;
        count++;
      }
    }

    if (count > 0) {
      centroid = math.Point(sumX / count, sumY / count);
    }
  }

  double distanceTo(math.Point<double> other) {
    return math.sqrt(math.pow(centroid.x - other.x, 2) + math.pow(centroid.y - other.y, 2));
  }
}

class PoseDetectionService {
  final ml_kit.PoseDetector _poseDetector = ml_kit.PoseDetector(options: ml_kit.PoseDetectorOptions());
  
  final List<TrackedPerson> _activeTracks = [];

  // Scene Analysis State

  
  // Stability thresholds
  static const int _maxMissedFrames = 60; 

  Future<void> close() async {
    await _poseDetector.close();
  }



  Future<List<TrackedPerson>> detect(ml_kit.InputImage inputImage, Uint8List originalBytes) async {
    // 1. Run Standard ML Kit Pose Detector
    // This returns the most prominent person in the frame (single-person model behavior)
    final List<ml_kit.Pose> poses = await _poseDetector.processImage(inputImage);
    
    // 2. Prediction Step (Physics)
    if (_activeTracks.isNotEmpty) {
      _activeTracks.first.predict();
    }

    if (poses.isEmpty) {

       // Cleanup if lost for too long
       _activeTracks.removeWhere((t) => t.missedCount > _maxMissedFrames);
      return List.from(_activeTracks);
    }

    // 3. Process the Primary Subject
    // We strictly take the first detected pose and force it to be ID 0
    final primaryPose = poses.first;
    final landmarks = _mapLandmarks(primaryPose.landmarks);

    if (_activeTracks.isEmpty) {
      _activeTracks.add(TrackedPerson(0, landmarks));
    } else {
      // Update existing track (always ID 0)
      _activeTracks.first.update(landmarks, 0.6); // 0.6 smoothing factor
      _activeTracks.first.missedCount = 0;
    }

    // 4. Post-Process Analysis


    return List.from(_activeTracks);
  }

  Map<PoseLandmarkType, PoseLandmark> _mapLandmarks(Map<ml_kit.PoseLandmarkType, ml_kit.PoseLandmark> raw) {
    // Map SDK types to our domain types manually to resolve type mismatch
    final Map<PoseLandmarkType, PoseLandmark> result = {};
    
    raw.forEach((ml_kit.PoseLandmarkType type, ml_kit.PoseLandmark landmark) {
       // Convert SDK type to our Domain type via name matching
       for (var ourType in PoseLandmarkType.values) {
         if (ourType.name == type.name) {
           result[ourType] = PoseLandmark(
             type: ourType,
             x: landmark.x,
             y: landmark.y,
             z: landmark.z,
             likelihood: landmark.likelihood,
           );
           break;
         }
       }
    });
    return result;
  }



  /// Calculates the angle of the torso relative to the vertical axis.
  /// Ported from Prototype: 90 = Upright, 0 = Flat.
  double getTorsoAngle(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];

    if (leftShoulder == null || rightShoulder == null || leftHip == null || rightHip == null) {
      return 0;
    }

    final midShoulderX = (leftShoulder.x + rightShoulder.x) / 2;
    final midShoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    final midHipX = (leftHip.x + rightHip.x) / 2;
    final midHipY = (leftHip.y + rightHip.y) / 2;

    final dx = midShoulderX - midHipX;
    final dy = midShoulderY - midHipY; 

    // atan2(abs(dy), abs(dx)) gives angle with horizontal
    // verticality where 90 is Upright, 0 is Flat.
    final angleRad = math.atan2(dy.abs(), dx.abs());
    return angleRad * (180 / math.pi);
  }

  double getLegStraightness(Map<PoseLandmarkType, PoseLandmark> landmarks) {
  /// Calculates the angle between three landmarks using atan2 (Anatomical Standard).
  double getAngle(PoseLandmark? first, PoseLandmark? mid, PoseLandmark? last) {
    if (first == null || mid == null || last == null) return 0;
    
    final double result = (
      math.atan2(last.y - mid.y, last.x - mid.x) -
      math.atan2(first.y - mid.y, first.x - mid.x)
    ).abs() * (180 / math.pi);
    
    return result > 180 ? 360 - result : result;
  }

    final leftBend = getAngle(
      landmarks[PoseLandmarkType.leftHip],
      landmarks[PoseLandmarkType.leftKnee],
      landmarks[PoseLandmarkType.leftAnkle],
    );

    final rightBend = getAngle(
      landmarks[PoseLandmarkType.rightHip],
      landmarks[PoseLandmarkType.rightKnee],
      landmarks[PoseLandmarkType.rightAnkle],
    );

    return math.min(leftBend, rightBend);
  }

  bool isLaying(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    if (landmarks.isEmpty) return false;
    final torsoAngle = getTorsoAngle(landmarks);
    
    final xValues = landmarks.values.map((l) => l.x).toList();
    final yValues = landmarks.values.map((l) => l.y).toList();
    if (xValues.isEmpty || yValues.isEmpty) return false;
    
    final width = xValues.reduce(math.max) - xValues.reduce(math.min);
    final height = yValues.reduce(math.max) - yValues.reduce(math.min);
    
    // Prototype check: torso < 25 or isFlat
    final isFlat = width > height * 1.4;

    return torsoAngle < 25 || isFlat;
  }

  bool isStanding(Map<PoseLandmarkType, PoseLandmark> landmarks) {
     if (landmarks.isEmpty) return false;
     final torsoAngle = getTorsoAngle(landmarks);
     if (torsoAngle < 60) return false;
     
     final legBend = getLegStraightness(landmarks);
     return legBend < 25; // Very straight
  }

  bool isWalking(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    if (landmarks.isEmpty) return false;
    final torsoAngle = getTorsoAngle(landmarks);
    if (torsoAngle < 60) return false;
    
    final legBend = getLegStraightness(landmarks);
    return legBend >= 25 && legBend < 65;
  }

  bool isFalling(TrackedPerson person) {
    if (person.landmarkPhysics.isEmpty) return false;
    
    final height = _getBodyHeight(person.smoothedLandmarks);
    if (height < 50) return false; // Too small / far away

    double maxAcc = 0;
    double maxDownVel = 0;
    
    // Check hips for fall dynamics
    for (var type in [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip]) {
      if (person.landmarkPhysics.containsKey(type)) {
        final physics = person.landmarkPhysics[type]!;
        if (physics.vy > maxDownVel) maxDownVel = physics.vy;
        if (physics.acceleration > maxAcc) maxAcc = physics.acceleration;
      }
    }
    
    // Fall: Downward speed > 1.5 body heights/sec OR Impact > 6 body heights/sec^2
    // Reduced impact threshold slightly to be more sensitive to sudden stops
    return maxDownVel > (height * 1.5) || maxAcc > (height * 6.0);
  }

  double _getBodyHeight(Map<PoseLandmarkType, PoseLandmark> landmarks) {
      final nose = landmarks[PoseLandmarkType.nose];
      final leftAnkle = landmarks[PoseLandmarkType.leftAnkle]; 
      final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];
      
      final double? y1 = nose?.y;
      double? y2;
      
      if (leftAnkle != null && rightAnkle != null) {
          y2 = (leftAnkle.y + rightAnkle.y) / 2;
      } else if (leftAnkle != null) {
          y2 = leftAnkle.y;
      } else if (rightAnkle != null) {
          y2 = rightAnkle.y;
      }
      
      if (y1 != null && y2 != null) {
          return (y1 - y2).abs();
      }
      return 100.0;
  }
}
