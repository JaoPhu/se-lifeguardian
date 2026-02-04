import 'dart:ui' as ui;
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart' hide PoseLandmark, PoseLandmarkType;
import 'package:permission_handler/permission_handler.dart';

import '../data/pose_models.dart';

import '../data/pose_detection_service.dart';
import '../data/health_status_provider.dart';
import 'pose_painter.dart';
import 'package:video_player/video_player.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:math' as math;

class PoseDetectorView extends ConsumerStatefulWidget {
  final String? videoPath;
  const PoseDetectorView({super.key, this.videoPath});
 
  @override
  ConsumerState<PoseDetectorView> createState() => _PoseDetectorViewState();
}

class _PoseDetectorViewState extends ConsumerState<PoseDetectorView> with TickerProviderStateMixin {
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
  final double _playbackSpeed = 1.0;
  DateTime _simTime = DateTime.now();
  bool _isAnalysisComplete = false;
  bool _isAnalyzing = false;
  bool _isPaused = false;
  bool _isIdentificationMode = false;
  final bool _showDiagnosticInsights = true;
  final double _healthScore = 98.0;
  String _diagnosticMessage = "Scanning Systemic Alignment...";

  // Video Player state
  VideoPlayerController? _videoController;
  Timer? _simTimer;
  bool _isAnalysisLoopRunning = false;
  final Map<int, Map<String, _OneEuroFilter>> _filters = {};

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
    _isAnalysisLoopRunning = false;
    _loadingController.dispose();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _videoController?.dispose();
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
        _isLoading = false; // Set to false here, pre-analysis will handle its own loading state
        _statusText = "Video Initialized.";
      });

      if (!mounted) return;

      // Start pre-analysis
      _runPreAnalysis();

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
    _isAnalysisLoopRunning = false;
    _simTimer?.cancel();
    _videoController?.pause();
    _isAnalysisLoopRunning = false;

    if (_persons.length > 1 && _selectedPersonIndex == null) {
      setState(() {
         _isIdentificationMode = true;
      });
    } else {
      setState(() {
        _selectedPersonIndex ??= (_persons.isNotEmpty ? 0 : null);
        _isAnalysisComplete = true;
        _statusText = "Analysis Complete";
      });
    }
  }

  Future<void> _runPreAnalysis() async {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }
    
    setState(() {
      _isAnalyzing = true;
      _isAnalysisComplete = false;
      _statusText = "Analyzing Scene...";
    });

    final duration = _videoController!.value.duration.inMilliseconds;
    // Fast Sampling: Sample every 1000ms for quick scene understanding (Faster than 500ms)
    final sampleInterval = duration > 10000 ? 1000 : 500;
    
    for (int ms = 0; ms < duration; ms += sampleInterval) {
      if (!mounted) {
        return;
      }
      if (!_isAnalyzing) {
        break;
      }

      await _videoController!.seekTo(Duration(milliseconds: ms));
      // Ultra-fast seek wait
      await Future.delayed(const Duration(milliseconds: 60));
      
      // Low-res capture for maximum speed during pre-analysis
      final uint8list = await _screenshotController.capture(pixelRatio: 0.4);
      if (uint8list != null) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/pre_frame.png');
        await file.writeAsBytes(uint8list, flush: true);
        
        final inputImage = InputImage.fromFile(file);
        final trackedPersons = await _poseService.detect(inputImage, uint8list);
        
        // Update local _persons list so we know how many people are being tracked
        if (mounted) {
          final personColors = [
            const Color(0xFF0D9488),
            Colors.orange, Colors.blue, Colors.purple,
            Colors.pink, Colors.amber, Colors.cyan, Colors.lime,
          ];
          
          setState(() {
            _persons.clear();
            _persons.addAll(trackedPersons.map((tp) => PersonPose(
              id: tp.id,
              landmarks: tp.smoothedLandmarks,
              color: personColors[tp.id % personColors.length],
              isLaying: _poseService.isLaying(tp.smoothedLandmarks),
              isWalking: _poseService.isWalking(tp.smoothedLandmarks),
            )));
          });
        }
      }
      
      // Analysis logic removed progress update for now as it's not used in UI
    }

    if (!mounted || !_isAnalyzing) { // Check if cancelled or unmounted
      await _videoController!.seekTo(Duration.zero);
      return;
    }

    // Final state set
    
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Seek back to start
    await _videoController!.seekTo(Duration.zero);
    
    if (_persons.length > 1) {
      setState(() {
        _isAnalyzing = false;
        _isIdentificationMode = true;
      });
    } else {
      setState(() {
        _isAnalyzing = false;
        _selectedPersonIndex = _persons.isNotEmpty ? 0 : null;
        _videoController!.play();
      });
      _startVideoAnalysisLoop();
      _startSimulation();
    }
  }

  void _startVideoAnalysisLoop() async {
    if (_isAnalysisLoopRunning) {
      return;
    }
    _isAnalysisLoopRunning = true;

    while (mounted && widget.videoPath != null && _isAnalysisLoopRunning) {
      // Check if video is finished
      if (_videoController != null && 
          _videoController!.value.isInitialized &&
          _videoController!.value.position >= _videoController!.value.duration) {
        _onAnalysisComplete();
        break;
      }

      if (_isPaused || _isDetecting || _videoController == null || !_videoController!.value.isPlaying) {
        await Future.delayed(const Duration(milliseconds: 100));
        continue;
      }

      _isDetecting = true;
      try {
        // Capture at lower resolution (0.7) for significantly faster processing
        final uint8list = await _screenshotController.capture(pixelRatio: 0.6);
        if (uint8list == null) {
          _isDetecting = false;
          await Future.delayed(const Duration(milliseconds: 5));
          continue;
        }

        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/frame.png');
        await file.writeAsBytes(uint8list, flush: true);

        
        final inputImage = InputImage.fromFile(file);
        final poses = await _poseService.detect(inputImage, uint8list);
        
        if (!mounted) {
          break;
        }

        final List<PersonPose> detectedPersons = [];
        final List<Color> personColors = [
          const Color(0xFF0D9488), // Teal
          Colors.orange,
          Colors.blue,
          Colors.purple,
          Colors.pink,
          Colors.amber,
          Colors.cyan,
          Colors.lime,
        ];

        for (var tp in poses) {
          final landmarks = _applyOneEuroFilter(tp.id, tp.smoothedLandmarks);
          
          final isLaying = _poseService.isLaying(landmarks);
          final isWalking = _poseService.isWalking(landmarks);
          
          detectedPersons.add(PersonPose(
            id: tp.id,
            landmarks: landmarks,
            color: personColors[tp.id % personColors.length],
            isLaying: isLaying,
            isWalking: isWalking,
          ));
        }

        if (mounted) {
          // Dynamically detect image size for perfect alignment
          final completer = Completer<ui.Image>();
          ui.decodeImageFromList(uint8list, (ui.Image img) {
            completer.complete(img);
          });
          final img = await completer.future;

          setState(() {
            _persons.clear();
            _persons.addAll(detectedPersons);
            _imageSize = Size(img.width.toDouble(), img.height.toDouble());
            _imageRotation = InputImageRotation.rotation0deg;
            _isDetecting = false;
            
          if (_persons.isNotEmpty) {
            final targetIndex = (_selectedPersonIndex ?? 0).clamp(0, _persons.length - 1);
            final p = _persons[targetIndex];
            
            String detectedActivity = 'standing';
            if (p.isLaying) {
              detectedActivity = 'falling';
            } else if (p.isWalking) {
              detectedActivity = 'walking';
            }
            
            _statusText = p.isLaying ? "FALL DETECTED!" : "Anatomical Sync: Active";
            _diagnosticMessage = p.isLaying ? "CRITICAL: Fall detected" : "Frame Sync: Optimal Flow";

            // State Transition & Snapshot Logic
            final healthState = ref.read(healthStatusProvider);
            if (healthState.currentActivity != detectedActivity) {
               // Capture snapshot asynchronously to not block UI
               _captureSnapshot().then((path) {
                 ref.read(healthStatusProvider.notifier).updateActivity(detectedActivity, snapshotPath: path);
               });
            }
          }
        });
        }
      } catch (e) {
        debugPrint("Video analysis error: $e");
        if (mounted) {
          _isDetecting = false;
        }
      }
      
      // Minimal delay to yield to the UI thread
      await Future.delayed(Duration.zero);
    }
    _isAnalysisLoopRunning = false;
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
    if (_isDetecting) {
      return;
    }
    _isDetecting = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        return;
      }

      final poses = await _poseService.detect(inputImage, Uint8List(0));
      
      final List<PersonPose> detectedPersons = [];
      final List<Color> personColors = [
        const Color(0xFF0D9488), // Teal
        Colors.orange,
        Colors.blue,
        Colors.purple,
        Colors.pink,
        Colors.amber,
        Colors.cyan,
        Colors.lime,
      ];

      for (var pose in poses) {
        final tp = pose;
        final landmarks = _applyOneEuroFilter(tp.id, tp.smoothedLandmarks);
        final personColor = personColors[tp.id % personColors.length];
        
        final isLaying = _poseService.isLaying(landmarks);
        final isWalking = _poseService.isWalking(landmarks);

        detectedPersons.add(PersonPose(
          id: tp.id,
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
            
            String detectedActivity = 'standing';
            if (mainPerson.isLaying) {
              detectedActivity = 'falling';
            } else if (mainPerson.isWalking) {
              detectedActivity = 'walking';
            }
            
            _isLaying = mainPerson.isLaying;
            _isWalking = mainPerson.isWalking;
            
            if (_isLaying) {
              _statusText = "Laying / Fallen!";
            } else if (_isWalking) {
              _statusText = "Walking / Active";
            } else {
              _statusText = "Standing";
            }

            // Report live activity
            final healthState = ref.read(healthStatusProvider);
            if (healthState.currentActivity != detectedActivity) {
               _captureSnapshot().then((path) {
                 ref.read(healthStatusProvider.notifier).updateActivity(detectedActivity, snapshotPath: path);
               });
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

  Future<String?> _captureSnapshot() async {
    // Prevent multiple captures for the same fall (debounce 30 seconds)
    if (_isCapturing) {
      return null;
    }
    if (widget.videoPath != null && 
        _lastCaptureTime != null && 
        DateTime.now().difference(_lastCaptureTime!).inSeconds < 15) { // Reduced to 15s for more responsiveness in events
      return null;
    }

    _isCapturing = true;
    _lastCaptureTime = DateTime.now();

    try {
      final image = await _screenshotController.capture();
      if (image != null) {
        final directory = await getTemporaryDirectory();
        final fileName = 'event_${DateTime.now().millisecondsSinceEpoch}.png';
        final imagePath = '${directory.path}/$fileName';
        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(image);
        
        // Save to gallery for user visibility if requested, but we need the path
        await Gal.putImage(imagePath);
        debugPrint("Snapshot saved: $imagePath");
        return imagePath;
      }
    } catch (e) {
      debugPrint("Error capturing snapshot: $e");
    } finally {
      _isCapturing = false;
    }
    return null;
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) {
      return null;
    }

    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;
    
    // Official ML Kit Coordinate Mapping (Matching iOS/Android Docs)
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else {
      var rotationOffset = 0;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationOffset = (sensorOrientation + 0) % 360;
      } else {
        rotationOffset = (sensorOrientation - 0 + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationOffset);
    }
    
    if (rotation == null) {
      return null;
    }

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) {
      return null;
    }

    if (image.planes.isEmpty) {
      return null;
    }

    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
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

    if (_isAnalyzing) {
      return _buildLoadingScreen();
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
                  // Unified Start/Stop Analysis Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isPaused ? const Color(0xFF0D9488) : const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 4,
                        shadowColor: (_isPaused ? const Color(0xFF0D9492) : const Color(0xFFD97706)).withValues(alpha: 0.4),
                      ),
                      child: Text(
                        _isPaused ? 'Start Analysis' : 'Stop Analysis', 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                      ),
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
        color: Color(0xFF0D9492),
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
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final size = constraints.biggest;
                            double scale = 1.0;
                            
                            if (widget.videoPath != null && _videoController != null && _videoController!.value.isInitialized) {
                              scale = size.aspectRatio / _videoController!.value.aspectRatio;
                            } else if (_cameraController != null && _cameraController!.value.isInitialized) {
                              scale = size.aspectRatio * _cameraController!.value.aspectRatio;
                            }
                            if (scale < 1) {
                              scale = 1 / scale;
                            }

                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                Transform.scale(
                                  scale: scale,
                                  child: Center(
                                    child: Screenshot(
                                      controller: _screenshotController,
                                      child: _buildCameraContent(size),
                                    ),
                                  ),
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
                        if (_showDiagnosticInsights && _isAnalysisComplete) _buildDiagnosticOverlay(),

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
                      painter: PulsePainter(color: const Color(0xFF0D9492).withValues(alpha: 0.8)),
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
                  color: isDark ? Colors.white54 : const Color(0xFF64748B).withValues(alpha: 0.8),
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

  String _getColorName(Color color) {
    if (color == const Color(0xFF0D9488)) {
      return "Teal";
    }
    if (color == Colors.orange) {
      return "Orange";
    }
    if (color == Colors.blue) {
      return "Blue";
    }
    if (color == Colors.purple) {
      return "Purple";
    }
    if (color == Colors.pink) {
      return "Pink";
    }
    if (color == Colors.amber) {
      return "Amber";
    }
    if (color == Colors.cyan) {
      return "Cyan";
    }
    if (color == Colors.lime) {
      return "Lime";
    }
    return "Custom Color";
  }

  Widget _buildSummaryScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: const Color(0xFF0D9492),
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
              
              // Person Selection List (Scrollable)
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: List.generate(_persons.length, (index) {
                      final person = _persons[index];
                      final colorName = _getColorName(person.color);
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: InkWell(
                            onTap: () {
                              final isAtEnd = _videoController != null && 
                                              _videoController!.value.isInitialized &&
                                              _videoController!.value.position >= _videoController!.value.duration;
                              
                              setState(() {
                                _selectedPersonIndex = index;
                                _isIdentificationMode = false;
                                if (isAtEnd) {
                                   _isAnalysisComplete = true;
                                   _statusText = "Analysis Complete";
                                } else {
                                   _videoController?.play();
                                }
                              });
                              
                              if (!isAtEnd) {
                                _startVideoAnalysisLoop();
                                _startSimulation();
                              }
                            },
                            borderRadius: BorderRadius.circular(24),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: person.color,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: person.color.withValues(alpha: 0.4),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        )
                                      ],
                                    ),
                                    child: const Icon(Icons.person, color: Colors.white),
                                  ),
                                  const SizedBox(width: 20),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "That's me! ($colorName)",
                                        style: const TextStyle(
                                          fontSize: 18, 
                                          fontWeight: FontWeight.bold, 
                                          color: Colors.white
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tracked as ID #${person.id}',
                                        style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7)),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              
              const Spacer(),
              
              TextButton(
                onPressed: () {
                  setState(() {
                    _isIdentificationMode = false;
                    _isAnalyzing = false; // Stop pre-analysis if it was running
                    _videoController?.play(); // Resume video if it was paused for identification
                    _startVideoAnalysisLoop(); // Start the main analysis loop
                  });
                },
                child: const Text('Cancel Analysis', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
            color: const Color(0xFF0D9492).withValues(alpha: 0.3),
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
                    color: const Color(0xFF0D9492).withValues(alpha: 0.1),
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
                backgroundColor: const Color(0xFF0D9492).withValues(alpha: 0.1),
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

  Map<PoseLandmarkType, PoseLandmark> _applyOneEuroFilter(int personId, Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final t = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final Map<PoseLandmarkType, PoseLandmark> filteredMap = {};
    
    _filters.putIfAbsent(personId, () => {});
    final personFilters = _filters[personId]!;

    landmarks.forEach((type, landmark) {
      final keyX = '${type.name}_x';
      final keyY = '${type.name}_y';
      final keyZ = '${type.name}_z';
      
      // High-speed responsiveness tuning (Beta 0.05 for faster reaction to movement)
      final fX = personFilters.putIfAbsent(keyX, () => _OneEuroFilter(minCutoff: 1.0, beta: 0.05));
      final fY = personFilters.putIfAbsent(keyY, () => _OneEuroFilter(minCutoff: 1.0, beta: 0.05));
      final fZ = personFilters.putIfAbsent(keyZ, () => _OneEuroFilter(minCutoff: 1.0, beta: 0.05));

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
  double? _tPrev;

  _OneEuroFilter({this.minCutoff = 1.0, this.beta = 0.0, this.dCutoff = 1.0});

  double filter(double x, double t) {
    if (_tPrev == null || _xPrev == null) {
      _tPrev = t;
      _xPrev = x;
      _dxPrev = 0;
      return x;
    }

    final double te = t - _tPrev!;
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
