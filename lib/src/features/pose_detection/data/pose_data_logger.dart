import 'dart:io';
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'pose_models.dart';

class PoseDataLogger {
  bool isRecording = false;
  String? currentLabel;
  final List<String> _buffer = [];

  void startRecording(String label) {
    isRecording = true;
    currentLabel = label;
    _buffer.clear();
    debugPrint('PoseDataLogger: Started recording for $label');
  }

  void stopRecording() async {
    isRecording = false;
    if (_buffer.isNotEmpty) {
      await _saveToFile();
    }
    debugPrint('PoseDataLogger: Stopped recording. Buffer size: ${_buffer.length}');
  }

  void addFrame(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    if (!isRecording || currentLabel == null) return;

    final normalized = _normalize(landmarks);
    if (normalized == null) return;

    final List<String> row = [currentLabel!];
    
    // We iterate through all landmark types to ensure consistent CSV columns
    // Use a fixed order for columns
    for (var type in PoseLandmarkType.values) {
      final l = normalized[type];
      if (l != null) {
        row.add(l.x.toStringAsFixed(4));
        row.add(l.y.toStringAsFixed(4));
        row.add(l.z.toStringAsFixed(4));
      } else {
        // Placeholder for missing data
        row.add("0.0000");
        row.add("0.0000");
        row.add("0.0000");
      }
    }

    _buffer.add(row.join(','));
  }

  Map<PoseLandmarkType, PoseLandmark>? _normalize(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];

    if (leftHip == null || rightHip == null || leftShoulder == null || rightShoulder == null) {
      return null;
    }

    // 1. Calculate Center point (Mid-hip)
    final centerX = (leftHip.x + rightHip.x) / 2;
    final centerY = (leftHip.y + rightHip.y) / 2;

    // 2. Calculate Scale factor (Shoulder distance)
    final double scale = math.sqrt(
      math.pow(leftShoulder.x - rightShoulder.x, 2) + 
      math.pow(leftShoulder.y - rightShoulder.y, 2)
    );

    if (scale == 0) return null;

    // 3. Normalize all points
    final Map<PoseLandmarkType, PoseLandmark> normalized = {};
    for (var entry in landmarks.entries) {
      normalized[entry.key] = PoseLandmark(
        type: entry.key,
        x: (entry.value.x - centerX) / scale,
        y: (entry.value.y - centerY) / scale,
        z: entry.value.z / scale,
        likelihood: entry.value.likelihood,
      );
    }

    return normalized;
  }

  Future<void> _saveToFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/pose_data_$timestamp.csv');

      // Add Header
      final List<String> header = ['label'];
      for (var type in PoseLandmarkType.values) {
        header.add('${type.name}_x');
        header.add('${type.name}_y');
        header.add('${type.name}_z');
      }

      final content = '${header.join(',')}\n${_buffer.join('\n')}';
      await file.writeAsString(content);
      debugPrint('PoseDataLogger: CSV saved to ${file.path}');
    } catch (e) {
      debugPrint('PoseDataLogger: Error saving file: $e');
    }
  }

  Future<List<File>> getSavedFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = directory.listSync();
    return files
        .whereType<File>()
        .where((f) => f.path.contains('pose_data_') && f.path.endsWith('.csv'))
        .toList();
  }
}
