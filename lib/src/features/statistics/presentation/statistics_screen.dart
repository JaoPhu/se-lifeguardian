import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../pose_detection/data/health_status_provider.dart';
import '../domain/simulation_event.dart';
import '../../notification/presentation/notification_bell.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  DateTime _selectedDate = DateTime.now();

  String get _formattedDate {
    return DateFormat('dd MMM yyyy').format(_selectedDate);
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
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF111827), // Dark theme for picker to match app feel
              onPrimary: Colors.white,
              onSurface: Color(0xFF111827),
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
      // Trigger provider refresh if needed, but since we use local state for date
      // and providers might watch this state if lifted up.
      // Current architecture seems to rely on selectedDateProvider in history.
      // But user said "H้ามแก้ feature history".
      // Wait, the previous implementation used `_selectedDate` local state.
      // So I keep it local based on "H้ามแก้ feature history" instruction.
      // But for "ref.refresh provider", if the data depends on it...
      // The previous code passed `healthState.events` which comes from `healthStatusProvider`.
      // `healthStatusProvider` usually gives current live data or data for a date?
      // Looking at imports: `../../pose_detection/data/health_status_provider.dart`
      // It seems to be the global health status.
      // User said: "เมื่อเลือกวันที่ → setState และ ref.refresh provider" in requirement.
      // So I will add `ref.refresh(healthStatusProvider)`.
      ref.refresh(healthStatusProvider);
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
      double duration = 0.0;
      if (event.durationSeconds != null) {
        duration = event.durationSeconds! / 3600;
      } else {
        final durationStr = event.duration ?? '0.0h';
        duration = double.tryParse(durationStr.replaceAll('h', '')) ?? 0.0;
      }

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
      } else if (type == 'falling' || type == 'fall') {
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

  @override
  Widget build(BuildContext context) {
    final healthState = ref.watch(healthStatusProvider);
    final stats = _calculateDurations(healthState.events);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildDateSelector(context),
                    const SizedBox(height: 20),
                    _buildSummaryGrid(context, stats),
                    const SizedBox(height: 20),
                    _buildPieChartSection(context, stats),
                    const SizedBox(height: 20),
                    _buildWeeklyChartSection(context),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Statistics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => context.push('/notification'),
                child: const Icon(Icons.notifications_none, color: Color(0xFF111827)),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey.shade200,
                  child: const Icon(Icons.person, size: 20, color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: Color(0xFF111827)),
            const SizedBox(width: 8),
            Text(
              _formattedDate,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF111827),
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: Color(0xFF111827)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(BuildContext context, Map<String, double> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildStatCard(
              title: 'Relax',
              value: '${stats['relax']?.toStringAsFixed(1)}h',
              icon: Icons.weekend, // chair replacement
              color: const Color(0xFF3B82F6),
              width: cardWidth,
            ),
            _buildStatCard(
              title: 'Work',
              value: '${stats['work']?.toStringAsFixed(1)}h',
              icon: Icons.work,
              color: const Color(0xFFF59E0B),
              width: cardWidth,
            ),
            _buildStatCard(
              title: 'Walk',
              value: '${stats['walk']?.toStringAsFixed(1)}h',
              icon: Icons.directions_walk,
              color: const Color(0xFF22C55E),
              width: cardWidth,
            ),
            _buildStatCard(
              title: 'Falls',
              value: '${stats['falls']?.toInt()}',
              icon: Icons.warning,
              color: const Color(0xFFEF4444),
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title: $value')),
        );
      },
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartSection(BuildContext context, Map<String, double> stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 70,
                sections: _getPieSections(stats),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildLegend(),
        ],
      ),
    );
  }

  List<PieChartSectionData> _getPieSections(Map<String, double> stats) {
    final total = (stats['relax'] ?? 0) + (stats['work'] ?? 0) + (stats['walk'] ?? 0) + (stats['falls'] ?? 0);
    // Add default if total is 0 to show empty chart
    if (total == 0) {
      return [
         PieChartSectionData(
          color: const Color(0xFFF3F4F6),
          value: 1,
          radius: 60,
          showTitle: false,
        ),
      ];
    }
    
    return [
      if ((stats['relax'] ?? 0) > 0)
        PieChartSectionData(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.85),
          value: stats['relax']!,
          radius: 60,
          showTitle: false,
        ),
      if ((stats['work'] ?? 0) > 0)
        PieChartSectionData(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.85),
          value: stats['work']!,
          radius: 60,
          showTitle: false,
        ),
      if ((stats['walk'] ?? 0) > 0)
        PieChartSectionData(
          color: const Color(0xFF22C55E).withValues(alpha: 0.85),
          value: stats['walk']!,
          radius: 60,
          showTitle: false,
        ),
      if ((stats['falls'] ?? 0) > 0)
        PieChartSectionData(
          color: const Color(0xFFEF4444).withValues(alpha: 0.85),
          value: stats['falls']!,
          radius: 60,
          showTitle: false,
        ),
    ];
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Relax', const Color(0xFF3B82F6)),
        const SizedBox(width: 16),
        _buildLegendItem('Work', const Color(0xFFF59E0B)),
        const SizedBox(width: 16),
        _buildLegendItem('Walk', const Color(0xFF22C55E)),
      ],
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChartSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 20),
          AspectRatio(
            aspectRatio: 1.7,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 1,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const style = TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 10,
                        );
                        Widget text;
                        switch (value.toInt()) {
                          case 0:
                            text = const Text('M', style: style);
                            break;
                          case 1:
                            text = const Text('T', style: style);
                            break;
                          case 2:
                            text = const Text('W', style: style);
                            break;
                          case 3:
                            text = const Text('T', style: style);
                            break;
                          case 4:
                            text = const Text('F', style: style);
                            break;
                          case 5:
                            text = const Text('S', style: style);
                            break;
                          case 6:
                            text = const Text('S', style: style);
                            break;
                          default:
                            text = const Text('', style: style);
                        }
                        return SideTitleWidget(
                          meta: meta,
                          space: 4,
                          child: text,
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: 0.4 + (index % 3) * 0.2, // Mock data logic similar to prev
                        color: index == 6 ? const Color(0xFF111827) : const Color(0xFFE5E7EB),
                        width: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


