import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/share_utils.dart';
import '../utils/sport_icons.dart';

class FeedCard extends StatefulWidget {
  final Map<String, dynamic> game;
  final VoidCallback onTap;

  const FeedCard({
    super.key,
    required this.game,
    required this.onTap,
  });

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.974).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown() {
    _animationController.forward();
  }

  void _handleTapUp() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final sport = widget.game['sport'] ?? 'unknown';
    final sportEmoji = _getSportEmoji(sport);
    final title = widget.game['title'] ?? 'Game';
    final location = widget.game['location'] ?? 'Location on map';
    final players = widget.game['players'] as List<dynamic>? ?? [];
    final maxPlayers = widget.game['maxPlayers'] ?? 10;
    final photoUrl = widget.game['photoUrl'];
    final createdAt = DateTime.tryParse(widget.game['createdAt'] ?? '');
    final isLive = createdAt != null && 
        DateTime.now().difference(createdAt).inMinutes < 60;
    final isFull = players.length >= maxPlayers;

    final host = players.isNotEmpty ? players[0] as Map<String, dynamic>? : null;
    final hostName = host?['name'] ?? 'Host';
    final hostPhoto = host?['photoUrl'];

    return GestureDetector(
      onTapDown: (_) => _handleTapDown(),
      onTapUp: (_) => _handleTapUp(),
      onTapCancel: () => _animationController.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A0C00),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x1AFFB93C)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo header
              SizedBox(
                height: 148,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Photo or gradient
                    if (photoUrl != null && photoUrl.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, error, stackTrace) =>
                            _buildGradientBackground(sportEmoji),
                      )
                    else
                      _buildGradientBackground(sportEmoji),
                    
                    // Dark gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    
                    // Sport badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5A623).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SportIcons.getSportImage(_getSportName(sport), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              _getSportName(sport),
                              style: const TextStyle(
                                color: Color(0xFF140A00),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Status badge
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isFull
                              ? const Color(0xFF1A0C00)
                              : isLive
                                  ? const Color(0xFFFF4D1C)
                                  : const Color(0xFFF5A623),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isFull
                              ? 'FULL'
                              : isLive
                                  ? '🔴 LIVE'
                                  : '${players.length}/$maxPlayers',
                          style: TextStyle(
                            color: isFull
                                ? const Color(0xFFFF4D1C)
                                : const Color(0xFF140A00),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    // Player avatar stack
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Row(
                        children: [
                          ...players.take(3).map((player) {
                            final p = player as Map<String, dynamic>;
                            final pPhoto = p['photoUrl'];
                            return Padding(
                              padding: const EdgeInsets.only(right: -8),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF0E0700),
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: pPhoto != null && pPhoto.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: pPhoto,
                                          fit: BoxFit.cover,
                                          errorWidget: (context, error, stackTrace) =>
                                              _buildDefaultAvatar(),
                                        )
                                      : _buildDefaultAvatar(),
                                ),
                              ),
                            );
                          }).toList(),
                          if (players.length > 3)
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF241200),
                                border: Border.all(
                                  color: const Color(0xFF0E0700),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '+${players.length - 3}',
                                  style: const TextStyle(
                                    color: Color(0xFFFFF8F0),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Card body
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFFFF8F0),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '📍 $location',
                      style: const TextStyle(
                        color: Color(0x8CFFF8F0),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Host avatar
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF241200),
                          ),
                          child: ClipOval(
                            child: hostPhoto != null && hostPhoto.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: hostPhoto,
                                    fit: BoxFit.cover,
                                    errorWidget: (context, error, stackTrace) =>
                                        _buildDefaultAvatar(),
                                  )
                                : _buildDefaultAvatar(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Host name
                        Expanded(
                          child: Text(
                            '@${hostName.split(' ')[0]}',
                            style: const TextStyle(
                              color: Color(0x8CFFF8F0),
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Share button
                        GestureDetector(
                          onTap: () {
                            ShareUtils.shareGameOnWhatsApp(
                              gameTitle: title,
                              sport: sport,
                              location: location,
                              gameId: widget.game['id'],
                            );
                          },
                          child: const Text(
                            '📲',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientBackground(String sportName) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E1800), Color(0xFF221000)],
        ),
      ),
      child: Center(
        child: SportIcons.getSportImage(sportName, size: 64),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: const Color(0xFF241200),
      child: const Icon(Icons.person, size: 16, color: Color(0xFFF5A623)),
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

  String _getSportName(String sport) {
    final names = {
      'football': 'Football',
      'cricket': 'Cricket',
      'basketball': 'Basketball',
      'badminton': 'Badminton',
      'volleyball': 'Volleyball',
      'tennis': 'Tennis',
      'running': 'Running',
      'cycling': 'Cycling',
      'frisbee': 'Frisbee',
      'hockey': 'Hockey',
      'kabaddi': 'Kabaddi',
    };
    return names[sport] ?? 'Sport';
  }
}
