import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/camera_provider.dart';
import '../domain/camera.dart';
import '../../pose_detection/data/health_status_provider.dart';
import '../../notification/presentation/notification_bell.dart';
import '../../profile/data/user_repository.dart';
import '../../statistics/domain/simulation_event.dart';
import '../../../common_widgets/user_avatar.dart';

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    // final isDark = Theme.of(context).brightness == Brightness.dark; // Unused
    final cameras = ref.watch(cameraProvider);
    final healthState = ref.watch(healthStatusProvider);

    return Scaffold(

      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(top: 56, bottom: 24, left: 24, right: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0D9488),
                  const Color(0xFF0D9488).withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'LifeGuardian',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                Row(
                  children: [
                    const NotificationBell(color: Colors.white, whiteBorder: true),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => context.push('/profile'),
                      child: UserAvatar(
                        avatarUrl: user.avatarUrl,
                        radius: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(0),
                ),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ...cameras.map((camera) => _buildCameraCard(context, ref, camera, healthState)),
                  
                  const SizedBox(height: 24),
                  
                  // Try Demo Button
                  Center(
                    child: SizedBox(
                      width: 240,
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                    child: ElevatedButton(
                      onPressed: () => context.push('/demo-setup'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_circle_fill, color: Colors.white),
                          SizedBox(width: 12),
                          Text(
                            'Try Demo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildCameraCard(BuildContext context, WidgetRef ref, Camera camera, HealthState healthState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12), // Reduced padding to match prototype px-3 (approx 12px)
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.white.withValues(alpha: 0.05) 
              : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    camera.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D9488),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (camera.status != CameraStatus.offline)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onSelected: (value) async {
                      if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Camera?'),
                            content: const Text('This will remove the camera and permanently delete all its associated history and images.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true), 
                                child: const Text('Delete', style: TextStyle(color: Colors.red))
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          // 1. Clear History for this camera first
                          await ref.read(healthStatusProvider.notifier).clearAllData(cameraId: camera.id);
                          // 2. Remove the camera
                          ref.read(cameraProvider.notifier).removeCamera(camera.id);
                        }
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Connection Status Box with Aspect Ratio 16:9
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: camera.status == CameraStatus.online 
                    ? Colors.black 
                    : (isDark ? const Color(0xFF111827) : const Color(0xFFD9D9D9)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: camera.status == CameraStatus.offline 
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'No connection',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8F9197),
                        ),
                      ),
                      Text(
                        'This function is not available.',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF8F9197),
                        ),
                      ),
                    ],
                  )
                : Builder(
                    builder: (context) {
                      final configThumbnail = camera.config?.thumbnailUrl;

                      // Find the latest event for this camera from the global state
                      final cameraEvents = healthState.events.where((e) => e.cameraId == camera.id).toList();
                      final latestEvent = cameraEvents.isNotEmpty ? cameraEvents.first : null;

                      if (configThumbnail != null) {
                        return _buildImageWrapper(File(configThumbnail).existsSync() ? Image.file(File(configThumbnail)) : null);
                      } else if (latestEvent != null) {
                        if (latestEvent.remoteImageUrl != null) {
                          return _buildImageWrapper(
                            Image.network(
                              latestEvent.remoteImageUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => _buildLocalFallback(latestEvent),
                            ),
                          );
                        } else if (latestEvent.snapshotUrl != null) {
                          return _buildImageWrapper(_buildLocalFallback(latestEvent));
                        }
                      }
                      return const Center(child: Icon(Icons.videocam_off, color: Colors.white54));
                    },
                  ),
            ),
          ),
          const SizedBox(height: 12),

          // Footer Row
          Row(
            children: [
              // Left Date Range
              Expanded(
                child: Builder(
                  builder: (context) {
                    final cameraEvents = healthState.events.where((e) => e.cameraId == camera.id).toList();
                    if (cameraEvents.isEmpty) {
                      return const SizedBox();
                    }
                    
                    final dates = cameraEvents
                        .map((e) => e.date)
                        .whereType<String>()
                        .toSet()
                        .toList();
                    dates.sort();
                    
                    if (dates.isEmpty) return const SizedBox();
                    
                    String formatDate(String d) => d.replaceAll('-', '/');
                    
                    final dateLabel = dates.length == 1 
                        ? formatDate(dates.first)
                        : "${formatDate(dates.first)} - ${formatDate(dates.last)}";

                    return Text(
                      dateLabel,
                      style: const TextStyle(
                        fontSize: 14, // Match prototype size
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B7280), // Slate/Grey as in prototype
                      ),
                    );
                  },
                ),
              ),
              
              // Center Events Button
              Expanded(
                child: Center(
                  child: TextButton.icon(
                    onPressed: camera.status == CameraStatus.offline 
                        ? null 
                        : () => context.push('/events/${camera.id}'),
                    icon: Icon(
                      Icons.folder_open, 
                      size: 20, 
                      color: camera.status == CameraStatus.offline ? Colors.grey.shade300 : const Color(0xFF0D9488)
                    ),
                    label: Text(
                      'Events',
                      style: TextStyle(
                        color: camera.status == CameraStatus.offline ? Colors.grey.shade300 : const Color(0xFF0D9488), 
                        fontWeight: FontWeight.bold, 
                        fontSize: 14
                      ),
                    ),
                  ),
                ),
              ),
              
              // Right Source Label
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    camera.source.name,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageWrapper(Widget? child) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: child ?? Container(color: Colors.grey[900]),
      ),
    );
  }

  Widget _buildLocalFallback(SimulationEvent event) {
    if (event.snapshotUrl != null && File(event.snapshotUrl!).existsSync()) {
      return Image.file(
        File(event.snapshotUrl!),
        fit: BoxFit.contain,
      );
    }
    return Container(color: Colors.grey[900]);
  }
}
