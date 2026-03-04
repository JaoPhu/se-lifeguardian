import 'package:flutter/material.dart';

class TopNotificationToast extends StatefulWidget {
  final String title;
  final String message;
  final String time;
  final VoidCallback onDismissed;

  const TopNotificationToast({
    super.key,
    required this.title,
    required this.message,
    required this.time,
    required this.onDismissed,
  });

  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context,
    String title,
    String message, {
    String time = '',
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Remove any existing toast first
      try {
        _currentEntry?.remove();
      } catch (_) {}
      _currentEntry = null;

      // Use the Navigator overlay (root level) to ensure it shows above everything
      final overlay = Navigator.of(context, rootNavigator: true).overlay;
      if (overlay == null) return;

      late OverlayEntry overlayEntry;

      overlayEntry = OverlayEntry(
        builder: (ctx) => TopNotificationToast(
          title: title,
          message: message,
          time: time,
          onDismissed: () {
            try {
              if (_currentEntry == overlayEntry) {
                _currentEntry?.remove();
                _currentEntry = null;
              }
            } catch (_) {}
          },
        ),
      );

      _currentEntry = overlayEntry;
      overlay.insert(overlayEntry);
    });
  }

  @override
  State<TopNotificationToast> createState() => _TopNotificationToastState();
}

class _TopNotificationToastState extends State<TopNotificationToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    // Auto-dismiss after 6 seconds
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismissed());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (_controller.isAnimating || _controller.isCompleted) {
      _controller.reverse().then((_) => widget.onDismissed());
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final displayTime = widget.time.isNotEmpty ? widget.time : _formatNow();

    return Positioned(
      top: topPadding + 12,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _offsetAnimation,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              if (details.delta.dy < -2) {
                _dismiss();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.97),
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: Logo + App name + Time + Close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D9488),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Center(
                              child: Text(
                                'LG',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'LIFEGUARDIAN',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            displayTime,
                            style: const TextStyle(
                              color: Colors.black45,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _dismiss,
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Body
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatNow() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
