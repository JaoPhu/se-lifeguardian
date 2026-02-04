import 'dart:typed_data';
import 'pose_models.dart';

abstract class IPoseDetectionService {
  Future<List<dynamic>> detect(dynamic input, Uint8List originalBytes);
  Future<void> close();
}
