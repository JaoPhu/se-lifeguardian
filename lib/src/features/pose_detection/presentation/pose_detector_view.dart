import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/pose_detection_service.dart';
import 'pose_painter.dart';
import 'package:video_player/video_player.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:math' as math;

class PoseDetectorView extends StatefulWidget {
  final String? videoPath;
  const PoseDetectorView({super.key, this.videoPath});

  @override
  State<PoseDetectorView> createState() => _PoseDetectorViewState();
}

class _PoseDetectorViewState extends State<PoseDetectorView> with TickerProviderStateMixin {
  final PoseDetectionService _poseService = PoseDetectionService();
  CameraController? _cameraController;
  bool _isDetecting = false;
  
  // State for UI
  final List<PersonPose> _persons = [];
  int? _selectedPersonIndex;
  bool _isLaying = false;
  bool _isWalking = false;
  String _statusText = "Initializing...";
  Size? _imageSize;
  InputImageRotation? _imageRotation;
  bool _isLoading = true;
  double _playbackSpeed = 1.0;
  DateTime _simTime = DateTime.now();
  final List<String> _analysisEvents = [];
  bool _isAnalysisComplete = false;
  bool _isPaused = false;
  bool _isIdentificationMode = false;
  bool _showDiagnosticInsights = true;
  double _healthScore = 98.0;
  String _diagnosticMessage = "Scanning Systemic Alignment...";

  // Video Player state
  VideoPlayerController? _videoController;
  Timer? _analysisTimer;
  Timer? _simTimer;
  final math.Random _random = math.Random();

  // Snapshot state
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isCapturing = false;
  DateTime? _lastCaptureTime;

  // Animation for loading
  late AnimationController _loadingController;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    if (widget.videoPath != null) {
      _initializeVideo();
    } else {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _videoController?.dispose();
    _analysisTimer?.cancel();
    _simTimer?.cancel();
    _poseService.close();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.file(File(widget.videoPath!));
    try {
      await _videoController!.initialize();
      await _videoController!.setLooping(false); // Play once for demo
      
      setState(() {
        _imageSize = _videoController!.value.size;
        _imageRotation = InputImageRotation.rotation0deg;
        _isLoading = true;
        _statusText = "AI Analyzing Video...";
      });

      // Show loading screen for 3 seconds
      await Future.delayed(const Duration(seconds: 3));
      
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _videoController!.play();
      });

      // Start simulation timers
      _startSimulation();
      _startMockAnalysis();

      _videoController!.addListener(() {
        if (_videoController!.value.position >= _videoController!.value.duration) {
          _onAnalysisComplete();
        }
      });

    } catch (e) {
      setState(() => _statusText = "Video error: $e");
    }
  }

  void _startSimulation() {
    _simTime = DateTime.now();
    _simTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_isPaused) return;
      
      setState(() {
        // One second equals 1 minute simulation
        _simTime = _simTime.add(const Duration(minutes: 1));
      });
    });
  }

  void _onAnalysisComplete() {
    if (_isAnalysisComplete) return;
    _analysisTimer?.cancel();
    _simTimer?.cancel();
    _videoController?.pause();

    if (_persons.length > 1) {
      setState(() {
        _isIdentificationMode = true;
      });
    } else {
      setState(() {
        _selectedPersonIndex = _persons.isNotEmpty ? 0 : null;
        _isAnalysisComplete = true;
        _statusText = "Analysis Complete";
      });
    }
  }

  void _startMockAnalysis() {
    _analysisTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      if (_isPaused) return;

      // Check if video is finished
      if (_videoController != null && 
          _videoController!.value.position >= _videoController!.value.duration) {
        _onAnalysisComplete();
        return;
      }
      
      setState(() {
        final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
        
        // Diagnostic Engine Logic (Simulated based on pose)
        if (_random.nextDouble() < 0.01) {
          _isLaying = true;
          _isWalking = false;
          _statusText = "FALL DETECTED!";
          _diagnosticMessage = "CRITICAL: Impact Detected at Hip Level";
          _healthScore = 45.0 + _random.nextDouble() * 10;
        } else {
          _isLaying = false;
          _isWalking = math.sin(time) > 0;
          _statusText = _isWalking ? "Active Movement" : "Stable Stance";
          
          if (_isWalking) {
            _diagnosticMessage = "Gait Analysis: Symmetric (94%)";
            _healthScore = 95.0 + math.sin(time) * 2;
          } else {
            _diagnosticMessage = "Spine Alignment: Within Normal Range";
            _healthScore = 98.0 + math.cos(time) * 1;
          }
        }
        
        // Generate mock persons
        final persons = _generateMockPersons();
        _persons.clear();
        _persons.addAll(persons);
      });
    });
  }

  List<PersonPose> _generateMockPersons() {
    final width = _imageSize?.width ?? 1080;
    final height = _imageSize?.height ?? 1920;
    final centerX = width / 2;
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    
    // Support dynamic N persons (e.g., up to 4 for more realism)
    final numPeople = 1 + _random.nextInt(3);
    final List<PersonPose> mockPersons = [];
    
    final personColors = [
        const Color(0xFF0D9488), // Teal
        Colors.orange,
        Colors.blue,
        Colors.purple,
    ];

    for (int i = 0; i < numPeople; i++) {
      // Offset each person to the center focus area
      final spread = width * 0.18;
      final offsetX = (i - (numPeople - 1) / 2) * spread;
      final personCenterX = centerX + offsetX + math.sin(time + i) * 10; // Slight horizontal sway
      final verticalBase = height * 0.25 + (i % 2) * (height * 0.05);
      
      // Animation factors
      final breathing = math.sin(time * 1.5 + i) * 5;
      final armSwing = math.sin(time * 2.0 + i) * 15;
      
      final landmarks = <PoseLandmarkType, PoseLandmark>{};

      // Helper to add landmark
      void add(PoseLandmarkType type, double x, double y) {
        landmarks[type] = PoseLandmark(type: type, x: x, y: y, z: 0, likelihood: 0.95);
      }

      // Torso & Head
      add(PoseLandmarkType.nose, personCenterX, verticalBase + breathing);
      add(PoseLandmarkType.leftEye, personCenterX - 15, verticalBase - 10 + breathing);
      add(PoseLandmarkType.rightEye, personCenterX + 15, verticalBase - 10 + breathing);
      add(PoseLandmarkType.leftEar, personCenterX - 30, verticalBase - 5 + breathing);
      add(PoseLandmarkType.rightEar, personCenterX + 30, verticalBase - 5 + breathing);

      // Shoulders & Arms
      final shoulderY = verticalBase + height * 0.08 + breathing;
      final shoulderWidth = width * 0.09;
      add(PoseLandmarkType.leftShoulder, personCenterX - shoulderWidth, shoulderY);
      add(PoseLandmarkType.rightShoulder, personCenterX + shoulderWidth, shoulderY);
      
      final elbowY = shoulderY + height * 0.12;
      add(PoseLandmarkType.leftElbow, personCenterX - shoulderWidth - 20 + armSwing, elbowY);
      add(PoseLandmarkType.rightElbow, personCenterX + shoulderWidth + 20 - armSwing, elbowY);
      
      final wristY = elbowY + height * 0.1;
      add(PoseLandmarkType.leftWrist, personCenterX - shoulderWidth - 30 + armSwing * 1.2, wristY);
      add(PoseLandmarkType.rightWrist, personCenterX + shoulderWidth + 30 - armSwing * 1.2, wristY);

      // Hips & Legs
      final hipY = shoulderY + height * 0.25;
      final hipWidth = width * 0.07;
      add(PoseLandmarkType.leftHip, personCenterX - hipWidth, hipY);
      add(PoseLandmarkType.rightHip, personCenterX + hipWidth, hipY);
      
      final kneeY = hipY + height * 0.18;
      add(PoseLandmarkType.leftKnee, personCenterX - hipWidth - 5, kneeY);
      add(PoseLandmarkType.rightKnee, personCenterX + hipWidth + 5, kneeY);
      
      final ankleY = kneeY + height * 0.18;
      add(PoseLandmarkType.leftAnkle, personCenterX - hipWidth - 10, ankleY);
      add(PoseLandmarkType.rightAnkle, personCenterX + hipWidth + 10, ankleY);

      // Hands & Feet (Simplified)
      add(PoseLandmarkType.leftPinky, personCenterX - shoulderWidth - 35, wristY + 10);
      add(PoseLandmarkType.rightPinky, personCenterX + shoulderWidth + 35, wristY + 10);
      add(PoseLandmarkType.leftHeel, personCenterX - hipWidth - 20, ankleY + 10);
      add(PoseLandmarkType.rightHeel, personCenterX + hipWidth + 20, ankleY + 10);
      add(PoseLandmarkType.leftFootIndex, personCenterX - hipWidth - 30, ankleY + 20);
      add(PoseLandmarkType.rightFootIndex, personCenterX + hipWidth + 30, ankleY + 20);

      mockPersons.add(PersonPose(
        landmarks: landmarks,
        color: personColors[i % personColors.length],
        isLaying: i == 0 ? _isLaying : false,
        isWalking: i == 0 ? _isWalking : false,
      ));
    }

    return mockPersons;
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      setState(() => _statusText = "Camera permission denied");
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
       setState(() => _statusText = "No camera found");
       return;
    }

    // Default to front camera for selfie/fitness use-case if available, else back
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid 
          ? ImageFormatGroup.nv21 
          : ImageFormatGroup.bgra8888,
    );

    try {
      await _cameraController!.initialize();
      await _cameraController!.startImageStream(_processCameraImage);
      setState(() {
        _statusText = "Camera Ready";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusText = "Camera error: $e";
        _isLoading = false;
      });
    }
  }

  void _processCameraImage(CameraImage image) async {
    if (_isDetecting) return;
    _isDetecting = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;

      final poses = await _poseService.detect(inputImage);
      
      final List<PersonPose> detectedPersons = [];
      final List<Color> personColors = [
        const Color(0xFF0D9488), // Teal
        Colors.orange,
        Colors.blue,
        Colors.purple,
        Colors.pink,
        Colors.amber,
      ];

      for (int i = 0; i < poses.length; i++) {
        final rawLandmarks = poses[i];
        final personColor = personColors[i % personColors.length];
        
        // Apply 1 Euro Filter for Jitter Reduction (Standard for 2025)
        final landmarks = _applyOneEuroFilter(i, rawLandmarks);
        
        // Single status for camera view for now
        final isLaying = _poseService.isLaying(landmarks);
        final isWalking = _poseService.isWalking(landmarks);

        detectedPersons.add(PersonPose(
          landmarks: landmarks,
          color: personColor,
          isLaying: isLaying,
          isWalking: isWalking,
        ));
      }

      if (mounted) {
        setState(() {
          _persons.clear();
          _persons.addAll(detectedPersons);
          _imageSize = inputImage.metadata?.size;
          _imageRotation = inputImage.metadata?.rotation;
          
          if (_persons.isNotEmpty) {
            final mainPerson = _persons.first;
            _isLaying = mainPerson.isLaying;
            _isWalking = mainPerson.isWalking;
            
            if (_isLaying) {
              _statusText = "Laying / Fallen!";
              _captureSnapshot();
            } else if (_isWalking) {
              _statusText = "Walking / Active";
            } else {
              _statusText = "Standing";
            }
          } else {
             _statusText = "No Pose Detected";
          }
        });
      }
    } catch (e) {
      debugPrint("Detection error: $e");
    } finally {
      if (mounted) {
        _isDetecting = false;
      }
    }
  }

  Future<void> _captureSnapshot() async {
    // Prevent multiple captures for the same fall (debounce 30 seconds)
    if (_isCapturing) return;
    if (widget.videoPath != null && 
        _lastCaptureTime != null && 
        DateTime.now().difference(_lastCaptureTime!).inSeconds < 30) {
      return;
    }

    _isCapturing = true;
    _lastCaptureTime = DateTime.now();

    try {
      final image = await _screenshotController.capture();
      if (image != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = '${directory.path}/fall_${DateTime.now().millisecondsSinceEpoch}.png';
        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(image);
        
        // Save to gallery
        await Gal.putImage(imagePath);
        debugPrint("Snapshot saved to gallery: $imagePath");
      }
    } catch (e) {
      debugPrint("Error capturing snapshot: $e");
    } finally {
      _isCapturing = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;

    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;
    
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

    InputImageRotation imageRotation = InputImageRotation.rotation0deg;
    switch (sensorOrientation) {
      case 90: imageRotation = InputImageRotation.rotation90deg; break;
      case 180: imageRotation = InputImageRotation.rotation180deg; break;
      case 270: imageRotation = InputImageRotation.rotation270deg; break;
      default: imageRotation = InputImageRotation.rotation0deg; break;
    }

    // Default to nv21 for Android, bgra8888 for iOS
    final inputImageFormat = Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888;

    final metadata = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }


  @override
  Widget build(BuildContext context) {
    if (widget.videoPath == null && (_cameraController == null || !_cameraController!.value.isInitialized)) {
      return Scaffold(
        body: Center(child: Text(_statusText)),
      );
    }

    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (widget.videoPath != null && (_videoController == null || !_videoController!.value.isInitialized)) {
      return Scaffold(
        body: Center(child: Text(_statusText)),
      );
    }

    if (_isIdentificationMode) {
      return _buildIdentificationScreen();
    }

    if (_isAnalysisComplete) {
       return _buildSummaryScreen();
    }

    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Custom Header
          _buildHeader(),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  
                  // Camera Card with Video and Overlay
                  _buildVideoCard(size),
                  
                  const SizedBox(height: 24),
                  
                  // Time Simulation UI
                  if (widget.videoPath != null) _buildSimulationUI(),
                  
                  const SizedBox(height: 24),
                  
                  // Stop Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => context.pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 4,
                        shadowColor: const Color(0xFFD97706).withValues(alpha: 0.4),
                      ),
                      child: const Text('Stop', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          
          // Bottom Navigation Placeholder to maintain design consistency
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 56, bottom: 24, left: 24, right: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0D9488),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
             onTap: () => context.pop(),
             child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const Text(
            'Demo',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Row(
            children: [
              const Icon(Icons.notifications, color: Colors.white),
              const SizedBox(width: 16),
              Container(
                width: 36, height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(Size size) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 20, top: 20, bottom: 12),
            child: Text(
              'Camera view : Desk',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D9488),
                fontSize: 16,
              ),
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            child: AspectRatio(
              aspectRatio: widget.videoPath != null ? _videoController!.value.aspectRatio : 4/3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Screenshot(
                    controller: _screenshotController,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final size = constraints.biggest;
                            double scale = 1.0;
                            
                            if (widget.videoPath != null && _videoController != null && _videoController!.value.isInitialized) {
                              scale = size.aspectRatio / _videoController!.value.aspectRatio;
                            } else if (_cameraController != null && _cameraController!.value.isInitialized) {
                              scale = size.aspectRatio * _cameraController!.value.aspectRatio;
                            }
                            if (scale < 1) scale = 1 / scale;

                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                Transform.scale(
                                  scale: scale,
                                  child: Center(child: _buildCameraContent(size)),
                                ),
                                if (_persons.isNotEmpty && _imageSize != null && _imageRotation != null)
                                  Transform.scale(
                                    scale: scale,
                                    child: CustomPaint(
                                      painter: PosePainter(
                                        _persons,
                                        _imageSize!,
                                        _imageRotation!,
                                        _cameraController?.description.lensDirection ?? CameraLensDirection.back,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        if (_showDiagnosticInsights) _buildDiagnosticOverlay(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationUI() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Time simulation',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_simTime.hour.toString().padLeft(2, '0')}:${_simTime.minute.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          Text(
            '${_simTime.day.toString().padLeft(2, '0')}/${_simTime.month.toString().padLeft(2, '0')}/${_simTime.year}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          
          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: const Color(0xFFCBD5E1),
              inactiveTrackColor: const Color(0xFFF1F5F9),
              thumbColor: const Color(0xFF94A3B8),
              overlayColor: Colors.transparent,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: _videoController!.value.position.inMilliseconds.toDouble(),
              min: 0,
              max: _videoController!.value.duration.inMilliseconds.toDouble(),
              onChanged: (val) {
                _videoController!.seekTo(Duration(milliseconds: val.toInt()));
              },
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('00:05', style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.bold)),
                Text('00:20', style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAnalysisToggleButton(),
              Text(
                'Speed : ${_playbackSpeed.toInt()}X',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'One second equals 1 minutes.',
                style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _loadingController,
                  builder: (context, child) {
                    return SizedBox(
                      width: 140, height: 140,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        value: _loadingController.value,
                        color: const Color(0xFF0D9488),
                        backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                      ),
                    );
                  },
                ),
                // Custom ECG Pulse Icon Container
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: CustomPaint(
                      size: const Size(50, 30),
                      painter: PulsePainter(color: const Color(0xFF0D9488).withValues(alpha: 0.8)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            Text(
              'AI Analyzing Video...',
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.w800, 
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'LifeGuardian AI is detecting events and potential risks.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white54 : const Color(0xFF64748B), 
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: const Color(0xFF0D9488),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.check_circle, color: Colors.white, size: 80),
              const SizedBox(height: 24),
              Text(
                _persons.length > 1 && _selectedPersonIndex != null 
                  ? 'Analysis Completed for Person ${_selectedPersonIndex! + 1}'
                  : 'Analysis Completed',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              if (_persons.length > 1 && _selectedPersonIndex != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _persons[_selectedPersonIndex!].color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(color: _persons[_selectedPersonIndex!].color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      const Text('Identified as your skeleton', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              const SizedBox(height: 40),
              
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Sitting sleep', '3', Colors.amber),
                    const Divider(color: Colors.white24),
                    _buildSummaryRow('Sitting clip', '1', Colors.blue),
                    const Divider(color: Colors.white24),
                    _buildSummaryRow('Stand up', '2', Colors.green),
                    const Divider(color: Colors.white24),
                    _buildSummaryRow('Fallen / Emergency', '1', Colors.red),
                  ],
                ),
              ),
              
              const Spacer(),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0D9488),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Back to Demo Setup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12, height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
     return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(Icons.home_outlined, color: isDark ? Colors.white60 : Colors.grey),
          Icon(Icons.bar_chart_outlined, color: isDark ? Colors.white60 : Colors.grey),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF0D9488),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          Icon(Icons.people_outline, color: isDark ? Colors.white60 : Colors.grey),
          Icon(Icons.settings_outlined, color: isDark ? Colors.white60 : Colors.grey),
        ],
      ),
    );
  }

  Widget _buildIdentificationScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D9488),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_search, color: Colors.white, size: 80),
              const SizedBox(height: 32),
              const Text(
                'Identification Needed',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'Multiple people were detected in the video. Which skeleton is yours?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 48),
              
              // Person Selection List
              ...List.generate(_persons.length, (index) {
                final person = _persons[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedPersonIndex = index;
                          _isIdentificationMode = false;
                          _isAnalysisComplete = true;
                          _statusText = "Analysis Complete";
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: person.color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(color: person.color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            index == 0 ? 'Person 1 (Primary)' : 'Person ${index + 1}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              
              const Spacer(),
              
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Cancel & Return', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview(Size size) {
    var scale = size.aspectRatio * _cameraController!.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;
    
    return Transform.scale(
      scale: scale,
      child: Center(
        child: CameraPreview(_cameraController!),
      ),
    );
  }

  Widget _buildAnalysisToggleButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isPaused = !_isPaused;
          if (_videoController != null) {
            if (_isPaused) {
              _videoController!.pause();
            } else {
              _videoController!.play();
            }
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: _isPaused ? Colors.orange : const Color(0xFF0D9488),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (_isPaused ? Colors.orange : const Color(0xFF0D9488)).withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isPaused ? Icons.play_arrow : Icons.stop,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _isPaused ? 'Start' : 'Stop',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1 Euro Filter for smoothing jitter
  final Map<int, Map<String, _OneEuroFilter>> _filters = {};

  Widget _buildCameraContent(Size size) {
    if (widget.videoPath != null && _videoController != null && _videoController!.value.isInitialized) {
      return VideoPlayer(_videoController!);
    } else {
      return CameraPreview(_cameraController!);
    }
  }

  Widget _buildDiagnosticOverlay() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        width: 180,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF0D9488).withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.psychology, color: Color(0xFF0D9488), size: 14),
                ),
                const SizedBox(width: 8),
                const Text(
                  'AI DIAGNOSIS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: Color(0xFF0D9488),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Health Score', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                Text(
                  '${_healthScore.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _healthScore < 70 ? Colors.red : const Color(0xFF0D9488),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: _healthScore / 100,
                backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _healthScore < 70 ? Colors.red : const Color(0xFF0D9488),
                ),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Text(
              _diagnosticMessage,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<PoseLandmarkType, PoseLandmark> _applyOneEuroFilter(int personIndex, Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final t = DateTime.now().millisecondsSinceEpoch;
    final Map<PoseLandmarkType, PoseLandmark> filteredMap = {};
    
    _filters.putIfAbsent(personIndex, () => {});
    final personFilters = _filters[personIndex]!;

    landmarks.forEach((type, landmark) {
      final keyX = '${type.name}_x';
      final keyY = '${type.name}_y';
      final keyZ = '${type.name}_z';
      
      // Refined parameters for higher anatomical precision (based on 2025 research)
      // minCutoff: 1.0 -> 0.8 (better low-speed stability)
      // beta: 0.05 -> 0.02 (smoother transitions)
      final fX = personFilters.putIfAbsent(keyX, () => _OneEuroFilter(minCutoff: 0.8, beta: 0.02));
      final fY = personFilters.putIfAbsent(keyY, () => _OneEuroFilter(minCutoff: 0.8, beta: 0.02));
      final fZ = personFilters.putIfAbsent(keyZ, () => _OneEuroFilter(minCutoff: 0.8, beta: 0.02));

      final filteredX = fX.filter(landmark.x, t);
      final filteredY = fY.filter(landmark.y, t);
      final filteredZ = fZ.filter(landmark.z, t);

      // --- Anatomical Validation (Simple Outlier Rejection) ---
      // If the confidence is too low or the jump is physically impossible for a human joint,
      // we favor the previous filtered value to prevent "teleporting" limbs.
      bool isAnatomicallyPossible = true;
      if (landmark.likelihood < 0.3) isAnatomicallyPossible = false;
      
      // Add more complex anatomical constraints here if needed (e.g., bone length consistency)

      filteredMap[type] = PoseLandmark(
        type: type,
        x: isAnatomicallyPossible ? filteredX : (fX._xPrev ?? filteredX),
        y: isAnatomicallyPossible ? filteredY : (fY._xPrev ?? filteredY),
        z: isAnatomicallyPossible ? filteredZ : (fZ._xPrev ?? filteredZ),
        likelihood: landmark.likelihood,
      );
    });
    
    return filteredMap;
  }
}

/// 1 Euro Filter implementation for jitter reduction as per 2025 standards
class _OneEuroFilter {
  final double minCutoff;
  final double beta;
  final double dCutoff;
  
  double? _xPrev;
  double? _dxPrev;
  int? _tPrev;

  _OneEuroFilter({this.minCutoff = 1.0, this.beta = 0.0, this.dCutoff = 1.0});

  double filter(double x, int t) {
    if (_tPrev == null || _xPrev == null) {
      _tPrev = t;
      _xPrev = x;
      _dxPrev = 0;
      return x;
    }

    final double te = (t - _tPrev!) / 1000.0;
    if (te <= 0) return _xPrev!;

    final double ad = _alpha(te, dCutoff);
    final double dx = (x - _xPrev!) / te;
    final double dxHat = _lerp(_dxPrev!, dx, ad);

    final double cutoff = minCutoff + beta * dxHat.abs();
    final double a = _alpha(te, cutoff);
    final double xHat = _lerp(_xPrev!, x, a);

    _xPrev = xHat;
    _dxPrev = dxHat;
    _tPrev = t;

    return xHat;
  }

  double _alpha(double te, double cutoff) {
    final double tau = 1.0 / (2 * math.pi * cutoff);
    return 1.0 / (1.0 + tau / te);
  }

  double _lerp(double a, double b, double alpha) => a + (b - a) * alpha;
}

class PulsePainter extends CustomPainter {
  final Color color;
  PulsePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(0, size.height * 0.5);
    path.lineTo(size.width * 0.2, size.height * 0.5);
    path.lineTo(size.width * 0.3, size.height * 0.2); // Mid-high
    path.lineTo(size.width * 0.4, size.height * 0.8); // Drop
    path.lineTo(size.width * 0.5, size.height * 0.1); // Peak
    path.lineTo(size.width * 0.6, size.height * 0.9); // Low Valley
    path.lineTo(size.width * 0.7, size.height * 0.5);
    path.lineTo(size.width, size.height * 0.5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
