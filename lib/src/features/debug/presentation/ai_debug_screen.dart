import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../pose_detection/presentation/pose_painter.dart';

class AIDebugScreen extends StatefulWidget {
  const AIDebugScreen({super.key});

  @override
  State<AIDebugScreen> createState() => _AIDebugScreenState();
}

class _AIDebugScreenState extends State<AIDebugScreen> {
  CameraController? _controller;
  PoseDetector? _poseDetector;
  bool _isDetecting = false;
  bool _canProcess = true;
  bool _isBusy = false;
  String _statusText = 'Initializing...';
  double _fallThreshold = 0.35;
  double _minConfidence = 0.5;
  List<Pose> _poses = [];
  CustomPaint? _customPaint;
  Size? _imageSize;
  InputImageRotation? _imageRotation;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializePoseDetector();
  }

  Future<void> _initializePoseDetector() async {
    final options = PoseDetectorOptions(mode: PoseDetectionMode.stream);
    _poseDetector = PoseDetector(options: options);
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _statusText = 'No cameras found');
        return;
      }

      final firstCamera = cameras.first;
      _controller = CameraController(
        firstCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup:
            Platform.isAndroid
                ? ImageFormatGroup.nv21
                : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();
      if (!mounted) return;
      setState(() => _statusText = 'Camera Ready');
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusText = 'Camera Error: $e');
    }
  }

  Future<void> _startImageStream() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      await _controller!.startImageStream(_processImage);
      setState(() => _statusText = 'Detecting...');
    } catch (e) {
      setState(() => _statusText = 'Error starting stream: $e');
    }
  }

  Future<void> _stopImageStream() async {
    if (_controller == null || !_controller!.value.isStreamingImages) return;

    try {
      await _controller!.stopImageStream();
      setState(() => _statusText = 'Paused');
    } catch (e) {
      setState(() => _statusText = 'Error stopping stream: $e');
    }
  }

  void _processImage(CameraImage image) async {
    if (!_canProcess || _isBusy || _poseDetector == null) return;
    _isBusy = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        _isBusy = false;
        return;
      }

      final poses = await _poseDetector!.processImage(inputImage);

      if (mounted) {
        setState(() {
          _poses = poses;
          _imageSize = inputImage.metadata?.size;
          _imageRotation = inputImage.metadata?.rotation;
          _checkFallStatus(poses);
        });
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
    } finally {
      _isBusy = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;

    final camera = _controller!.description;
    final sensorOrientation = camera.sensorOrientation;
    final orientations = {
      DeviceOrientation.portraitUp: 0,
      DeviceOrientation.landscapeLeft: 90,
      DeviceOrientation.portraitDown: 180,
      DeviceOrientation.landscapeRight: 270,
    };
    final rotationCompensation =
        (orientations[_controller!.value.deviceOrientation] ?? 0 + sensorOrientation) % 360;

    final rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    if (image.planes.isEmpty) return null;

    return InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  void _checkFallStatus(List<Pose> poses) {
    if (poses.isEmpty) {
      _statusText = 'No Pose Detected';
      return;
    }

    final pose = poses.first;
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    if (nose != null && leftAnkle != null && rightAnkle != null) {
      final ankleY = (leftAnkle.y + rightAnkle.y) / 2;
      final heightDiff = (nose.y - ankleY).abs();
      // Normalize heightDiff based on image height? For now just raw pixel check or ratio if possible.
      // Since we don't have normalized coordinates easily without calculation, we'll use a simplified logic.
      // In real app, we'd normalize by image height.
      // For debug, let's just show the raw diff.
      
      // Heuristic: If nose Y is close to ankle Y (small difference), horizontal -> Fall?
      // Assuming Y increases downwards.
      // Standing: Nose Y < Ankle Y. Diff is large.
      // Lying down: Nose Y ~ Ankle Y. Diff is small.
      
      // We need image height to normalize.
      final imageHeight = _controller!.value.previewSize?.height ?? 1.0;
      final normalizedDiff = heightDiff / imageHeight;

      if (normalizedDiff < _fallThreshold) {
        _statusText = 'FALL DETECTED! (${normalizedDiff.toStringAsFixed(2)})';
      } else {
        _statusText = 'Normal (${normalizedDiff.toStringAsFixed(2)})';
      }
    }
  }

  @override
  void dispose() {
    _canProcess = false;
    _poseDetector?.close();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text(
            _statusText,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          Center(
            child: CameraPreview(
              _controller!,
              child: _customPaint,
            ),
          ),

          // Pose Painter Overlay
          if (_poses.isNotEmpty && _isDetecting && _imageSize != null && _imageRotation != null)
            CustomPaint(
              painter: PosePainter(
                _poses.first.landmarks,
                _imageSize!,
                _imageRotation!,
                _controller!.description.lensDirection,
                isLaying: _statusText.contains('FALL'),
                isWalking: false,
              ),
              child: Container(),
            ),


          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(
                  top: 48, bottom: 16, left: 16, right: 16),
              color: Colors.black45,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.bug_report, color: Color(0xFF0D9488)),
                  const SizedBox(width: 8),
                  const Text(
                    'AI Debug Playground',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Status Overlay
          Positioned(
            top: 100,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF0D9488)),
              ),
              child: Text(
                'STATUS: $_statusText',
                style: const TextStyle(
                  color: Color(0xFF5EEAD4), // teal-300
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),

          // Controls Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isDetecting = !_isDetecting;
                            if (_isDetecting) {
                              _startImageStream();
                            } else {
                              _stopImageStream();
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isDetecting
                              ? Colors.red
                              : const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.local_activity, size: 18),
                        label: Text(_isDetecting ? 'STOP' : 'START'),
                      ),
                      IconButton(
                        onPressed: () {}, // Toggle Skeleton (Always on for now)
                        icon: const Icon(Icons.visibility,
                            color: Color(0xFF0D9488)),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSlider(
                      'Fall Threshold',
                      _fallThreshold,
                      (val) => setState(() => _fallThreshold = val),
                      0.1,
                      0.8),
                  const SizedBox(height: 16),
                  _buildSlider(
                      'Min Confidence',
                      _minConfidence,
                      (val) => setState(() => _minConfidence = val),
                      0.0,
                      1.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double value,
      ValueChanged<double> onChanged, double min, double max) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold)),
            Text(value.toStringAsFixed(2),
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF0D9488),
                    fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF0D9488),
            inactiveTrackColor: Colors.grey.shade300,
            thumbColor: const Color(0xFF0D9488),
            trackHeight: 2.0,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

