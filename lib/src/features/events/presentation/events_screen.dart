import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../pose_detection/data/health_status_provider.dart';
import '../../statistics/domain/simulation_event.dart';

class EventsScreen extends ConsumerWidget {
  final String cameraId;
  const EventsScreen({super.key, required this.cameraId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthState = ref.watch(healthStatusProvider);
    final events = healthState.events;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFF0D9488),
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
                      'Monitoring Data',
                      style: TextStyle(
                        fontSize: 20,
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(0),
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                children: [
                  
                  // Horizontal Gallery (Stickman/Snapshot Previews)
                  const Text(
                    'Activity Gallery',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D9488),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 160,
                    child: events.isEmpty 
                      ? _buildEmptyGallery(context)
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: events.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            final event = events[index];
                            return _buildGalleryItem(context, event);
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
                          color: Color(0xFF374151),
                        ),
                      ),
                      Text(
                        'Total: ${events.length}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return _buildEventListItem(context, event);
                        },
                      ),

                  const SizedBox(height: 24),

                  // Health Status Button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        context.go('/status');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Health Status & Stats',
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

  Widget _buildGalleryItem(BuildContext context, SimulationEvent event) {
    final isCritical = event.isCritical;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: isCritical ? Colors.red.shade50 : (isDark ? Colors.grey.shade800 : Colors.white),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isCritical ? Border.all(color: Colors.red.shade300, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCritical ? Colors.red.shade100 : Colors.teal.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  _getIconForType(event.type),
                  size: 48,
                  color: isCritical ? Colors.red : const Color(0xFF0D9488),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.thaiLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isCritical ? Colors.red : (isDark ? Colors.grey.shade200 : const Color(0xFF374151)),
                      ),
                    ),
                    Text(
                      event.timestamp,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
                if (isCritical)
                  const Icon(Icons.warning, color: Colors.red, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventListItem(BuildContext context, SimulationEvent event) {
    final isCritical = event.isCritical;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCritical 
            ? (isDark ? Colors.red.withValues(alpha: 0.1) : Colors.red.shade50)
            : (isDark ? Colors.grey.shade900 : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(16),
        border: isCritical ? Border.all(color: Colors.red.shade200) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCritical ? Colors.red.shade100 : Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIconForType(event.type),
              size: 20,
              color: isCritical ? Colors.red : const Color(0xFF0D9488),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.thaiLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isCritical ? Colors.red : (isDark ? Colors.grey.shade200 : const Color(0xFF374151)),
                  ),
                ),
                Text(
                  event.description ?? "Duration: ${event.duration ?? "0.5 hr"}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            event.timestamp,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ],
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
