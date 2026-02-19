import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class AnalysisLoadingScreen extends StatefulWidget {
  final Map<String, dynamic> extras;

  const AnalysisLoadingScreen({
    super.key,
    required this.extras,
  });

  @override
  State<AnalysisLoadingScreen> createState() => _AnalysisLoadingScreenState();
}

class _AnalysisLoadingScreenState extends State<AnalysisLoadingScreen> {
  @override
  void initState() {
    super.initState();
    _startAnalysis();
  }

  Future<void> _startAnalysis() async {
    // Simulate analysis delay
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      // Navigate to the actual pose detection view
      // We'll use a new route path for the actual view, e.g., '/pose-detection'
      // Or we can replace the current route in the stack?
      // Since AppRouter maps '/analysis' to this, we need 'PoseDetectorView' to be on a different path 
      // OR we handle this inside this widget (switch child).
      
      // Better approach: Update AppRouter to point '/analysis' to this, 
      // and map '/simulation-view' to PoseDetectorView.
      context.replace('/simulation-view', extra: widget.extras);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Use a loading indicator or Lottie if available. 
            // Fallback to CircularProgressIndicator for now.
            const CircularProgressIndicator(
              color: Color(0xFF0D9488),
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text(
              "Analyzing Video...",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Processing frames and detecting poses",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
