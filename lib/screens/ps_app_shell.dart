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
  final SocketService _socketService = SocketService();

  @override
  void initState() {
    super.initState();
    _socketService.connect();
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
