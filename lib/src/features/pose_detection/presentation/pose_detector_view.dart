import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart' hide PoseLandmark, PoseLandmarkType;
import 'package:flutter/foundation.dart';




import '../data/pose_detection_service.dart';
import '../data/health_status_provider.dart';
import 'pose_painter.dart';
import 'package:video_player/video_player.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../dashboard/data/camera_provider.dart' as cam_provider;
import '../../dashboard/domain/camera.dart' as cam_domain;
import '../../statistics/domain/simulation_event.dart';
import '../pose_providers.dart';


class PoseDetectorView extends ConsumerStatefulWidget {
  final String? videoPath;
  // If true, we show some debugging info or simulate events
  final bool isSimulation;
  final String? displayCameraName;
  final TimeOfDay? startTime;
  final DateTime? date;

  const PoseDetectorView({
    super.key, 
    this.videoPath, 
    this.isSimulation = false,
    this.displayCameraName,
    this.startTime,
    this.date,
  });
 
  @override
  ConsumerState<PoseDetectorView> createState() => _PoseDetectorViewState();
}

class _PoseDetectorViewState extends ConsumerState<PoseDetectorView> with TickerProviderStateMixin {
  final PoseDetectionService _poseService = PoseDetectionService();
  bool _isDetecting = false;
  
  // State for UI
  final List<PersonPose> _persons = [];
  int? _selectedPersonIndex;
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


  // Snapshot state
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isCapturing = false;
  DateTime? _lastCaptureTime;
  String? _registeredCameraId;
  String? _registeredCameraName;
  String? _firstFramePath;
  Uint8List? _lastCapturedFrameBytes;

  // Animation for loading
  late AnimationController _loadingController;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Initialize simulation time based on user input or default
    final baseDate = widget.date ?? DateTime(2025, 1, 1);
    final baseTime = widget.startTime ?? const TimeOfDay(hour: 10, minute: 0);
    _simTime = DateTime(
      baseDate.year, baseDate.month, baseDate.day, 
      baseTime.hour, baseTime.minute
    );

    // Initial sync of simulation clock to notifier
    // This is crucial so the very first event gets the correct start time!
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(healthStatusProvider.notifier).updateSimulationClock(_simTime);
    });

    if (widget.videoPath != null) {
      _initializeVideo();
    }
    
    _poseService.logger = ref.read(poseDataLoggerProvider);

    // Reset health monitoring state for new analysis session
    Future.microtask(() {
      ref.read(healthStatusProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _isAnalysisLoopRunning = false;
    _loadingController.dispose();
    _videoController?.dispose();
    _simTimer?.cancel();
    
    // Stop AI Data Collection if running
    if (ref.read(isRecordingPoseProvider)) {
      ref.read(poseDataLoggerProvider).stopRecording();
      ref.read(isRecordingPoseProvider.notifier).state = false;
    }
    
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
        _isLoading = false; 
        _statusText = "Video Initialized.";
      });

      if (!mounted) return;

      // Capture first frame for Thumbnail
      await Future.delayed(const Duration(milliseconds: 500)); // Wait for first frame to render
      final uint8list = await _screenshotController.capture(pixelRatio: 0.5);
      if (uint8list != null) {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.png';
        await File(path).writeAsBytes(uint8list);
        _firstFramePath = path;
      }

      // Register camera with name and thumbnail
      Future.microtask(() async {
          final notifier = ref.read(cam_provider.cameraProvider.notifier);
          // Removed notifier.clearCameras() to preserve existing boxes
          
          
          
          final camName = widget.displayCameraName ?? 'Demo Camera';
          final camera = await notifier.addCameraSafely(camName, config: cam_domain.CameraConfig(
             startTime: "08:00", 
             date: "2025-06-15",
             thumbnailUrl: _firstFramePath,
          ));
          if (mounted) {
            setState(() {
              _registeredCameraId = camera.id;
              _registeredCameraName = camera.name;
            });
          }
      });

      // Start pre-analysis
      _runPreAnalysis();

      _videoController!.addListener(() {
        if (!mounted) return;
        if (_videoController!.value.position >= _videoController!.value.duration) {
          _onAnalysisComplete();
        }
        // Sync UI (Slider progress) with video playback
        setState(() {});
      });

    } catch (e) {
      setState(() => _statusText = "Video error: $e");
    }
  }

  void _startSimulation() {
    _simTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_isPaused) return;
      
      setState(() {
        // One second equals 1 minute simulation
        _simTime = _simTime.add(const Duration(minutes: 1));
      });
      
      // Update the HealthStatusNotifier with the new simulation time
      // This drives the duration calculation for active events
      ref.read(healthStatusProvider.notifier).updateSimulationClock(_simTime);
    });
  }

  void _onAnalysisComplete() {
    if (_isAnalysisComplete) return;
    _isAnalysisLoopRunning = false;
    _simTimer?.cancel();
    _videoController?.pause();
    _isAnalysisLoopRunning = false;

    // Stop AI Data Collection if running
    if (ref.read(isRecordingPoseProvider)) {
      ref.read(poseDataLoggerProvider).stopRecording();
      ref.read(isRecordingPoseProvider.notifier).state = false;
      debugPrint("Auto-stopped AI Data Collection on Analysis Complete");
    }

    if (_persons.length > 1 && _selectedPersonIndex == null) {
      setState(() {
         _isIdentificationMode = true;
      });
    } else {
      // Force a final update to close the duration of the last activity
      // using the final simulation time
      if (_lastProcessedActivity != null) {
        ref.read(healthStatusProvider.notifier).updateActivity(
          _lastProcessedActivity!, // Re-confirm last activity
          cameraId: _registeredCameraId,
          customTime: _simTime, // Final time
          forceSync: true, // Force the last activity duration to be closed and synced
        );
      }

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
            const Color(0xFF0D9492),
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
              isFalling: _poseService.isFalling(tp),
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
        _lastCapturedFrameBytes = uint8list; // Cache for event snapshots

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
          const Color(0xFF0D9492), // Teal
          Colors.orange,
          Colors.blue,
          Colors.purple,
          Colors.pink,
          Colors.amber,
          Colors.cyan,
          Colors.lime,
        ];

        for (var tp in poses) {
          final landmarks = tp.smoothedLandmarks;
          
          final isLaying = _poseService.isLaying(landmarks);
          final isSitting = _poseService.isSitting(landmarks);
          final isSlouching = _poseService.isSlouching(landmarks);
          final isWalking = _poseService.isWalking(landmarks);
          final isFalling = _poseService.isFalling(tp);
          
          detectedPersons.add(PersonPose(
            id: tp.id,
            landmarks: landmarks,
            color: personColors[tp.id % personColors.length],
            isLaying: isLaying,
            isSitting: isSitting,
            isSlouching: isSlouching,
            isWalking: isWalking,
            isFalling: isFalling,
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
            if (p.isFalling) {
               detectedActivity = 'falling'; 
            } else if (p.isLaying) {
              detectedActivity = 'laying';
            } else if (p.isSitting) {
              detectedActivity = 'sitting';
            } else if (p.isSlouching) {
              detectedActivity = 'slouching';
            } else if (p.isWalking) {
              detectedActivity = 'walking';
            }
            
            if (p.isFalling) {
               _statusText = "IMPACT DETECTED!";
               _diagnosticMessage = "CRITICAL: Fall detected";
            } else if (p.isLaying) {
              _statusText = "Laying / Fallen";
              _diagnosticMessage = "Subject horizontal";
            } else if (p.isSlouching) {
              _statusText = "Unconscious / Slouching";
              _diagnosticMessage = "Leaning posture detected";
            } else if (p.isSitting) {
              _statusText = "Sitting";
              _diagnosticMessage = "Resting posture";
            } else if (p.isWalking) {
              _statusText = "Walking / Active";
              _diagnosticMessage = "Active movement";
            } else {
              _statusText = "Standing Still";
              _diagnosticMessage = "Upright position";
            }

            // State Transition & Snapshot Logic
            // Use buffered handler instead of direct check to prevent snapshot spam
            _handleActivityChange(detectedActivity);
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

  // UI Buffering State
  String? _lastDetectedActivity;
  int _consecutiveFrameCount = 0;
  // Require ~60 frames (approx 2 sec) of consistency to trigger UI update/snapshot
  // Falling is critical, requires less buffering (e.g. 5 frames just to filter noise)
  static const int _bufferThresholdNormal = 60; 
  static const int _bufferThresholdCritical = 5;
  
  // Track the last activity we successfully sent to the notifier to prevent loop
  String? _lastProcessedActivity;

  void _handleActivityChange(String detectedActivity) {
    if (_lastDetectedActivity == detectedActivity) {
      _consecutiveFrameCount++;
    } else {
      _lastDetectedActivity = detectedActivity;
      _consecutiveFrameCount = 0;
    }

    final isCritical = detectedActivity == 'falling' || detectedActivity == 'near_fall';
    final threshold = isCritical ? _bufferThresholdCritical : _bufferThresholdNormal;

    if (_consecutiveFrameCount >= threshold) {
      // Activity confirmed stable in UI
      final healthState = ref.read(healthStatusProvider);
      
      // Only trigger update if it's DIFFERENT from what we last processed locally
      // AND different from current global state (double check)
      if (_lastProcessedActivity != detectedActivity && healthState.currentActivity != detectedActivity) {
         
          // Mark as processed immediately to stop subsequent frames from triggering
          _lastProcessedActivity = detectedActivity;

          // We capture snapshot NOW.
          _captureSnapshot(force: true, isCritical: isCritical).then((path) {
            if (mounted) {
              ref.read(healthStatusProvider.notifier).updateActivity(
                detectedActivity, 
                snapshotPath: path,
                cameraId: _registeredCameraId,
                customTime: _simTime, // Use simulation time for duration calc
              );
            }
          });
          
          // Reset count
          _consecutiveFrameCount = 0; 
      }
    }
  }



  // Track type of last capture to allow 'Normal -> Critical' transitions quickly
  bool _lastCaptureWasCritical = false;

  Future<String?> _captureSnapshot({bool force = false, bool isCritical = false}) async {
    // Prevent multiple captures for the same fall (debounce 30 seconds)
    if (_isCapturing) {
      return null;
    }
    
    if (_lastCaptureTime != null) {
      final diffMs = DateTime.now().difference(_lastCaptureTime!).inMilliseconds;
      int cooldownMs = 2000; // Default 2s for normal events

      if (isCritical) {
        if (!_lastCaptureWasCritical) {
           // Normal -> Critical: Allow QUICK capture (e.g. Walking -> Falling)
           // Just enough to ensure file IO is clear (500ms)
           cooldownMs = 500; 
        } else {
           // Critical -> Critical: Prevent spamming the SAME fall (5s)
           cooldownMs = 5000;
        }
      } else {
         // Normal -> Normal: Keep standard 2s to avoid fidgeting spam
         cooldownMs = 2000;
      }

      if (diffMs < cooldownMs) return null;
    }

    _isCapturing = true;
    _lastCaptureTime = DateTime.now();
    _lastCaptureWasCritical = isCritical;

    try {
      // Use cached frame if available to avoid concurrency issues with ScreenshotController
      // and to ensure we capture exactly what the AI saw.
      final image = _lastCapturedFrameBytes ?? await _screenshotController.capture(pixelRatio: 1.5);
      
      if (image != null) {
        // Use ApplicationDocumentsDirectory so images persist across restarts
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'event_${DateTime.now().millisecondsSinceEpoch}.png';
        final imagePath = '${directory.path}/$fileName';
        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(image);
        
        // Save to gallery for user visibility if requested
        // Note: Gal might need external storage permission, handled by the plugin/OS
        try {
          await Gal.putImage(imagePath);
        } catch (e) {
          debugPrint("Gallery save failed (harmless): $e");
        }
        
        debugPrint("Snapshot saved: $imagePath");
        return imagePath;
      }
    } catch (e) {
      debugPrint("Error capturing snapshot: $e");
    } finally {
      if (mounted) {
         _isCapturing = false;
      }
    }
    return null;
  }



  @override
  Widget build(BuildContext context) {
    if (widget.videoPath == null) {
      return const Scaffold(
        body: Center(child: Text("No video path provided.")),
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
                        backgroundColor: _isPaused ? const Color(0xFF0D9492) : const Color(0xFFD97706),
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
                  const SizedBox(height: 16),

                  // AI Data Collection Section (Only visible in Debug Mode)
                  if (kDebugMode) _buildAIRecordingUI(),

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
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 20, bottom: 12),
            child: Text(
              widget.displayCameraName ?? 'Camera view : Desk',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D9492),
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
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.black,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final containerSize = constraints.biggest;
                    
                    double videoRatio = 1.0;
                    if (widget.videoPath != null && _videoController != null && _videoController!.value.isInitialized) {
                      videoRatio = _videoController!.value.aspectRatio;
                    }

                    return Center(
                      child: AspectRatio(
                        aspectRatio: videoRatio,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Screenshot(
                              controller: _screenshotController,
                              child: _buildCameraContent(containerSize),
                            ),
                            if (_persons.isNotEmpty && _imageSize != null && _imageRotation != null)
                              CustomPaint(
                                  painter: PosePainter(
                                    _persons,
                                    _imageSize!,
                                    _imageRotation!,
                                  ),
                                ),
                            if (_showDiagnosticInsights && _isAnalysisComplete) _buildDiagnosticOverlay(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
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
              onChanged: kDebugMode ? (val) {
                _videoController!.seekTo(Duration(milliseconds: val.toInt()));
              } : null,
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Speed : ${_playbackSpeed.toInt()}X',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
                        color: const Color(0xFF0D9492),
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
    if (color == const Color(0xFF0D9492)) {
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
    final healthState = ref.watch(healthStatusProvider);
    final events = healthState.events;
    
    // Count occurrences
    final int sittingCount = events.where((e) => e.type == 'sitting' || e.type == 'slouching').length;
    final int standingCount = events.where((e) => e.type == 'standing').length;
    final int walkingCount = events.where((e) => e.type == 'walking' || e.type == 'exercise').length;
    final int emergencyCount = events.where((e) => e.type == 'falling' || e.type == 'near_fall' || e.type == 'laying').length;

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
                    _buildSummaryRow('Sitting / Slouching', sittingCount.toString(), Colors.amber),
                    const Divider(color: Colors.white24),
                    _buildSummaryRow('Standing Still', standingCount.toString(), Colors.blue),
                    const Divider(color: Colors.white24),
                    _buildSummaryRow('Walking / Active', walkingCount.toString(), Colors.green),
                    const Divider(color: Colors.white24),
                    _buildSummaryRow('Fallen / Emergency', emergencyCount.toString(), Colors.red),
                  ],
                ),
              ),
              
              const Spacer(),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    // Capture snapshot for the dashboard thumbnail
                    // Force capture on finish to GUARANTEE a cover image
                    final snapshotPath = await _captureSnapshot(force: true);
                    
                    // Save results to dashboard
                    final healthState = ref.read(healthStatusProvider);
                    final events = List<SimulationEvent>.from(healthState.events);
                    
                    // If we have a snapshot but no events have one, add/update one
                    if (snapshotPath != null) {
                        if (events.isEmpty) {
                           events.add(SimulationEvent(
                             id: DateTime.now().millisecondsSinceEpoch.toString(),
                             type: 'analysis_complete',
                             timestamp: "${DateTime.now().hour}:${DateTime.now().minute}", 
                             date: DateTime.now().toString().split(' ')[0],
                             isCritical: false,
                             snapshotUrl: snapshotPath,
                             description: 'Demo Analysis Completed',
                           ));
                        } else {
                           // Update the most recent event with the snapshot if it doesn't have one
                           if (events.first.snapshotUrl == null) {
                             events[0] = events.first.copyWith(snapshotUrl: snapshotPath);
                           }
                        }
                    }

                    final demoCamera = cam_domain.Camera(
                      id: _registeredCameraId ?? 'demo-camera-${DateTime.now().millisecondsSinceEpoch}',
                      name: _registeredCameraName ?? widget.displayCameraName ?? 'Demo Camera', 
                      status: cam_domain.CameraStatus.online,
                      source: cam_domain.CameraSource.demo,
                      events: events,
                      config: cam_domain.CameraConfig(
                        date: DateTime.now().toString().split(' ')[0],
                        startTime: "08:00",
                        thumbnailUrl: _firstFramePath,
                      ),
                    );
                    
                    final notifier = ref.read(cam_provider.cameraProvider.notifier);
                    // Removed notifier.clearCameras() to respect disconnected box
                    notifier.addCamera(demoCamera);
                    
                    // Navigate to Dashboard (Overview)
                    context.go('/overview');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0D9492),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Finish & View Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
              color: Color(0xFF0D9492),
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
      backgroundColor: const Color(0xFF0D9492),
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
      return const Center(child: Text("Initializing video..."));
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
                  child: const Icon(Icons.psychology, color: Color(0xFF0D9492), size: 14),
                ),
                const SizedBox(width: 8),
                const Text(
                  'AI DIAGNOSIS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: Color(0xFF0D9492),
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
                    color: _healthScore < 70 ? Colors.red : const Color(0xFF0D9492),
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
                  _healthScore < 70 ? Colors.red : const Color(0xFF0D9492),
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

  final TextEditingController _labelController = TextEditingController(text: 'sitting_upright');

  Widget _buildAIRecordingUI() {
    final isRecording = ref.watch(isRecordingPoseProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isRecording ? Colors.red.withValues(alpha: 0.5) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology, 
                color: isRecording ? Colors.red : const Color(0xFF0D9492),
              ),
              const SizedBox(width: 8),
              const Text(
                'AI Data Collection (Phase 1)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              if (isRecording)
                const _PulseIcon(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Label the current posture to train the AI model.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _labelController,
            enabled: !isRecording,
            decoration: InputDecoration(
              labelText: 'Pose Label',
              hintText: 'e.g. sitting_slouching',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.label_outline),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final logger = ref.read(poseDataLoggerProvider);
                if (isRecording) {
                  logger.stopRecording();
                  ref.read(isRecordingPoseProvider.notifier).state = false;
                } else {
                  if (_labelController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a label first')),
                    );
                    return;
                  }
                  logger.startRecording(_labelController.text);
                  ref.read(isRecordingPoseProvider.notifier).state = true;
                }
              },
              icon: Icon(isRecording ? Icons.stop : Icons.fiber_manual_record),
              label: Text(isRecording ? 'Stop Recording' : 'Start Recording Frames'),
              style: OutlinedButton.styleFrom(
                foregroundColor: isRecording ? Colors.red : const Color(0xFF0D9492),
                side: BorderSide(color: isRecording ? Colors.red : const Color(0xFF0D9492)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseIcon extends StatefulWidget {
  const _PulseIcon();

  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: const Icon(Icons.circle, color: Colors.red, size: 12),
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
