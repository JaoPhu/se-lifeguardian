import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/camera_provider.dart';
import '../domain/camera.dart';
import '../../pose_detection/data/health_status_provider.dart';
import '../../notification/presentation/notification_bell.dart';

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameras = ref.watch(cameraProvider);
    final healthState = ref.watch(healthStatusProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D9492), // Slightly deeper teal for premium feel
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
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.yellow.shade100,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          image: const DecorationImage(
                            image: NetworkImage('https://api.dicebear.com/7.x/avataaars/svg?seed=Felix'),
                            fit: BoxFit.cover,
                          ),
                        ),
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
                Text(
                  camera.name,
                  style: const TextStyle(
                    fontSize: 16, // Slightly larger font for name
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D9488),
                  ),
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
                color: camera.status == CameraStatus.online ? Colors.black : const Color(0xFFD9D9D9),
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
                : (healthState.events.isNotEmpty && healthState.events.any((e) => e.snapshotUrl != null))
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(healthState.events.firstWhere((e) => e.snapshotUrl != null).snapshotUrl!),
                          fit: BoxFit.cover,
                        ),
                      )
                    : null,
            ),
          ),
          const SizedBox(height: 12),

          // Footer Row
          Row(
            children: [
              // Left Spacer for parity
              const Expanded(child: SizedBox()),
              
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


}
