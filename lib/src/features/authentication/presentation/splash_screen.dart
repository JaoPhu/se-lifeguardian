import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  double _progress = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    
    // Progress animation (20ms steps, 2000ms duration)
    _timer = Timer.periodic(const Duration(milliseconds: 20), (timer) async {
      if (!mounted) return;
      
      setState(() {
        _progress += 0.01;
      });

      if (_progress >= 1.0) {
        _progress = 1.0;
        timer.cancel();
        
        if (mounted) {
          // Navigate to overview and let GoRouter's redirect logic handle the rest
          // (Welcome if not logged in, EditProfile if name is missing, etc.)
          context.go('/overview');
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF134E4A), // primary-900
      body: Stack(
        children: [
          // Background Pulse Effect (Subtle radial gradient to match proto)
          Positioned.fill(
             child: Container(
               decoration: BoxDecoration(
                 gradient: RadialGradient(
                   colors: [
                     const Color(0xFF2DD4BF).withValues(alpha: 0.2), // primary-400 opacity 20
                     Colors.transparent,
                   ],
                   center: Alignment.center,
                   radius: 0.8,
                 ),
               ),
             ),
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Container
                Transform.rotate(
                  angle: 3 * math.pi / 180, // 3 degrees
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32), // More rounded
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF042F2E).withValues(alpha: 0.5),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Image.asset(
                        'assets/icon/icon_full.png',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title
                const Text(
                  'LifeGuardian',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Subtitle
                const Text(
                  'SENIOR SAFETY SYSTEM',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF99F6E4), // primary-200
                    letterSpacing: 2.0, // tracking-widest
                  ),
                ),
              ],
            ),
          ),
          
          // Loading Bar
          Positioned(
            bottom: 40,
            left: 48,
            right: 48,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF115E59), // primary-800
                borderRadius: BorderRadius.circular(2),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: _progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF5EEAD4), // primary-300
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
