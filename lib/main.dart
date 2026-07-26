import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'theme/playspot_theme.dart';
import 'screens/ps_app_shell.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'socket_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Disable mock mode to test real backend
  if (kDebugMode) {
    SocketService.setMockMode(false);
  }
  
  final prefs = await SharedPreferences.getInstance();
  
  // Generate or retrieve userId
  String? userId = prefs.getString('ps_userId');
  if (userId == null) {
    userId = 'u_${DateTime.now().millisecondsSinceEpoch.toString()}';
    await prefs.setString('ps_userId', userId);
  }
  
  runApp(PlaySpotApp(userId: userId));
}

class PlaySpotApp extends StatelessWidget {
  final String userId;
  const PlaySpotApp({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      debugLogDiagnostics: kDebugMode,
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => WelcomeScreen(
            onGetStarted: () => context.go('/splash'),
          ),
        ),
        GoRoute(
          path: '/splash',
          builder: (context, state) => SplashScreen(
            onFinished: () async {
              final hasProfile = await _checkProfile();
              if (hasProfile) {
                context.go('/home');
              } else {
                context.go('/onboarding');
              }
            },
          ),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const ProfileScreen(isFirstTimeSetup: true),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const PSAppShell(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        backgroundColor: const Color(0xFF0E0700),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFF5A623), size: 64),
              const SizedBox(height: 16),
              const Text(
                'Page not found',
                style: TextStyle(color: Color(0xFFFFF8F0), fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5A623),
                  foregroundColor: const Color(0xFF140A00),
                ),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );

    return MaterialApp.router(
      title: 'PlaySpot',
      debugShowCheckedModeBanner: false,
      theme: buildPlaySpotTheme(),
      routerConfig: router,
      builder: (context, child) {
        return Container(
          color: const Color(0xFF050300),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: child,
            ),
          ),
        );
      },
    );
  }

  Future<bool> _checkProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('ps_profile');
  }
}
