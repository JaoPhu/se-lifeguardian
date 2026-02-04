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

  void addCamera(Camera camera) {
    if (state.any((c) => c.id == camera.id)) {
      state = state.map((c) => c.id == camera.id ? camera : c).toList();
    } else {
      state = [camera, ...state];
    }
  }

  void updateCameraEvents(String id, List<SimulationEvent> events) {
    state = state.map((c) => c.id == id ? c.copyWith(events: events) : c).toList();
  }
}

final cameraProvider = StateNotifierProvider<CameraNotifier, List<Camera>>((ref) {
  return CameraNotifier();
});
