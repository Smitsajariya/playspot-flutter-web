import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/ps_bottom_nav.dart';
import '../socket_service.dart';
import 'ps_home_screen.dart';
import 'events_screen.dart';
import 'leaderboard_screen.dart';
import 'map_screen.dart';
import 'host_category_screen.dart';
import 'host_activity_screen.dart';
import 'host_form_screen.dart';
import 'chat_list_screen.dart';
import 'social_feed_screen.dart';
import 'create_post_screen.dart';
import 'go_live_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'friends_screen.dart';

/// Root shell — owns the bottom nav state and swaps the body screen.
/// MAP, PROFILE-VIEW, HOST-FORM, JOIN, etc. are intentionally not built yet;
/// this first pass covers HOME / EVENTS / RANKS / the sport-picker (HOST entry).
class PSAppShell extends StatefulWidget {
  const PSAppShell({super.key});

  @override
  State<PSAppShell> createState() => _PSAppShellState();
}

class _PSAppShellState extends State<PSAppShell> {
  PSNavTab _tab = PSNavTab.home;
  bool _showingCategoryPicker = false;
  String? _selectedCategory;
  Function(Map<String, dynamic>)? _onPostCreated;
  bool _isConnected = false;
  DateTime? _disconnectedSince;
  Timer? _connectionTicker;
  final SocketService _socketService = SocketService();

  @override
  void initState() {
    super.initState();
    _socketService.setConnectionStatusCallback((connected) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
          _disconnectedSince = connected ? null : (_disconnectedSince ?? DateTime.now());
        });
        if (!connected) {
          _connectionTicker ??= Timer.periodic(const Duration(seconds: 3), (_) {
            if (mounted) setState(() {});
          });
        } else {
          _connectionTicker?.cancel();
          _connectionTicker = null;
        }
      }
    });
    _socketService.connect();
  }

  @override
  void dispose() {
    _connectionTicker?.cancel();
    super.dispose();
  }

  void _goHostFlow() => setState(() => _showingCategoryPicker = true);
  void _closeHostFlow() => setState(() {
    _showingCategoryPicker = false;
    _selectedCategory = null;
  });
  void _goToActivityScreen(String categoryId) {
    setState(() => _selectedCategory = categoryId);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HostActivityScreen(
          categoryId: categoryId,
          onActivitySelect: (activity) {
            Navigator.pop(context);
            _goToHostForm(activity);
          },
        ),
      ),
    );
  }
  void _goToHostForm(dynamic activity) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HostFormScreen(selectedActivity: activity)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showingCategoryPicker) {
      return Scaffold(
        body: HostCategoryScreen(
          onBack: _closeHostFlow,
          onCategorySelect: (categoryId) {
            _goToActivityScreen(categoryId);
          },
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          _buildBody(),
          // Connection status indicator
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _isConnected ? 0 : 40,
              child: _isConnected
                  ? const SizedBox.shrink()
                  : Builder(
                      builder: (context) {
                        final waitedSeconds = _disconnectedSince == null
                            ? 0
                            : DateTime.now().difference(_disconnectedSince!).inSeconds;
                        // Render's free tier can take up to ~50s to wake from
                        // sleep. Treat that window as normal/expected rather
                        // than alarming the user with a permanent red error.
                        final isLikelyColdStart = waitedSeconds < 50;
                        return Container(
                          color: (isLikelyColdStart ? Colors.amber[800] : Colors.red)!.withOpacity(0.9),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: isLikelyColdStart
                                    ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                                    : const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isLikelyColdStart
                                      ? 'Waking up the server — this can take up to a minute the first time.'
                                      : 'Still having trouble connecting. Check your internet or try again.',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                              if (!isLikelyColdStart)
                                TextButton(
                                  onPressed: () => _socketService.connect(),
                                  child: const Text(
                                    'Retry',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: PSBottomNav(
              current: _tab,
              onSelect: (t) => setState(() => _tab = t),
              onHostTap: _goHostFlow,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_tab) {
      case PSNavTab.home:
        return PSHomeScreen(
          onHostTap: _goHostFlow,
          onMapTap: () => setState(() => _tab = PSNavTab.map),
          onEventsTap: () => setState(() => _tab = PSNavTab.events),
          onLeaderboardTap: () => setState(() => _tab = PSNavTab.ranks),
          onProfileTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen(isFirstTimeSetup: false)),
            );
          },
          onNotificationsTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationsScreen()),
            );
          },
          onFriendsTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FriendsScreen()),
            );
          },
        );
      case PSNavTab.map:
        return const MapScreen();
      case PSNavTab.host:
        return const SizedBox.shrink(); // handled via _showingSportPicker
      case PSNavTab.chats:
        return const ChatListScreen();
      case PSNavTab.events:
        return const EventsScreen();
      case PSNavTab.ranks:
        return const LeaderboardScreen();
      case PSNavTab.social:
        return SocialFeedScreen(
          onCreatePost: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreatePostScreen(
                  onPostCreated: (postData) {
                    setState(() {
                      _tab = PSNavTab.social;
                    });
                  },
                ),
              ),
            );
          },
          onGoLive: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GoLiveScreen()),
            );
          },
        );
    }
  }
}
