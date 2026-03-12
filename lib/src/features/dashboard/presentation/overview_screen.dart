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
import '../../group/providers/group_providers.dart';

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    // final isDark = Theme.of(context).brightness == Brightness.dark; // Unused
    final cameras = ref.watch(cameraProvider);
    // healthStatusFamily is now a family provider, we watch it per camera in _buildCameraCard

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
                  // Patient Selector
                  Consumer(
                    builder: (context, ref, child) {
                      final targetUsersAsync = ref.watch(targetUsersProvider);
                      final targets = targetUsersAsync.valueOrNull ?? [];
                      if (targets.isEmpty || targets.length == 1) return const SizedBox();

                      final selectedUid = ref.watch(resolvedTargetUidProvider);
                      // Ensure selectedUid is in the list, otherwise fallback to first
                      final validUid = targets.any((t) => t.uid == selectedUid) ? selectedUid : targets.first.uid;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const Text(
                              'Viewing: ',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0D9488),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                height: 36,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.3)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: validUid,
                                    isExpanded: true,
                                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0D9488), size: 20),
                                    onChanged: (String? newValue) {
                                      ref.read(activeTargetUidProvider.notifier).state = newValue;
                                    },
                                    items: targets.map((target) {
                                      return DropdownMenuItem<String>(
                                        value: target.uid,
                                        child: Text(
                                          target.name,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  ...cameras.map((camera) => _buildCameraCard(context, ref, camera)),
                  
                  const SizedBox(height: 24),
                  
                  // Try Demo Button (Only show if viewing own dashboard)
                  Consumer(
                    builder: (context, ref, child) {
                      final selectedUid = ref.watch(resolvedTargetUidProvider);
                      // selectedUid is the currently viewed ID. 
                      // If it matches the logged in user, or is empty/null, or is the dummy demo user, they are viewing their own stuff.
                      final isOwner = selectedUid.isEmpty || selectedUid == user.id || selectedUid == 'demo_user';

                      if (!isOwner) return const SizedBox.shrink();

                      return Center(
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
                              onPressed: () {
                                // Switch view back to self when testing demo
                                ref.read(activeTargetUidProvider.notifier).state = null; 
                                context.push('/demo-setup');
                              },
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
                      );
                    },
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
  Widget _buildCameraCard(BuildContext context, WidgetRef ref, Camera camera) {
    final healthState = ref.watch(healthStatusFamily(camera.id));
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
                if (camera.status != CameraStatus.offline && (ref.watch(resolvedTargetUidProvider) == ref.watch(userProvider).id))
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onSelected: (value) async {
                      if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            title: const Center(
                              child: Text(
                                'Delete Camera?',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                            content: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'This will remove the camera and permanently delete all its associated history and images.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            actions: [
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0D9488),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                      ),
                                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFD65D5D),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                      ),
                                      child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          // 1. Clear History for this camera first
                          await ref.read(healthStatusFamily(camera.id).notifier).clearAllData(cameraId: camera.id);
                          // 2. Remove the camera
                          ref.read(cameraProvider.notifier).deleteCamera(camera.id);
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


                      if (configThumbnail != null && configThumbnail.startsWith('http')) {
                        return _buildImageWrapper(Image.network(configThumbnail, fit: BoxFit.fitHeight));
                      } else if (configThumbnail != null && File(configThumbnail).existsSync()) {
                        return _buildImageWrapper(Image.file(File(configThumbnail), fit: BoxFit.fitHeight));
                      } else {
                        // Find the latest event for this camera that HAS an image
                        final cameraEvents = healthState.events.where((e) => e.cameraId == camera.id).toList();
                        
                        SimulationEvent? eventWithImage;
                        try {
                          eventWithImage = cameraEvents.firstWhere(
                            (e) => e.remoteImageUrl != null || (e.snapshotUrl != null && File(e.snapshotUrl!).existsSync()),
                          );
                        } catch (_) {
                          // No event with image found
                        }

                        if (eventWithImage != null) {
                          if (eventWithImage.remoteImageUrl != null) {
                            return _buildImageWrapper(
                              Image.network(
                                eventWithImage.remoteImageUrl!,
                                fit: BoxFit.fitHeight,
                                errorBuilder: (context, error, stackTrace) => _buildLocalFallback(eventWithImage!),
                              ),
                            );
                          } else if (eventWithImage.snapshotUrl != null) {
                            return _buildImageWrapper(_buildLocalFallback(eventWithImage));
                          }
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
                    
                    final Set<String> datesSet = {};
                    for (var event in cameraEvents) {
                      if (event.date != null) datesSet.add(event.date!);
                      // Calculate the end date using startTimeMs and duration
                      if (event.startTimeMs != null && event.durationSeconds != null && event.durationSeconds! > 0) {
                        final endTime = DateTime.fromMillisecondsSinceEpoch(event.startTimeMs! + event.durationSeconds! * 1000);
                        final endDateStr = "${endTime.year}-${endTime.month.toString().padLeft(2, '0')}-${endTime.day.toString().padLeft(2, '0')}";
                        datesSet.add(endDateStr);
                      }
                    }
                    final dates = datesSet.toList()..sort();
                    
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
        fit: BoxFit.fitHeight,
      );
    }
    return Container(color: Colors.grey[900]);
  }
}
