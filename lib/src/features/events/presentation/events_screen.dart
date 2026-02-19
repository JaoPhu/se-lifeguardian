import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../pose_detection/data/health_status_provider.dart';
import '../../dashboard/data/camera_provider.dart';
import '../../events/data/event_repository.dart';
import '../../statistics/domain/simulation_event.dart';
import '../../profile/data/user_repository.dart';

class EventsScreen extends ConsumerWidget {
  final String cameraId;
  const EventsScreen({super.key, required this.cameraId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    // final healthState = ref.watch(healthStatusProvider);
    final eventsStream = ref.watch(eventsStreamProvider);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Get camera name for context
    final cameras = ref.watch(cameraProvider);
    final camera = cameras.any((c) => c.id == cameraId) 
        ? cameras.firstWhere((c) => c.id == cameraId)
        : null;
    final cameraName = camera?.name ?? 'Camera';

    return Scaffold(
      backgroundColor: const Color(0xFF0D9492),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(top: 56, bottom: 24, left: 24, right: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Events',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.push('/notifications'),
                      child: const Icon(Icons.notifications, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => context.push('/profile'),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade900 : Colors.yellow.shade100,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          image: DecorationImage(
                            image: NetworkImage(user.avatarUrl),
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
              padding: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(0),
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                children: [
                                   eventsStream.when(
                    data: (allEvents) {
                      final events = allEvents.where((e) => e.cameraId == cameraId).toList();
                      return Column(
                        children: [
                          // Horizontal Gallery
                          Text(
                            'Events of $cameraName',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D9488),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 180,
                            child: events.isEmpty 
                              ? _buildEmptyGallery(context)
                              : ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: events.length,
                                  separatorBuilder: (context, index) => const SizedBox(width: 16),
                                  itemBuilder: (context, index) {
                                    final event = events[index];
                                    return _buildGalleryItem(context, event, cameraName);
                                  },
                                ),
                          ),
                          const SizedBox(height: 32),
                          // Recent Events List
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recent Events',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D9492),
                                ),
                              ),
                              Row(
                                children: [
                                  if (events.isNotEmpty)
                                    // Hidden as requested
                                    const SizedBox.shrink(),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Total: ${events.length}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.withValues(alpha: 0.6)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          events.isEmpty
                            ? const SizedBox(
                                height: 100,
                                child: Center(child: Text('No events detected yet.', style: TextStyle(color: Colors.grey)))
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
                                itemCount: events.length,
                                separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12),
                                itemBuilder: (context, index) {
                                  final event = events[index];
                                  return _buildEventListItem(context, event);
                                },
                              ),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Center(child: Text('Error: $e')),
                  ),

                  const SizedBox(height: 32),

                  // Outlined Health Button
                  SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        context.go('/status');
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF0D9488), width: 1),
                        foregroundColor: const Color(0xFF0D9488),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'View Status & Statistics',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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

  Widget _buildEmptyGallery(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300, style: BorderStyle.solid),
      ),
      child: const Center(
        child: Text('Waiting for start...', style: TextStyle(color: Colors.grey)),
      ),
    );
  }

  Widget _buildGalleryItem(BuildContext context, SimulationEvent event, String cameraName) {
    return Container(
      width: 180, // Narrower as in prototype
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: event.remoteImageUrl != null
                    ? Image.network(
                        event.remoteImageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) => _buildLocalOrPlaceholder(event),
                      )
                    : _buildLocalOrPlaceholder(event),
                ),
                if (event.isVerified)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white, size: 8),
                          const SizedBox(width: 2),
                          Text(
                            'AI Verified ${(event.confidence ?? 0 * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${event.thaiLabel} of $cameraName',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEventListItem(BuildContext context, SimulationEvent event) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.thaiLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.grey.shade200 : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Duration: ${event.duration ?? "0.32 hr"}",
                  style: const TextStyle(
                    fontSize: 14, 
                    color: Color(0xFF0D9488),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.description ?? "Subject is resting in a horizontal position",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (event.isVerified) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.verified_user, size: 12, color: Color(0xFF0D9488)),
                      const SizedBox(width: 4),
                      Text(
                        'AI Verified (${(event.confidence ?? 0 * 100).toStringAsFixed(0)}% Confidence)',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF0D9488), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                event.date ?? "2026/02/05",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                event.timestamp,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocalOrPlaceholder(SimulationEvent event) {
    if (event.snapshotUrl != null && File(event.snapshotUrl!).existsSync()) {
      return Image.file(
        File(event.snapshotUrl!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return Container(
      color: Colors.teal.shade50,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Icon(
          _getIconForType(event.type),
          size: 32,
          color: const Color(0xFF0D9488),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'sitting': return Icons.chair;
      case 'slouching': return Icons.accessibility_new;
      case 'walking': return Icons.directions_walk;
      case 'standing': return Icons.person;
      case 'laying': return Icons.hotel;
      case 'exercise': return Icons.fitness_center;
      case 'falling': return Icons.warning_amber_rounded;
      case 'near_fall': return Icons.error_outline;
      default: return Icons.local_activity;
    }
  }
}
