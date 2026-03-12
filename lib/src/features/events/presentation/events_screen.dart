import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../dashboard/data/camera_provider.dart';
import '../../events/data/event_repository.dart';
import '../../statistics/domain/simulation_event.dart';
import '../../profile/data/user_repository.dart';
import '../../group/providers/group_providers.dart';
import '../../../common_widgets/user_avatar.dart';

class EventsScreen extends ConsumerStatefulWidget {
  final String cameraId;
  const EventsScreen({super.key, required this.cameraId});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  bool _isGalleryExpanded = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final selectedUid = ref.watch(resolvedTargetUidProvider);
    final isOwner = selectedUid.isEmpty || selectedUid == user.id || selectedUid == 'demo_user';
    final eventsStream = ref.watch(eventsStreamProvider);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Get camera name for context
    final cameras = ref.watch(cameraProvider);
    final camera = cameras.any((c) => c.id == widget.cameraId) 
        ? cameras.firstWhere((c) => c.id == widget.cameraId)
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
                      final events = allEvents.where((e) => e.cameraId == widget.cameraId).toList();
                      
                      // For wrapping gallery:
                      final int maxPreviewCount = 4; // 2 rows of 2 columns
                      final bool showToggle = events.length > maxPreviewCount;
                      final List<SimulationEvent> displayEvents = (showToggle && !_isGalleryExpanded) 
                          ? events.take(maxPreviewCount).toList() 
                          : events;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // --- Patient Selector Dropdown ---
                          Consumer(
                            builder: (context, ref, child) {
                              final targetUsersAsync = ref.watch(targetUsersProvider);
                              final targets = targetUsersAsync.valueOrNull ?? [];
                              if (targets.isEmpty || targets.length == 1) return const SizedBox();

                              final selectedUid = ref.watch(resolvedTargetUidProvider);
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
                                          border: Border.all(color: const Color(0xFF0D9488).withOpacity(0.3)),
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

                          // Gallery Section
                          Text(
                            'Events of $cameraName',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D9488),
                            ),
                          ),
                          const SizedBox(height: 16),
                          events.isEmpty 
                            ? _buildEmptyGallery(context)
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.9,
                                ),
                                itemCount: displayEvents.length,
                                itemBuilder: (context, index) {
                                  return _buildGalleryItem(context, displayEvents[index], cameraName);
                                },
                              ),
                          if (showToggle) ...[
                            const SizedBox(height: 8),
                            Center(
                              child: TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _isGalleryExpanded = !_isGalleryExpanded;
                                  });
                                },
                                icon: Icon(
                                  _isGalleryExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  color: const Color(0xFF0D9488),
                                ),
                                label: Text(
                                  _isGalleryExpanded ? 'Show Less' : 'Show All',
                                  style: const TextStyle(
                                    color: Color(0xFF0D9488),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],

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
                                    const SizedBox.shrink(),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Total: ${events.length}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.withOpacity(0.6)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Builder(builder: (context) {
                            if (events.isEmpty && !isOwner) {
                              final mockEvent = SimulationEvent(
                                id: 'mock_1',
                                cameraId: cameraName,
                                type: 'falling',
                                timestamp: '10:00',
                                date: '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
                                isCritical: true,
                                snapshotUrl: 'assets/images/google_logo.png',
                                startTimeMs: DateTime.now().subtract(const Duration(minutes: 5)).millisecondsSinceEpoch,
                                durationSeconds: 15,
                                duration: "0.00 h",
                                description: 'CRITICAL: Sudden impact detected. Check subject! (Mock Data)',
                                isVerified: false,
                              );
                              return Column(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 8.0),
                                    child: Text('Viewing Demo Data (No real events)', style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
                                  ),
                                  _buildEventListItem(context, mockEvent),
                                ],
                              );
                            }

                            if (events.isEmpty) {
                              return const SizedBox(
                                height: 100,
                                child: Center(child: Text('No events detected yet.', style: TextStyle(color: Colors.grey))),
                              );
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: events.length,
                              separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12),
                              itemBuilder: (context, index) {
                                final event = events[index];
                                return _buildEventListItem(context, event);
                              },
                            );
                          }),
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
      // width removed so GridView contrains it
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
                  "Duration: ${event.duration ?? "0.00 h"}",
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
