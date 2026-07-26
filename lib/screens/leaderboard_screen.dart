import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<dynamic> _players = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://playspot-zsof.onrender.com/api/leaderboard'),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok']) {
          setState(() {
            _players = data['players'] ?? [];
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      print('Error loading leaderboard: $e');
    }

    // Fallback to mock data if backend fails
    if (mounted) {
      setState(() {
        _players = _getMockPlayers();
        _isLoading = false;
      });
    }
  }

  List<dynamic> _getMockPlayers() {
    return [
      {
        'id': '1',
        'name': 'Alex Johnson',
        'username': 'alex_runner',
        'avatarUrl': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop&crop=face',
        'points': 1250,
        'wins': 45,
        'losses': 12,
      },
      {
        'id': '2',
        'name': 'Sarah Chen',
        'username': 'sarah_tennis',
        'avatarUrl': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&h=200&fit=crop&crop=face',
        'points': 1180,
        'wins': 42,
        'losses': 15,
      },
      {
        'id': '3',
        'name': 'Emma Williams',
        'username': 'emma_basketball',
        'avatarUrl': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200&h=200&fit=crop&crop=face',
        'points': 980,
        'wins': 38,
        'losses': 18,
      },
      {
        'id': '4',
        'name': 'Mike Sports',
        'username': 'mike_football',
        'avatarUrl': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&h=200&fit=crop&crop=face',
        'points': 850,
        'wins': 32,
        'losses': 20,
      },
      {
        'id': '5',
        'name': 'David Kim',
        'username': 'david_swim',
        'avatarUrl': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&h=200&fit=crop&crop=face',
        'points': 720,
        'wins': 28,
        'losses': 22,
      },
    ];
  }

  String _getRankEmoji(int rank) {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    if (rank == 3) return '🥉';
    return '#$rank';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0700),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0700),
        elevation: 0,
        title: const Text(
          'Leaderboard',
          style: TextStyle(
            color: Color(0xFFFFF8F0),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF5A623)),
            )
          : _players.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events,
                        size: 64,
                        color: const Color(0x47FFF8F0),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No rankings yet',
                        style: TextStyle(
                          color: Color(0x47FFF8F0),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Play games to earn points!',
                        style: TextStyle(
                          color: Color(0x47FFF8F0),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _players.length,
                  itemBuilder: (context, index) {
                    final player = _players[index];
                    final name = player['name'] ?? 'Player';
                    final points = player['points'] ?? 0;
                    final photoUrl = player['photoUrl'];
                    final rank = index + 1;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: rank <= 3 
                              ? const Color(0xFFF5A623).withOpacity(0.1)
                              : const Color(0xFF1A0C00),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: rank <= 3 
                                ? const Color(0xFFF5A623)
                                : const Color(0x1AFFB93C),
                            width: rank <= 3 ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Rank
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: rank <= 3 
                                    ? const Color(0xFFF5A623)
                                    : const Color(0xFF241200),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  _getRankEmoji(rank),
                                  style: TextStyle(
                                    fontSize: rank <= 3 ? 20 : 14,
                                    color: rank <= 3 
                                        ? const Color(0xFF140A00)
                                        : const Color(0xFFF5A623),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Avatar
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                                  ? CachedNetworkImageProvider(photoUrl)
                                  : null,
                              child: photoUrl == null || photoUrl.isEmpty
                                  ? const Icon(Icons.person, color: Color(0xFFF5A623))
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            // Name and points
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: Color(0xFFFFF8F0),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$points points',
                                    style: const TextStyle(
                                      color: Color(0x8CFFF8F0),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Points badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5A623),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$points',
                                style: const TextStyle(
                                  color: Color(0xFF140A00),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
