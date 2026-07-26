import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfileViewScreen extends StatefulWidget {
  final String userId;
  const ProfileViewScreen({super.key, required this.userId});

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await http.get(
        Uri.parse('https://playspot-zsof.onrender.com/api/profile/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok']) {
          setState(() {
            _profile = data['profile'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0700),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0700),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFFF8F0)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF5A623)),
            )
          : _profile == null
              ? const Center(
                  child: Text(
                    'Profile not found',
                    style: TextStyle(color: Color(0x8CFFF8F0)),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header with avatar
                      Container(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Avatar
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF1A0C00),
                                border: Border.all(
                                  color: const Color(0xFFF5A623),
                                  width: 3,
                                ),
                              ),
                              child: ClipOval(
                                child: _profile!['photoUrl'] != null &&
                                        _profile!['photoUrl'].isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: _profile!['photoUrl'],
                                        fit: BoxFit.cover,
                                        errorWidget: (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Color(0xFFF5A623),
                                            ),
                                      )
                                    : const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Color(0xFFF5A623),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Name
                            Text(
                              _profile!['name'] ?? 'Player',
                              style: const TextStyle(
                                color: Color(0xFFFFF8F0),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Email
                            if (_profile!['email'] != null &&
                                _profile!['email'].isNotEmpty)
                              Text(
                                _profile!['email'],
                                style: const TextStyle(
                                  color: Color(0x8CFFF8F0),
                                  fontSize: 14,
                                ),
                              ),
                            const SizedBox(height: 8),
                            // Pro badge
                            if (_profile!['isPro'] == true)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5A623),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'PRO',
                                  style: TextStyle(
                                    color: Color(0xFF140A00),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Stats
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Games Hosted',
                                '${_profile!['hostedCount'] ?? 0}',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Games Joined',
                                '${_profile!['joinedCount'] ?? 0}',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Points',
                                '${_profile!['points'] ?? 0}',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Bio
                      if (_profile!['bio'] != null &&
                          _profile!['bio'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'About',
                                style: TextStyle(
                                  color: Color(0xFFF5A623),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _profile!['bio'],
                                style: const TextStyle(
                                  color: Color(0x8CFFF8F0),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      // Sports
                      if (_profile!['sports'] != null &&
                          (_profile!['sports'] as List).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sports',
                                style: TextStyle(
                                  color: Color(0xFFF5A623),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: (_profile!['sports'] as List)
                                    .map<Widget>((sport) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A0C00),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFFF5A623),
                                      ),
                                    ),
                                    child: Text(
                                      '${_getSportEmoji(sport)} ${sport.toString().toUpperCase()}',
                                      style: const TextStyle(
                                        color: Color(0xFFFFF8F0),
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      // Neighborhood
                      if (_profile!['neighborhood'] != null &&
                          _profile!['neighborhood'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Location',
                                style: TextStyle(
                                  color: Color(0xFFF5A623),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '📍 ${_profile!['neighborhood']}',
                                style: const TextStyle(
                                  color: Color(0x8CFFF8F0),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0C00),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1AFFB93C)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFF5A623),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0x8CFFF8F0),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _getSportEmoji(String sport) {
    final emojis = {
      'football': '⚽',
      'cricket': '🏏',
      'basketball': '🏀',
      'badminton': '🏸',
      'volleyball': '🏐',
      'tennis': '🎾',
      'running': '🏃',
      'cycling': '🚴',
      'frisbee': '🥏',
      'hockey': '🏑',
      'kabaddi': '🤼',
    };
    return emojis[sport] ?? '🎯';
  }
}
