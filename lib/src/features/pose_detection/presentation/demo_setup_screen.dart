import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VideoPreview extends StatefulWidget {
  final String videoPath;
  const VideoPreview({super.key, required this.videoPath});

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(VideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) {
      _initialize();
    }
  }

  Future<void> _initialize() async {
    await _controller?.dispose();
    if (kIsWeb) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoPath));
    } else {
      _controller = VideoPlayerController.file(File(widget.videoPath));
    }
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)));
    }
    return VideoPlayer(_controller!);
  }
}

class DemoSetupScreen extends ConsumerStatefulWidget {
  const DemoSetupScreen({super.key});

  @override
  ConsumerState<DemoSetupScreen> createState() => _DemoSetupScreenState();
}

class _DemoSetupScreenState extends ConsumerState<DemoSetupScreen> {
  final _cameraNameController = TextEditingController(text: 'Camera view : Desk');
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  double _speed = 1.0;
  DateTime _date = DateTime.now();
  String? _videoPath;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _videoPath = video.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // final user = ref.watch(userProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header
         Container(
            padding: const EdgeInsets.only(top: 56, bottom: 16, left: 16, right: 24),
            decoration: const BoxDecoration(
              color: Color(0xFF0D9488),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  onPressed: () => context.pop(),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Demo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Video Upload Card
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12, top: 8, bottom: 4),
                        child: Text(
                          'Video',
                          style: TextStyle(
                            fontSize: 14, 
                            fontWeight: FontWeight.bold, 
                            color: const Color(0xFF0D9488).withValues(alpha: 0.8)
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _pickVideo,
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white12 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _videoPath != null 
                            ? VideoPreview(videoPath: _videoPath!)
                            : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: const BoxDecoration(
                                    color: Colors.black12,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add, color: Colors.white),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Upload video',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Camera Name
                _buildLabel('Name Camera'),
                TextField(
                  controller: _cameraNameController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? Colors.white10 : Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF0D9488)),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Grid for Start Time, Speed, Date
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Start time'),
                          _buildButton(
                            _startTime.format(context), 
                            Icons.access_time, 
                            () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _startTime,
                              );
                              if (picked != null) {
                                setState(() => _startTime = picked);
                              }
                            }
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Speed'),
                           _buildButton(
                             '${_speed.toString().replaceAll(RegExp(r"([.]*0)(?!.*\d)"), "")}x', 
                             Icons.speed, 
                             () {
                               // Simple cycle through speeds
                               setState(() {
                                 if (_speed == 1.0) {
                                   _speed = 2.0;
                                 } else if (_speed == 2.0) {
                                   _speed = 4.0;
                                 } else if (_speed == 4.0) {
                                   _speed = 0.5;
                                 } else {
                                   _speed = 1.0;
                                 }
                               });
                             }
                           ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Date'),
                          _buildButton(
                            '${_date.day}/${_date.month}/${_date.year + 543}', 
                            Icons.calendar_today, 
                            () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _date,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => _date = picked);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Play Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _videoPath != null ? () {
                      context.push('/analysis', extra: {
                        'videoPath': _videoPath,
                        'cameraName': _cameraNameController.text,
                        'startTime': _startTime, // Pass TimeOfDay
                        'date': _date, // Pass DateTime
                      });
                    } : null, // Disabled if no video
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      disabledBackgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: _videoPath != null ? 4 : 0,
                    ),
                    child: const Text(
                      'Play',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                if (_videoPath == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Center(
                      child: Text(
                        'Please upload a video to start the demo',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D9488), fontSize: 12),
      ),
    );
  }

  Widget _buildButton(String text, IconData? icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF374151),
                fontSize: 13,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 6),
              Icon(icon, size: 16, color: const Color(0xFF0D9488)),
            ],
          ],
        ),
      ),
    );
  }
}
