import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../pose_detection/data/health_status_provider.dart';
import '../../notification/presentation/notification_bell.dart';
import '../../profile/data/user_repository.dart';
import '../../../common_widgets/user_avatar.dart';

class StatusScreen extends ConsumerWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthState = ref.watch(healthStatusFamily(null));
    final user = ref.watch(userProvider);
    final config = _getStatusConfig(healthState.score, healthState.status, context);

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
                          (() {
                            // Process activities: group by category and sum durations
                            final Map<String, int> categoryDurations = {};
                            final Map<String, String> categoryToRepresentativeType = {}; // For icons
                            final Set<String> criticalCategories = {};
                            
                            // Iterate through latest 50 events
                            for (var event in healthState.events.take(50)) {
                              final categoryLabel = _mapToUserCategory(event.type);
                              categoryDurations[categoryLabel] = (categoryDurations[categoryLabel] ?? 0) + (event.durationSeconds ?? 0);
                              
                              // Keep the first type we see for icon/representative purposes (most recent)
                              categoryToRepresentativeType.putIfAbsent(categoryLabel, () => event.type);
                              
                              if (event.isCritical) {
                                criticalCategories.add(categoryLabel);
                              }
                            }

                            // Define the order of categories as requested by user
                            const order = ['นั่ง', 'เดิน', 'ทำงาน', 'นอน', 'ล้ม'];
                            final sortedCategories = order.where((cat) => categoryDurations.containsKey(cat)).toList();
                            // If there are other categories not in the order list
                            for (var cat in categoryDurations.keys) {
                              if (!order.contains(cat) && !sortedCategories.contains(cat)) {
                                sortedCategories.add(cat);
                              }
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: sortedCategories.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final categoryLabel = sortedCategories[index];
                                final totalSeconds = categoryDurations[categoryLabel]!;
                                final representativeType = categoryToRepresentativeType[categoryLabel]!;
                                final isCritical = criticalCategories.contains(categoryLabel);
                                
                                String durationText = _formatAggregatedDuration(totalSeconds);
                                
                                // Special case for Falls: if we detect multiple falls with 0s duration, 
                                // common for instantaneous events.
                                if (categoryLabel == 'ล้ม' && totalSeconds == 0) {
                                  durationText = "Detected";
                                }

                                return _buildActivityItem(
                                  context, 
                                  "$categoryLabel ($durationText)", 
                                  _getIconForType(representativeType), 
                                  isCritical
                                );
                              },
                            );
                          })(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Health Status Criteria Guide
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
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'เกณฑ์การประเมินสุขภาพ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D9488),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildCriteriaItem(context, 'ปกติ (Normal)', '800-1000', 'สุขภาพดีเยี่ยม ไม่พบพฤติกรรมเสี่ยง', const Color(0xFF0D9488)),
                        const Divider(height: 24),
                        _buildCriteriaItem(context, 'มีความเสี่ยง (Warning)', '500-799', 'พฤติกรรมเสี่ยงสะสม ควรปรับเปลี่ยนท่าทาง', Colors.orange),
                        const Divider(height: 24),
                        _buildCriteriaItem(context, 'ฉุกเฉิน (Emergency)', '0-499', 'วิกฤต: ตรวจพบเหตุฉุกเฉินหรือการล้ม', Colors.red),
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

  String _formatAggregatedDuration(int seconds) {
    if (seconds <= 0) return "0s";
    if (seconds < 60) return "${seconds}s"; 
    
    if (seconds < 3600) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      return s == 0 ? "${m}m" : "${m}m ${s}s";
    }
    
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return m == 0 ? "${h}h" : "${h}h ${m}m";
  }

  String _mapToUserCategory(String type) {
    switch (type) {
      case 'sitting':
      case 'slouching':
        return 'นั่ง';
      case 'walking':
        return 'เดิน';
      case 'standing':
      case 'exercise':
      case 'working':
      case 'work':
        return 'ทำงาน'; // Matches "Work" in Statistics
      case 'laying':
        return 'นอน';
      case 'falling':
      case 'near_fall':
        return 'ล้ม';
      default:
        return 'อื่นๆ';
    }
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

  _StatusConfig _getStatusConfig(int score, HealthStatus status, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scoreText = " ($score/1000)";
    
    // Determine if there's an emergency based on the HealthStatus
    final bool hasEmergency = status == HealthStatus.emergency;

    String scoreDescription = '';
    if (status == HealthStatus.normal) {
      if (score >= 900) {
        scoreDescription = 'สุขภาพดีเยี่ยม ไม่พบพฤติกรรมเสี่ยง';
      } else {
        scoreDescription = 'สุขภาพดี ควรขยับร่างกายบ้างเพื่อความสดชื่น';
      }
    } else if (status == HealthStatus.warning) {
      if (score >= 650) {
        scoreDescription = 'พฤติกรรมเสี่ยงระดับต่ำ โปรดระวังท่านั่งและการเคลื่อนไหว';
      } else {
        scoreDescription = 'พฤติกรรมเสี่ยงระดับกลาง โปรดปรับเปลี่ยนอิริยาบถทันที';
      }
    } else { // HealthStatus.emergency
      scoreDescription = 'วิกฤต: ตรวจพบเหตุฉุกเฉินหรือพฤติกรรมเสี่ยงสูงมาก';
    }

    // Re-evaluate the status based on the score and emergency flag for the final config
    HealthStatus finalStatus;
    if (hasEmergency) {
      finalStatus = HealthStatus.emergency;
    } else if (score >= 800) {
      finalStatus = HealthStatus.normal;
    } else if (score >= 500) {
      finalStatus = HealthStatus.warning;
    } else {
      finalStatus = HealthStatus.emergency; // Fallback for scores below 500 if not already emergency
    }

    Color bgColor;
    Color iconBgColor;
    IconData? icon;
    Color textColor;
    Color iconColor;
    String title;

    switch (finalStatus) {
      case HealthStatus.normal:
        title = 'สถานะ : ปกติ$scoreText';
        bgColor = isDark ? Colors.green.shade900.withValues(alpha: 0.5) : const Color(0xFF34D399);
        iconBgColor = isDark 
            ? Colors.green.shade800 
            : const Color(0xFF10B981).withValues(alpha: 0.3);
        icon = Icons.check_circle;
        textColor = isDark ? Colors.green.shade100 : const Color(0xFF064E3B);
        iconColor = isDark ? Colors.green.shade100 : const Color(0xFF064E3B);
        break;
      case HealthStatus.warning:
        title = 'สถานะ : มีความเสี่ยง$scoreText';
        bgColor = isDark ? Colors.amber.shade900.withValues(alpha: 0.5) : const Color(0xFFFBBF24);
        iconBgColor = isDark 
            ? Colors.amber.shade800 
            : const Color(0xFFF59E0B).withValues(alpha: 0.3);
        icon = Icons.warning_amber_rounded;
        textColor = isDark ? Colors.amber.shade100 : const Color(0xFF78350F);
        iconColor = isDark ? Colors.amber.shade100 : const Color(0xFF78350F);
        break;
      case HealthStatus.emergency:
        title = 'สถานะ : ฉุกเฉิน$scoreText';
        bgColor = isDark ? Colors.red.shade900.withValues(alpha: 0.5) : const Color(0xFFEF4444);
        iconBgColor = isDark 
            ? Colors.red.shade800 
            : const Color(0xFFDC2626).withValues(alpha: 0.3);
        icon = Icons.error;
        textColor = Colors.white;
        iconColor = Colors.white;
        break;
      case HealthStatus.none:
      default:
        title = 'สถานะ : ไม่มีข้อมูล';
        bgColor = Theme.of(context).dividerColor.withValues(alpha: 0.05);
        iconBgColor = Colors.transparent;
        icon = null;
        textColor = isDark ? Colors.grey.shade500 : Colors.grey.shade500;
        iconColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;
        break;
    }

    return _StatusConfig(
      title: title,
      description: scoreDescription,
      bgColor: bgColor,
      iconBgColor: iconBgColor,
      icon: icon,
      textColor: textColor,
      iconColor: iconColor,
    );
  }

  Widget _buildCriteriaItem(BuildContext context, String label, String range, String desc, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 8,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    range,
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
