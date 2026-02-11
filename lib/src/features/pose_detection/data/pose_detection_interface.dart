import 'dart:typed_data';


abstract class IPoseDetectionService {
  Future<List<dynamic>> detect(dynamic input, Uint8List originalBytes);
  Future<void> close();
}
