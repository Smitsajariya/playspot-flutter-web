import 'package:flutter/material.dart';

/// First screen shown on launch: full-bleed hero photo, wordmark, tagline.
/// Automatically advances to [onFinished] once the minimum display time has
/// elapsed AND the async check it was given has resolved (e.g. checking
/// whether a profile already exists).
class SplashScreen extends StatefulWidget {
  final Future<void> Function() onFinished;
  final Duration minDuration;

  const SplashScreen({
    super.key,
    required this.onFinished,
    this.minDuration = const Duration(milliseconds: 1600),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final timer = Future.delayed(widget.minDuration);
    await Future.wait([timer, widget.onFinished()]);
    _navigated = true;
  }

  void _handleManualContinue() {
    if (_navigated) return; // auto-navigation already fired, avoid double nav
    _navigated = true;
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0700),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background hero photo
          Image.asset(
            'assets/branding/splash_hero.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF0E0700)),
          ),
          // Gradient scrim so the wordmark/tagline stay readable
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00000000),
                  Color(0x00000000),
                  Color(0xCC0E0700),
                  Color(0xFF0E0700),
                ],
                stops: [0.0, 0.45, 0.85, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 64, left: 24, right: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontWeight: FontWeight.w800,
                        fontSize: 44,
                        height: 1,
                      ),
                      children: [
                        TextSpan(text: 'Play', style: TextStyle(color: Colors.white)),
                        TextSpan(text: 'Spot', style: TextStyle(color: Color(0xFFF5A623))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Find games and events near you',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Manual continue button, bottom-right corner
          Positioned(
            right: 20,
            bottom: 20,
            child: SafeArea(
              child: GestureDetector(
                onTap: _handleManualContinue,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF5A623),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF5A623).withOpacity(0.35),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Color(0xFF140A00),
                    size: 24,
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
