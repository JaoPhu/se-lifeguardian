import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/camera.dart';
import 'camera_repository.dart';
import '../../authentication/providers/auth_providers.dart'; // import authStateProvider
import '../../statistics/domain/simulation_event.dart';

class CameraNotifier extends StateNotifier<List<Camera>> {
  final CameraRepository _repository;

  CameraNotifier(this._repository) : super([]);

  // Placeholder camera for future real camera implementation
  static const _placeholderCamera = Camera(
    id: 'placeholder-cam-01',
    name: 'Camera 1',
    status: CameraStatus.offline,
    source: CameraSource.camera,
    events: [],
  );

  // Load cameras from repository
  void loadCameras(List<Camera> cameras) {
    // Sort demos by newest first (descending ID)
    cameras.sort((a, b) => b.id.compareTo(a.id));
    
    // User asked to "keep one disconnected box". 
    // We'll put it first or last? Usually "Camera 1" suggests it's the main one.
    // Let's prepend it.
    state = [_placeholderCamera, ...cameras];
  }

  Future<void> addCamera(Camera camera) async {
    // Optimistic update
    if (state.any((c) => c.id == camera.id)) {
      state = state.map((c) => c.id == camera.id ? camera : c).toList();
    } else {
      state = [camera, ...state];
    }
    // Sync to Cloud
    await _repository.saveCamera(camera);
  }

  Future<Camera> addCameraSafely(String baseName, {CameraConfig? config}) async {
    // 1. Ensure unique name within the user's camera list
    String uniqueName = baseName;
    int suffix = 1;
    // Iterate to find a unique name (e.g. "Camera", "Camera_1", "Camera_2")
    while (state.any((c) => c.name == uniqueName)) {
      uniqueName = "${baseName}_$suffix";
      suffix++;
    }

    final id = 'cam-${DateTime.now().millisecondsSinceEpoch}';
    final newCamera = Camera(
      id: id,
      name: uniqueName,
      status: CameraStatus.online,
      source: CameraSource.demo,
      events: const [],
      config: config,
    );
    // Optimistic
    state = [newCamera, ...state];
    // Sync
    await _repository.saveCamera(newCamera);
    return newCamera;
  }

  Future<void> updateCameraEvents(String id, List<SimulationEvent> events) async {
    final camera = state.firstWhere((c) => c.id == id, orElse: () => throw Exception('Camera not found'));
    final updated = camera.copyWith(events: events);
    
    // Optimistic
    state = state.map((c) => c.id == id ? updated : c).toList();
    // Sync
    await _repository.saveCamera(updated);
  }

  Future<void> deleteCamera(String id) async {
    // Optimistic update
    state = state.where((c) => c.id != id).toList();
    // Sync to Cloud
    await _repository.deleteCamera(id);
  }
}

final cameraProvider = StateNotifierProvider<CameraNotifier, List<Camera>>((ref) {
  final repository = ref.watch(cameraRepositoryProvider);
  final notifier = CameraNotifier(repository);

  // Watch for auth changes to reload stream
  ref.watch(authStateProvider);

  // Subscribe to Firestore updates
  final subscription = repository.watchCameras().listen((cameras) {
    notifier.loadCameras(cameras);
  });
  
  ref.onDispose(() => subscription.cancel());

  return notifier;
});
