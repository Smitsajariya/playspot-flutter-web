import 'package:flutter/material.dart';
import '../theme/playspot_theme.dart';

/// First screen shown when the app link is opened.
/// Deliberately has zero dependency on any image asset — pure gradient +
/// text — so it always renders even if something else in the app (fonts,
/// branding images, network) fails to load.
class WelcomeScreen extends StatelessWidget {
  final VoidCallback onGetStarted;

  const WelcomeScreen({super.key, required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PSColors.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background hero photo
          Image.asset(
            'assets/branding/welcome_hero.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.3),
                  radius: 1.2,
                  colors: [
                    Color(0xFF3A2408),
                    PSColors.bg,
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),
          // Gradient scrim so text/button stay readable over the photo
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x000E0700),
                  Color(0x660E0700),
                  Color(0xE60E0700),
                  Color(0xFF0E0700),
                ],
                stops: [0.0, 0.45, 0.75, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 5),
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                        height: 1.3,
                      ),
                      children: [
                        TextSpan(text: 'Welcome to ', style: TextStyle(color: Colors.white)),
                        TextSpan(text: 'PlaySpot', style: TextStyle(color: PSColors.gold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Find pickup games, sports events, and people\nto play with — all near you.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: PSColors.inkDim,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const Spacer(flex: 3),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: onGetStarted,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PSColors.gold,
                        foregroundColor: const Color(0xFF140A00),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(PSRadius.md),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
