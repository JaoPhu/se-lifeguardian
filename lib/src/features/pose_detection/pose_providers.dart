import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/pose_data_logger.dart';

final poseDataLoggerProvider = Provider<PoseDataLogger>((ref) {
  return PoseDataLogger();
});

final isRecordingPoseProvider = StateProvider<bool>((ref) => false);
final currentRecordingLabelProvider = StateProvider<String>((ref) => 'none');
