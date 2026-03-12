import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../domain/simulation_event.dart';
import '../../profile/data/user_repository.dart';
import '../../notification/presentation/notification_bell.dart';
import '../../../common_widgets/user_avatar.dart';

import '../../history/data/history_repository_provider.dart';


class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  DateTime _selectedDate = DateTime.now();

  String get _formattedDate {
    // Format: Today DD/MM/YY (BE)
    final d = DateFormat('dd/MM').format(_selectedDate);
    final y = (_selectedDate.year + 543).toString().substring(2);
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());
    return "${isToday ? 'Today ' : ''}$d/$y";
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF0D9488),
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Map<String, double> _calculateDurations(List<SimulationEvent> events) {
    double relax = 0;
    double work = 0;
    double walk = 0;
    double slouch = 0;
    double exercise = 0;
    int falls = 0;

    for (var event in events) {
      final type = event.type.toLowerCase();
      // Use precise seconds if available, otherwise fallback
      double duration = 0.0;
      if (event.durationSeconds != null) {
        duration = event.durationSeconds! / 3600; // Convert seconds to hours
      } else {
        final durationStr = event.duration ?? '0.0h';
        duration = double.tryParse(durationStr.replaceAll('h', '')) ?? 0.0;
      }

      // Robust matching
      if (type == 'sitting' || type == 'laying' || type == 'relax') {
        relax += duration;
      } else if (type == 'working' || type == 'work' || type == 'standing') {
        work += duration;
      } else if (type == 'walking' || type == 'walk') {
        walk += duration;
      } else if (type == 'slouching' || type == 'slouch') {
        slouch += duration;
      } else if (type == 'exercise') {
        exercise += duration;
      } else if (type == 'falling' || type == 'fall' || type == 'near_fall') {
        falls++;
      }
    }

    return {
      'relax': relax,
      'work': work,
      'walk': walk,
      'slouch': slouch,
      'exercise': exercise,
      'falls': falls.toDouble(),
    };
  }

  List<PieChartSectionData> _getPieSections(List<SimulationEvent> events) {
    if (events.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return [
        PieChartSectionData(
          color: isDark ? Colors.white10 : const Color(0xFFE8EBF0),
          value: 1,
          radius: 90,
          showTitle: false,
        )
      ];
    }

    final stats = _calculateDurations(events);
    final List<PieChartSectionData> sections = [];
    
    // Calculate total recorded hours
    final double recordedTotal = stats['relax']! + 
                          stats['work']! + 
                          stats['walk']! + 
                          stats['slouch']! + 
                          stats['exercise']!;
                          
    // Denominator is 24h or total if > 24h (as requested for testing scenarios)
    final double totalDenominator = recordedTotal > 24 ? recordedTotal : 24.0;

    if (stats['relax']! > 0) {
      sections.add(PieChartSectionData(
        color: Colors.blue.shade500,
        value: stats['relax']!,
        radius: 90,
        showTitle: false,
      ));
    }
    if (stats['work']! > 0) {
      sections.add(PieChartSectionData(
        color: Colors.amber.shade400,
        value: stats['work']!,
        radius: 90,
        showTitle: false,
      ));
    }
    if (stats['walk']! > 0) {
      sections.add(PieChartSectionData(
        color: const Color(0xFF10B981),
        value: stats['walk']!,
        radius: 90,
        showTitle: false,
      ));
    }
    if (stats['slouch']! > 0) {
      sections.add(PieChartSectionData(
        color: Colors.purple.shade500,
        value: stats['slouch']!,
        radius: 90,
        showTitle: false,
      ));
    }
    if (stats['exercise']! > 0) {
      sections.add(PieChartSectionData(
        color: Colors.indigo.shade500,
        value: stats['exercise']!,
        radius: 90,
        showTitle: false,
      ));
    }
    
    // Add "Empty/Rest" time to fill up to 24h (or handle overflow)
    final remains = totalDenominator - recordedTotal;
    if (remains > 0.01) { // Tiny buffer for float precision
      final isDark = Theme.of(context).brightness == Brightness.dark;
      sections.add(PieChartSectionData(
        color: isDark ? Colors.white10 : const Color(0xFFE8EBF0),
        value: remains,
        radius: 90,
        showTitle: false,
      ));
    }

    // Critical events (falls) are shown as indicators if present, not as part of the time pie
    // But since they were previously in the sections with a small clamp, I'll remove them from the pie
    // as they aren't "duration" based in the same way. The user said "เปรียบเทียบแบบปกติ"
    // which usually means the primary activity time.

    return sections;
  }

  DateTime _getStartOfWeek(DateTime date) {
    // Assuming week starts on Monday (1)
    return date.subtract(Duration(days: date.weekday - 1));
  }
  
  final List<String> _weekLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    // 1. Fetch Weekly Stats
    final startOfWeek = _getStartOfWeek(_selectedDate);
    final weeklyStatsAsync = ref.watch(weeklyStatsProvider(startOfWeek));

    // 2. Fetch Daily Events (Filtered by selected date)
    final dailyEventsAsync = ref.watch(dailyEventsProvider(_selectedDate));

    // 3. User & Theme
    final user = ref.watch(userProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return dailyEventsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error loading stats: $err'))),
      data: (dailyEvents) {
        final stats = _calculateDurations(dailyEvents);

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
                    const Text(
                      'Statistics',
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
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(0),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Column(
                      children: [
                        // Date Picker
                        Align(
                          alignment: Alignment.centerRight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedDate = DateTime.now();
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _formattedDate,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.grey.shade200
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _selectDate(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'choose date',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Daily Progress Circle
                        SizedBox(
                          height: 290,
                          width: 290,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 230,
                                height: 230,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFBDC6D3), width: 1.2),
                                  color: Colors.transparent,
                                ),
                              ),

                              SizedBox(
                                width: 180,
                                height: 180,
                                child: PieChart(
                                  PieChartData(
                                    sections: _getPieSections(dailyEvents),
                                    sectionsSpace: 0,
                                    centerSpaceRadius: 0,
                                    startDegreeOffset: 270,
                                    borderData: FlBorderData(show: false),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Summary Cards
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(child: _buildSummaryCard('Relax\n${stats['relax']!.toStringAsFixed(1)}h', Icons.weekend, isDark ? Colors.blue.shade900.withValues(alpha: 0.6) : const Color(0xFFE3F2FD), isDark ? Colors.blue.shade100 : const Color(0xFF1565C0))),
                              const SizedBox(width: 12),
                              Expanded(child: _buildSummaryCard('Work\n${stats['work']!.toStringAsFixed(1)}h', Icons.work, isDark ? Colors.amber.shade900.withValues(alpha: 0.6) : const Color(0xFFFFF8E1), isDark ? Colors.amber.shade100 : const Color(0xFFF57F17))),
                              const SizedBox(width: 12),
                              Expanded(child: _buildSummaryCard('Walk\n${stats['walk']!.toStringAsFixed(1)}h', Icons.directions_walk, isDark ? Colors.green.shade900.withValues(alpha: 0.6) : const Color(0xFFECFDF5), isDark ? Colors.green.shade100 : const Color(0xFF047857))),
                              const SizedBox(width: 12),
                              Expanded(child: _buildSummaryCard('Critical\n${stats['falls']!.toInt()}', Icons.warning_amber_rounded, isDark ? Colors.red.shade900.withValues(alpha: 0.6) : const Color(0xFFFFEBEE), isDark ? Colors.red.shade100 : const Color(0xFFC62828))),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 24),

                        // Weekly Statistics
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Weekly', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                              const SizedBox(height: 20),
                              
                              AspectRatio(
                                aspectRatio: 1.5,
                                child: weeklyStatsAsync.when(
                                  loading: () => const Center(child: CircularProgressIndicator()),
                                  error: (err, stack) => Center(child: Text('Error: $err')),
                                  data: (weeklyStats) {
                                    return BarChart(
                                      BarChartData(
                                        alignment: BarChartAlignment.spaceBetween,
                                        maxY: 24,
                                        barTouchData: BarTouchData(
                                          enabled: true,
                                          touchTooltipData: BarTouchTooltipData(
                                            getTooltipColor: (_) => Colors.blueGrey,
                                            tooltipBorderRadius: BorderRadius.circular(8),
                                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                              return BarTooltipItem(
                                                '${_weekLabels[group.x.toInt()]}\n',
                                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                                children: [TextSpan(text: rod.toY.toStringAsFixed(1))]
                                              );
                                            }
                                          ),
                                        ),
                                        titlesData: FlTitlesData(
                                          show: true,
                                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          topTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 20,
                                              getTitlesWidget: (value, meta) {
                                                final index = value.toInt();
                                                if (index < 0 || index >= weeklyStats.dailyStats.length) return const SizedBox();
                                                final dayStat = weeklyStats.dailyStats[index];
                                                if (dayStat.falls > 0) {
                                                  return const Icon(Icons.error, color: Color(0xFFC62828), size: 16);
                                                }
                                                return const SizedBox();
                                              },
                                            ),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 30,
                                              getTitlesWidget: (value, meta) {
                                                final index = value.toInt();
                                                if (index >= 0 && index < _weekLabels.length) {
                                                  return Padding(
                                                    padding: const EdgeInsets.only(top: 8.0),
                                                    child: Text(
                                                      _weekLabels[index],
                                                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B), fontWeight: FontWeight.bold),
                                                    ),
                                                  );
                                                }
                                                return const SizedBox();
                                              },
                                            ),
                                          ),
                                        ),
                                        gridData: const FlGridData(show: false),
                                        borderData: FlBorderData(show: false),
                                        barGroups: weeklyStats.dailyStats.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final stat = entry.value;
                                          final totalHours = stat.relaxHours + stat.workHours + stat.walkHours;
                                          
                                          return BarChartGroupData(
                                            x: index,
                                            barRods: [
                                              BarChartRodData(
                                                toY: totalHours,
                                                width: 16,
                                                borderRadius: BorderRadius.circular(6),
                                                backDrawRodData: BackgroundBarChartRodData(
                                                  show: true,
                                                  toY: 24,
                                                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
                                                ),
                                                rodStackItems: totalHours == 0 ? [] : [
                                                  BarChartRodStackItem(0, stat.relaxHours, Colors.blue.shade200),
                                                  BarChartRodStackItem(stat.relaxHours, stat.relaxHours + stat.workHours, Colors.amber.shade200),
                                                  BarChartRodStackItem(stat.relaxHours + stat.workHours, totalHours, const Color(0xFF10B981).withValues(alpha: 0.5)),
                                                ],
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(height: 25),
                              const Center(
                                child: Text('Weekly statistics for this week', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 24),

                        // Event History List
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Event History',
                            style: TextStyle(
                              fontSize: 22, 
                              fontWeight: FontWeight.bold, 
                              color: isDark ? Colors.white : const Color(0xFF1E293B)
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        if (dailyEvents.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Text('No events recorded for this day', style: TextStyle(color: Colors.grey)),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: dailyEvents.length,
                            itemBuilder: (context, index) {
                              final event = dailyEvents[index];
                              final isCritical = event.isCritical || event.type.contains('fall');
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: isCritical ? Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1.5) : null,
                                ),
                                child: ListTile(
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isCritical 
                                        ? Colors.red.shade50 
                                        : _getIconBgColor(event.type),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _getIconForType(event.type),
                                      color: isCritical 
                                        ? Colors.red.shade600 
                                        : _getIconColor(event.type),
                                    ),
                                  ),
                                  title: Text(
                                    event.thaiLabel,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isCritical ? Colors.red.shade800 : null,
                                    ),
                                  ),
                                  subtitle: Text('${event.timestamp} | Camera: ${event.cameraId ?? "Main"}'),
                                  trailing: Text(
                                    event.duration ?? '0.0h',
                                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
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
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String text, IconData icon, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: textColor),
          const SizedBox(height: 8),
          Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor, height: 1.2), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'sitting': return Icons.chair;
      case 'slouching': return Icons.accessibility_new;
      case 'walking':
      case 'walk': return Icons.directions_walk;
      case 'standing':
      case 'work':
      case 'working': return Icons.person;
      case 'laying': 
      case 'relax': return Icons.hotel;
      case 'exercise': return Icons.fitness_center;
      case 'falling':
      case 'fall': return Icons.warning_amber_rounded;
      case 'near_fall': return Icons.error_outline;
      default: return Icons.local_activity;
    }
  }

  Color _getIconBgColor(String type) {
    switch (type.toLowerCase()) {
      case 'exercise': return Colors.orange.shade50;
      case 'walking':
      case 'walk': return Colors.teal.shade50;
      case 'standing':
      case 'work':
      case 'working': return Colors.blue.shade50;
      case 'sitting':
      case 'laying':
      case 'relax': return Colors.purple.shade50;
      default: return Colors.grey.shade50;
    }
  }

  Color _getIconColor(String type) {
    switch (type.toLowerCase()) {
      case 'exercise': return Colors.orange.shade600;
      case 'walking':
      case 'walk': return Colors.teal.shade600;
      case 'standing':
      case 'work':
      case 'working': return Colors.blue.shade600;
      case 'sitting':
      case 'laying':
      case 'relax': return Colors.purple.shade600;
      default: return Colors.grey.shade600;
    }
  }
}
