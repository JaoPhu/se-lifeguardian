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

class _PoseDetectorViewState extends State<PoseDetectorView> {
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
  bool _isIdentificationMode = false;

  // Video Player state
  VideoPlayerController? _videoController;
  Timer? _analysisTimer;
  Timer? _simTimer;
  final math.Random _random = math.Random();

  // Snapshot state
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isCapturing = false;
  DateTime? _lastCaptureTime;

  @override
  void initState() {
    super.initState();
    if (widget.videoPath != null) {
      _initializeVideo();
    } else {
      _initializeCamera();
    }
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
    _analysisTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) return;
      
      setState(() {
        // Occasionally trigger a fall for the demo
        if (_random.nextDouble() < 0.1) {
          _isLaying = true;
          _isWalking = false;
          _statusText = "FALL DETECTED!";
        } else {
          _isLaying = false;
          _isWalking = _random.nextBool();
          _statusText = _isWalking ? "Walking / Active" : "Standing";
        }
        
        // Generate mock persons
        final persons = _generateMockPersons();
        _persons.clear();
        _persons.addAll(persons);
      });
    });
  }

  List<PersonPose> _generateMockPersons() {
    final width = _imageSize?.width ?? 480;
    final center = width / 2;
    
    // Person 1 (Teal)
    final p1Landmarks = {
      PoseLandmarkType.nose: PoseLandmark(type: PoseLandmarkType.nose, x: center - 50, y: 150, z: 0, likelihood: 0.9),
      PoseLandmarkType.leftShoulder: PoseLandmark(type: PoseLandmarkType.leftShoulder, x: center - 100, y: 200, z: 0, likelihood: 0.9),
      PoseLandmarkType.rightShoulder: PoseLandmark(type: PoseLandmarkType.rightShoulder, x: center, y: 200, z: 0, likelihood: 0.9),
      PoseLandmarkType.leftHip: PoseLandmark(type: PoseLandmarkType.leftHip, x: center - 80, y: 350, z: 0, likelihood: 0.9),
      PoseLandmarkType.rightHip: PoseLandmark(type: PoseLandmarkType.rightHip, x: center - 20, y: 350, z: 0, likelihood: 0.9),
      PoseLandmarkType.leftKnee: PoseLandmark(type: PoseLandmarkType.leftKnee, x: center - 80, y: 450, z: 0, likelihood: 0.9),
      PoseLandmarkType.rightKnee: PoseLandmark(type: PoseLandmarkType.rightKnee, x: center - 20, y: 450, z: 0, likelihood: 0.9),
      PoseLandmarkType.leftAnkle: PoseLandmark(type: PoseLandmarkType.leftAnkle, x: center - 80, y: 550, z: 0, likelihood: 0.9),
      PoseLandmarkType.rightAnkle: PoseLandmark(type: PoseLandmarkType.rightAnkle, x: center - 20, y: 550, z: 0, likelihood: 0.9),
    };

    // Person 2 (Orange) - further right
    final p2Landmarks = {
      PoseLandmarkType.nose: PoseLandmark(type: PoseLandmarkType.nose, x: center + 80, y: 180, z: 0, likelihood: 0.9),
      PoseLandmarkType.leftShoulder: PoseLandmark(type: PoseLandmarkType.leftShoulder, x: center + 40, y: 230, z: 0, likelihood: 0.9),
      PoseLandmarkType.rightShoulder: PoseLandmark(type: PoseLandmarkType.rightShoulder, x: center + 120, y: 230, z: 0, likelihood: 0.9),
      PoseLandmarkType.leftHip: PoseLandmark(type: PoseLandmarkType.leftHip, x: center + 50, y: 380, z: 0, likelihood: 0.9),
      PoseLandmarkType.rightHip: PoseLandmark(type: PoseLandmarkType.rightHip, x: center + 110, y: 380, z: 0, likelihood: 0.9),
      PoseLandmarkType.leftKnee: PoseLandmark(type: PoseLandmarkType.leftKnee, x: center + 50, y: 480, z: 0, likelihood: 0.9),
      PoseLandmarkType.rightKnee: PoseLandmark(type: PoseLandmarkType.rightKnee, x: center + 110, y: 480, z: 0, likelihood: 0.9),
      PoseLandmarkType.leftAnkle: PoseLandmark(type: PoseLandmarkType.leftAnkle, x: center + 50, y: 580, z: 0, likelihood: 0.9),
      PoseLandmarkType.rightAnkle: PoseLandmark(type: PoseLandmarkType.rightAnkle, x: center + 110, y: 580, z: 0, likelihood: 0.9),
    };

    return [
      PersonPose(landmarks: p1Landmarks, color: const Color(0xFF0D9488), isLaying: _isLaying, isWalking: _isWalking),
      PersonPose(landmarks: p2Landmarks, color: Colors.orange, isLaying: false, isWalking: false),
    ];
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
      setState(() => _statusText = "Camera Ready");
    } catch (e) {
      setState(() => _statusText = "Camera error: $e");
    }
  }

  void _processCameraImage(CameraImage image) async {
    if (_isDetecting) return;
    _isDetecting = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;

      final landmarks = await _poseService.detect(inputImage);
      
      final List<PersonPose> detectedPersons = [];
      const List<Color> personColors = [
        Color(0xFF0D9488), // Teal
        Colors.orange,
        Colors.blue,
      ];

      for (int i = 0; i < poses.length; i++) {
        final pose = poses[i];
        final personColor = personColors[i % personColors.length];
        
        // Single status for camera view for now
        final isLaying = _poseService.isLaying(pose.landmarks);
        final isWalking = _poseService.isWalking(pose.landmarks);

        detectedPersons.add(PersonPose(
          landmarks: pose.landmarks,
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
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _videoController?.dispose();
    _analysisTimer?.cancel();
    _poseService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoPath == null && (_cameraController == null || !_cameraController!.value.isInitialized)) {
      return Scaffold(
        body: Center(child: Text(_statusText)),
      );
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
                        if (widget.videoPath != null)
                          VideoPlayer(_videoController!)
                        else
                          _buildCameraPreview(size),
                          
                        if (_persons.isNotEmpty && _imageSize != null && _imageRotation != null)
                          CustomPaint(
                            painter: PosePainter(
                              _persons,
                              _imageSize!,
                              _imageRotation!,
                              _cameraController?.description.lensDirection ?? CameraLensDirection.back,
                            ),
                          ),
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
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
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
                SizedBox(
                  width: 140, height: 140,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    value: 0.7, // Fixed value for static representation or let it spin
                    color: const Color(0xFF0D9488),
                    backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                  ),
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

  Widget _buildSummaryScreen() {
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
}
