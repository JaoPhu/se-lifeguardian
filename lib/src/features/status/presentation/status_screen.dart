import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../pose_detection/data/health_status_provider.dart';
import '../../notification/presentation/notification_bell.dart';

class StatusScreen extends ConsumerWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthState = ref.watch(healthStatusProvider);
    final config = _getStatusConfig(healthState.status, context);

    return Scaffold(
      backgroundColor: const Color(0xFF0D9488),
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
                  
                  // Status Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: config.bgColor,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        if (config.icon != null)
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: config.iconBgColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              config.icon,
                              color: config.iconColor,
                              size: 32,
                            ),
                          ),
                        if (config.icon != null) const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: config.icon == null ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                            children: [
                              Text(
                                config.title,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: config.textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                config.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: config.textColor.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Activity Summary
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white.withValues(alpha: 0.05) 
                            : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Activity Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D9488),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        if (healthState.status == HealthStatus.none || healthState.events.isEmpty)
                          const SizedBox(
                            height: 100,
                            child: Center(
                              child: Text('No information.', style: TextStyle(color: Colors.grey)),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: healthState.events.length > 4 ? 4 : healthState.events.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final event = healthState.events[index];
                              return _buildActivityItem(
                                context, 
                                "${event.thaiLabel}${event.duration != null ? " (${event.duration})" : ""}", 
                                _getIconForType(event.type), 
                                event.isCritical
                              );
                            },
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Statistics Button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        context.go('/statistics');
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
                        'Statistics',
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

  Widget _buildActivityItem(BuildContext context, String text, IconData icon, bool highlight) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight 
          ? Theme.of(context).dividerColor.withValues(alpha: 0.1)
          : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight 
              ? const Color(0xFF0D9488).withValues(alpha: 0.3)
              : Theme.of(context).dividerColor.withValues(alpha: 0.05)
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF0D9488)),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade300 : const Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(HealthStatus status, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (status) {
      case HealthStatus.normal:
        return _StatusConfig(
          title: 'Status : Normal',
          description: 'No abnormal behavior detected.',
          bgColor: const Color(0xFF34D399),
          iconBgColor: const Color(0xFF10B981).withValues(alpha: 0.3),
          icon: Icons.check,
          textColor: const Color(0xFF064E3B),
          iconColor: const Color(0xFF064E3B),
        );
      case HealthStatus.warning:
        return _StatusConfig(
          title: 'Status : Warning',
          description: 'Detect risky behavior.',
          bgColor: const Color(0xFFFBBF24),
          iconBgColor: const Color(0xFFF59E0B).withValues(alpha: 0.3),
          icon: Icons.warning_amber_rounded,
          textColor: const Color(0xFF78350F),
          iconColor: const Color(0xFF78350F),
        );
      case HealthStatus.emergency:
        return _StatusConfig(
          title: 'Status : Emergency',
          description: 'Emergency detected.',
          bgColor: const Color(0xFFEF4444),
          iconBgColor: const Color(0xFFDC2626).withValues(alpha: 0.3),
          icon: Icons.add,
          textColor: Colors.white,
          iconColor: Colors.white,
        );
      case HealthStatus.none:
        return _StatusConfig(
          title: 'Status : None',
          description: 'No information.',
          bgColor: Theme.of(context).dividerColor.withValues(alpha: 0.05),
          iconBgColor: Colors.transparent,
          icon: null,
          textColor: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
          iconColor: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
        );
    }
  }
}

class _StatusConfig {
  final String title;
  final String description;
  final Color bgColor;
  final Color iconBgColor;
  final IconData? icon;
  final Color textColor;
  final Color iconColor;

  _StatusConfig({
    required this.title,
    required this.description,
    required this.bgColor,
    required this.iconBgColor,
    required this.icon,
    required this.textColor,
    required this.iconColor,
  });
}
