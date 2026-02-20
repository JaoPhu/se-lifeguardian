import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/camera.dart';
import 'camera_repository.dart';
import '../../statistics/domain/simulation_event.dart';

import '../../group/providers/group_providers.dart';

class CameraNotifier extends StateNotifier<List<Camera>> {
  final CameraRepository _repository;
  final Ref _ref;

  CameraNotifier(this._repository, this._ref) : super([]);

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

  Future<Camera?> addCameraSafely(String baseName, {CameraConfig? config}) async {
    // 1. Ensure unique name within the user's camera list
    String uniqueName = baseName;
    int suffix = 1;
    // Iterate to find a unique name (e.g. "Camera", "Camera_1", "Camera_2")
    while (state.any((c) => c.name == uniqueName)) {
      uniqueName = "${baseName}_$suffix";
      suffix++;
    }

    final id = 'cam-${DateTime.now().millisecondsSinceEpoch}';
    
    // 2. Handle Thumbnail Upload (if local)
    CameraConfig? finalConfig = config;
    if (config?.thumbnailUrl != null && !config!.thumbnailUrl!.startsWith('http')) {
      final remoteUrl = await _repository.uploadThumbnail(config.thumbnailUrl!, id);
      if (remoteUrl != null) {
        finalConfig = config.copyWith(thumbnailUrl: remoteUrl);
      }
    }

    final newCamera = Camera(
      id: id,
      name: uniqueName,
      status: CameraStatus.online,
      source: CameraSource.demo,
      events: const [],
      config: finalConfig,
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
  final notifier = CameraNotifier(repository, ref);

  // Watch for the active target UID
  final targetUid = ref.watch(resolvedTargetUidProvider);

  if (targetUid.isNotEmpty) {
    final subscription = repository.watchCameras(targetUid).listen((cameras) {
      notifier.loadCameras(cameras);
    });
    
    ref.onDispose(() => subscription.cancel());
  } else {
    // Pass empty if no UID available
    notifier.loadCameras([]);
  }

  return notifier;
});
