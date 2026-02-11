import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/camera.dart';
import '../../statistics/domain/simulation_event.dart';

class CameraNotifier extends StateNotifier<List<Camera>> {
  CameraNotifier() : super([
    const Camera(
      id: 'cam-01',
      name: 'Camera 1',
      status: CameraStatus.offline,
      source: CameraSource.camera,
      events: [],
    ),
  ]);

  void clearCameras() {
    state = [];
  }

  void addCamera(Camera camera) {
    if (state.any((c) => c.id == camera.id)) {
      state = state.map((c) => c.id == camera.id ? camera : c).toList();
    } else {
      state = [camera, ...state];
    }
  }

  String addCameraSafely(String baseName, {CameraConfig? config}) {
    final id = 'cam-${DateTime.now().millisecondsSinceEpoch}';
    final newCamera = Camera(
      id: id,
      name: baseName,
      status: CameraStatus.online,
      source: CameraSource.demo,
      events: const [],
      config: config,
    );
    state = [newCamera, ...state];
    return id;
  }

  void updateCameraEvents(String id, List<SimulationEvent> events) {
    state = state.map((c) => c.id == id ? c.copyWith(events: events) : c).toList();
  }

  void removeCamera(String id) {
    state = state.where((c) => c.id != id).toList();
  }
}

final cameraProvider = StateNotifierProvider<CameraNotifier, List<Camera>>((ref) {
  return CameraNotifier();
});
