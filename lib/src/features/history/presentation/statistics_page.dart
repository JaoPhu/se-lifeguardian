import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/history_repository_provider.dart';
import 'widgets/activity_circle_widget.dart';
import 'widgets/stats_summary_card.dart';
import 'widgets/weekly_chart_widget.dart';
import 'widgets/custom_date_picker_dialog.dart';

import '../../../constants/app_stats_colors.dart';

class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use selectedDateProvider for stable state
    final selectedDate = ref.watch(selectedDateProvider);
    final dailyStatsAsync = ref.watch(dailyStatsProvider(selectedDate));
    // Start of week for weekly stats
    final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    final weeklyStatsAsync = ref.watch(weeklyStatsProvider(startOfWeek));

    return Scaffold(
      backgroundColor: const Color(0xFF0D9488), // Teal background matching prototype
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Statistics',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                           // Navigate to notification if route exists, else show snackbar
                           try {
                             context.push('/notification');
                           } catch (e) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('Notification feature not implemented yet')),
                             );
                           }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.notifications, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                           try {
                             context.push('/profile');
                           } catch (e) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('Profile route not found')),
                             );
                           }
                        },
                         borderRadius: BorderRadius.circular(20),
                        child: const CircleAvatar(
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.person, color: Colors.white), 
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // White Container for Content
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                  child: RefreshIndicator(
                    onRefresh: () async {
                      // Invalidate providers to force fetch
                      ref.invalidate(dailyStatsProvider(selectedDate));
                      ref.invalidate(weeklyStatsProvider(startOfWeek));
                      
                      // Wait for both to complete
                      await Future.wait([
                        ref.read(dailyStatsProvider(selectedDate).future),
                        ref.read(weeklyStatsProvider(startOfWeek).future),
                      ]);
                    },
                    color: const Color(0xFF0D9488),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(), // Ensure scroll on short content
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Date Selector
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: () {
                                  ref.read(selectedDateProvider.notifier).state = DateTime.now();
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    // Display selected date
                                    "Today ${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${(selectedDate.year + 543).toString().substring(2)}", 
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDialog<DateTime>(
                                    context: context,
                                    builder: (context) => CustomDatePickerDialog(
                                      initialDate: selectedDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                    ),
                                  );

                                  if (picked != null) {
                                    ref.read(selectedDateProvider.notifier).state = picked;
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text("choose date", style: TextStyle(color: Colors.grey)),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Activity Circle
                          dailyStatsAsync.when(
                            data: (stats) => ActivityCircleWidget(
                                relaxHours: stats.relaxHours,
                                workHours: stats.workHours,
                                walkHours: stats.walkHours,
                            ),
                            loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)))),
                            error: (err, stack) => Text('Error: $err'),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Summary Cards
                          dailyStatsAsync.when(
                            data: (stats) => GridView.count(
                              crossAxisCount: 4,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 0.85, 
                              children: [
                                StatsSummaryCard(
                                  label: 'Relax',
                                  value: '${stats.relaxHours}h',
                                  icon: Icons.weekend,
                                  backgroundColor: AppStatsColors.relaxBg,
                                  iconColor: AppStatsColors.relaxPrimary,
                                  textColor: AppStatsColors.defaultText,
                                  onTap: () => _showDetails(context, 'Relax', '${stats.relaxHours} hours', 'Time spent relaxing.'),
                                ),
                                StatsSummaryCard(
                                  label: 'Work',
                                  value: '${stats.workHours}h',
                                  icon: Icons.work,
                                  backgroundColor: AppStatsColors.workBg,
                                  iconColor: AppStatsColors.workPrimary,
                                  textColor: AppStatsColors.defaultText,
                                  onTap: () => _showDetails(context, 'Work', '${stats.workHours} hours', 'Time spent working.'),
                                ),
                                StatsSummaryCard(
                                  label: 'Walk',
                                  value: '${stats.walkHours}h',
                                  icon: Icons.directions_walk,
                                  backgroundColor: AppStatsColors.walkBg,
                                  iconColor: AppStatsColors.walkPrimary,
                                  textColor: AppStatsColors.defaultText,
                                  onTap: () => _showDetails(context, 'Walk', '${stats.walkHours} hours', 'Time spent walking.'),
                                ),
                                StatsSummaryCard(
                                  label: 'Falls',
                                  value: '${stats.falls}',
                                  icon: Icons.warning_amber_rounded,
                                  backgroundColor: AppStatsColors.fallsBg,
                                  iconColor: AppStatsColors.fallsPrimary,
                                  textColor: AppStatsColors.dangerText,
                                  onTap: () => _showDetails(context, 'Falls', '${stats.falls} times', 'Number of falls detected.'),
                                ),
                              ],
                            ),
                            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488))),
                            error: (err, stack) => Text('Error: $err'),
                          ),
                          
                          const SizedBox(height: 30),
                          
                          // Weekly Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Weekly",
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                weeklyStatsAsync.when(
                                    data: (stats) => WeeklyChartWidget(weeklyStats: stats),
                                    loading: () => const SizedBox(height: 150, child: Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)))),
                                    error: (err, stack) => const Text('Error loading weekly stats'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, String title, String value, String description) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D9488),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
