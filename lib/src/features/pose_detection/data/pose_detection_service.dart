import 'dart:math' as math;

import 'dart:typed_data';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart' as ml_kit;
import 'optimized_pose_classifier.dart';
import 'pose_models.dart';
import '../logic/kalman_filter.dart';
import '../logic/physics_engine.dart';

class TrackedPerson {
  final int id;
  int missedCount = 0;
  Map<PoseLandmarkType, PoseLandmark> smoothedLandmarks = {};
  math.Point<double> centroid = const math.Point(0, 0);
  math.Point<double> velocity = const math.Point(0, 0); // Legacy: derived from centroid
  
  // New AI Components
  final Map<PoseLandmarkType, PointKalmanFilter> _landmarkFilters = {};
  final PhysicsEngine _physicsEngine = PhysicsEngine();
  Map<PoseLandmarkType, PhysicsData> landmarkPhysics = {};

  // Health Monitoring
  DateTime? sitStartTime;
  DateTime? lastSlouchTime;
  Duration totalSlouchDuration = Duration.zero;
  bool isCurrentlySlouching = false;

  TrackedPerson(this.id, Map<PoseLandmarkType, PoseLandmark> initialLandmarks) {
    smoothedLandmarks = Map<PoseLandmarkType, PoseLandmark>.from(initialLandmarks);
    _updateCentroid();
    sitStartTime = DateTime.now();
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
  final OptimizedPoseClassifier _classifier = OptimizedPoseClassifier();
  
  Future<void> initialize() async {
    await _classifier.initialize();
  }
  
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
    
    // Relaxed isFlat constraint from 1.2 to 0.85 to catch overhead camera poses
    // Top-down lay-down bounding boxes are often squarish rather than fully wide
    final isFlat = width > height * 0.85;

    // A person is likely laying down if their torso is very horizontal (< 30)
    // OR they are flat on the ground
    // OR their torso is somewhat horizontal (< 50) AND their bounding box is wider than tall (scrunched)
    return torsoAngle < 35 || isFlat || (torsoAngle < 55 && width > height * 0.9);
  }

  bool isSlouching(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    if (landmarks.isEmpty) return false;
    final torsoAngle = getTorsoAngle(landmarks);
    // Unconscious / Slumped / Leaning significantly (35-60)
    // Over 60 is Sitting/Standing, Under 35 is likely Laying
    return torsoAngle >= 35 && torsoAngle < 60;
  }

  bool isSitting(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    if (landmarks.isEmpty) return false;
    final torsoAngle = getTorsoAngle(landmarks);
    if (torsoAngle < 60) return false;
    
    final legBend = getLegStraightness(landmarks);
    
    // Check for Sitting on Floor: Hip and Ankle are relatively close in height
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    bool onFloor = false;
    if (leftHip != null && leftAnkle != null) {
      final nose = landmarks[PoseLandmarkType.nose];
      final torsoHeight = (nose != null) ? (leftHip.y - nose.y).abs() : 100.0;
      // If hip-to-ankle vertical distance is small, it's floor level
      if ((leftHip.y - leftAnkle.y).abs() < torsoHeight * 0.5) {
        onFloor = true;
      }
    }

    // Chair sitting usually 90-120deg; 
    // Floor sitting can be cross-legged (10-40deg) or legs out (straight).
    // If onFloor is true, we allow almost ANY leg bend (tucked or straight)
    // as long as the person is upright and low to the ground.
    final maxBend = onFloor ? 175.0 : 135.0;
    final minBend = onFloor ? 0.0 : 45.0;
    
    return legBend >= minBend && legBend < maxBend;
  }

  bool isStanding(Map<PoseLandmarkType, PoseLandmark> landmarks, {double maxVel = 0, double height = 100}) {
     if (landmarks.isEmpty) return false;
     final torsoAngle = getTorsoAngle(landmarks);
     if (torsoAngle < 60) return false;
          final legBend = getLegStraightness(landmarks);
      // Straight legs in anatomical standard are near 180 degrees.
      // ALSO: Must not be moving significantly horizontally/vertically to be "Still"
      final isNotMoving = maxVel < (height * 0.15);
      
      // Standing check: Torso height must be significant (to differentiate from sitting on floor)
      // Usually torso is 40-50% of height. If total height is only slightly longer than torso, it's sitting.
      final leftHip = landmarks[PoseLandmarkType.leftHip];
      final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
      bool isTall = true;
      if (leftHip != null && leftAnkle != null) {
        final nose = landmarks[PoseLandmarkType.nose];
        final torsoY = (nose != null) ? (leftHip.y - nose.y).abs() : 0.0;
        final legY = (leftHip.y - leftAnkle.y).abs();
        // If legs aren't long enough vertically, it's not standing.
        // Increased threshold from 0.7 to 1.1 to be stricter (human legs are ~1.0x torso height)
        isTall = legY > (torsoY * 1.1); 
      }

      return legBend > 162 && isNotMoving && isTall; 
  }

  bool isWalking(TrackedPerson person) {
    final landmarks = person.smoothedLandmarks;
    if (landmarks.isEmpty) return false;
    final torsoAngle = getTorsoAngle(landmarks);
    
    // Allow more leaning for walking (down to 40 deg for fast walking)
    if (torsoAngle < 40) return false;
    
    final legBend = getLegStraightness(landmarks);
    
    // Check for active movement using physics engine
    double maxVel = 0;
    for (var physics in person.landmarkPhysics.values) {
      final speed = math.sqrt(physics.vx * physics.vx + physics.vy * physics.vy);
      if (speed > maxVel) maxVel = speed;
    }

    final height = _getBodyHeight(landmarks);
    // Lowered movement threshold: 0.12 body heights per second (catches slow walk)
    final isMoving = maxVel > (height * 0.12);

    // Leg is partially bent (walking motion) 
    // Relaxed upper bound to 170 to catch frames where one leg is straight
    return isMoving && legBend > 105 && legBend < 172;
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
        // Use vy (downward) for fall detection
        if (physics.vy > maxDownVel) maxDownVel = physics.vy;
        if (physics.acceleration > maxAcc) maxAcc = physics.acceleration;
      }
    }
    
    final torsoAngle = getTorsoAngle(person.smoothedLandmarks);
    // A fall usually involves leaning (torso angle < 60)
    final isLeaning = torsoAngle < 60;

    // Fall logic: High downward velocity + Leaning OR massive impact
    // Thresholds: 1.8x body height/sec for velocity (was 2.2), 10.0x for acceleration (was 12.0)
    return (maxDownVel > (height * 1.8) && isLeaning) || (maxAcc > (height * 10.0));
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

  /// AI Classification using the trained model
  String classifyActivity(TrackedPerson person) {
    if (person.smoothedLandmarks.isEmpty) return 'unknown';

    // Prepare features in the same order as training (0-32, x, y, z, visibility)
    final List<double> features = [];
    for (var type in PoseLandmarkType.values) {
      final landmark = person.smoothedLandmarks[type];
      if (landmark != null) {
        features.addAll([landmark.x, landmark.y, landmark.z, landmark.likelihood]);
      } else {
        features.addAll([0.0, 0.0, 0.0, 0.0]);
      }
    }

    if (features.length < 33 * 4) return 'unknown';

    final rawLabel = _classifier.predictLabel(features);
    final mappedLabel = _mapAILabel(rawLabel);

    // --- HEURISTIC HYBRID GUARDS ---
    // These guards use physical geometry to override AI if the prediction is physically improbable.
    final landmarks = person.smoothedLandmarks;
    final torsoAngle = getTorsoAngle(landmarks);
    final height = _getBodyHeight(landmarks);

    // Get max velocity for movement-aware standing check
    double maxVel = 0;
    for (var physics in person.landmarkPhysics.values) {
      final speed = math.sqrt(physics.vx * physics.vx + physics.vy * physics.vy);
      if (speed > maxVel) maxVel = speed;
    }

    // Define boolean flags for heuristics
    final bool currentlyFalling = isFalling(person);
    final bool currentlyLaying = isLaying(landmarks);

    // 1. Fall Sanity Guard: Don't allow 'falling' if the person is still mostly upright
    // or if the physics engine doesn't see a "fall-like" velocity/acceleration.
    if (mappedLabel == 'falling') {
      if (torsoAngle > 45 && !currentlyFalling) {
        // Person is upright and not accelerating down: likely just walking or standing
        return isWalking(person) ? 'walking' : 'standing';
      }
    }

    // 2. Priority Falling Check: Physics detected a fall
    if (currentlyFalling) {
      return 'falling';
    } 
    
    // 3. Sitting Guard: Priority check before standing for floor sitting support
    if (isSitting(landmarks)) return 'sitting';

    // 4. Strong Standing Guard: If legs are straight and torso is upright, it's standing.
    if (isStanding(landmarks, maxVel: maxVel, height: height)) return 'standing';

    // 5. Resting/Laying Guard: Critical for safety (overrides everything if flat)
    if (currentlyLaying) {
      // Priority Guard: If we were just falling or had high impact, stay as 'falling'
      // rather than switching to 'laying' immediately.
      final wasVeryFast = person.landmarkPhysics.values.any((ph) => ph.vy > (_getBodyHeight(landmarks) * 1.5));
      if (wasVeryFast) {
        return 'falling';
      } else {
        return 'laying';
      }
    }

    // 6. Walking Guard: If moving and legs are in motion
    if (isWalking(person)) return 'walking';

    return mappedLabel;
  }

  String _mapAILabel(String rawLabel) {
    final label = rawLabel.toLowerCase();
    if (label.contains('fall')) return 'falling';
    if (label.contains('sit') || label.contains('siting')) return 'sitting'; // Fuzzy and handle misspelling
    if (label.contains('lying')) return 'laying';
    if (label.contains('walk')) return 'walking';
    if (label.contains('stand')) return 'standing';
    if (label.contains('exercise') || label.contains('pushup') || label.contains('squat')) return 'exercise';
    if (label.contains('sit_to_stand') || label.contains('stand_to_sit')) return 'standing';
    return rawLabel;
  }

  /// Detects health issues like poor posture or sitting too long.
  /// Returns a health warning string if issues are found.
  String? detectHealthIssues(TrackedPerson person) {
    final activity = classifyActivity(person);
    final landmarks = person.smoothedLandmarks;
    
    if (activity == 'sitting') {
      // 1. Long Sitting Check
      if (person.sitStartTime != null) {
        final sitDuration = DateTime.now().difference(person.sitStartTime!);
        if (sitDuration.inMinutes > 30) {
          return 'นั่งนานเกินไป ควรลุกขยับร่างกาย';
        }
      }

      // 2. Slumping/Back Bending Check (หลังงอ)
      final nose = landmarks[PoseLandmarkType.nose];
      final lShoulder = landmarks[PoseLandmarkType.leftShoulder];
      final rShoulder = landmarks[PoseLandmarkType.rightShoulder];
      
      if (nose != null && lShoulder != null && rShoulder != null) {
        final midShoulderY = (lShoulder.y + rShoulder.y) / 2;
        final headToShoulderDist = midShoulderY - nose.y;
        
        // If head is getting close to shoulder level while sitting (slumping forward)
        // Or if torso angle is leaning too much
        final torsoAngle = getTorsoAngle(landmarks);
        
        if (headToShoulderDist < 30 || (torsoAngle > 30 && torsoAngle < 60)) {
           return 'ระวังหลังงอ ควรนั่งตัวตรงเพื่อสุขภาพ';
        }
      }

      // 3. Head Dropping (หัวตก)
       if (nose != null && lShoulder != null && rShoulder != null) {
          final midShoulderY = (lShoulder.y + rShoulder.y) / 2;
          if (nose.y > midShoulderY && !isLaying(landmarks)) {
            return 'ศีรษะตก ระวังงีบหลับในท่าที่ไม่เหมาะสม';
          }
       }
    } else {
      // Reset sit timer if they stand up or walk
      person.sitStartTime = null;
      if (activity == 'standing') {
        person.sitStartTime = null; // Stale reset
      }
    }
    
    return null;
  }
}
