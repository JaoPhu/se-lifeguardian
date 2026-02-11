import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/history_provider.dart';
import '../widgets/history_list_item.dart';

class HistoryListPage extends ConsumerWidget {
  const HistoryListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyListProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "History",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0D9488), // Teal
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Invalidate provider to trigger refresh
          ref.invalidate(historyListProvider);
          // Wait for the new future to complete
             await ref.read(historyListProvider.future);
        },
        child: historyAsync.when(
          data: (history) {
            if (history.isEmpty) {
               return Center(
                child: Text(
                  "No history available",
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.only(top: 16, bottom: 32),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                return HistoryListItem(history: item);
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF0D9488)),
          ),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  "Failed to load history",
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(historyListProvider),
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
