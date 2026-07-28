import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import '../theme/playspot_theme.dart';
import '../models/ps_models.dart';
import '../models/player_model.dart';
import '../widgets/skeleton_loaders.dart';
import '../widgets/refresh_wrapper.dart';
import '../socket_service.dart';
import '../data/mock_data.dart';
import '../services/notification_service.dart';
import '../services/waitlist_service.dart';
import 'player_profile_screen.dart';
import 'profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PSHomeScreen extends StatefulWidget {
  final VoidCallback onHostTap;
  final VoidCallback onMapTap;
  final VoidCallback onEventsTap;
  final VoidCallback onLeaderboardTap;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onFriendsTap;

  const PSHomeScreen({
    super.key,
    required this.onHostTap,
    required this.onMapTap,
    required this.onEventsTap,
    required this.onLeaderboardTap,
    required this.onProfileTap,
    required this.onNotificationsTap,
    required this.onFriendsTap,
  });

  @override
  State<PSHomeScreen> createState() => _PSHomeScreenState();
}

class _PSHomeScreenState extends State<PSHomeScreen> {
  final SocketService _socketService = SocketService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'all';
  bool _isGrid = true;
  List<dynamic> _games = [];
  List<dynamic> _filteredGames = [];
  bool _isLoading = false;
  String _searchQuery = '';
  Position? _currentPosition;
  String? _savedLocationAddress; // User's saved location address
  String? _savedGameType; // User's saved game type
  double? _savedLocationLat;
  double? _savedLocationLng;

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'label': 'All', 'emoji': '🎯'},
    {'id': 'sports', 'label': 'Sports', 'emoji': '⚽'},
    {'id': 'nightlife', 'label': 'Nightlife', 'emoji': '🎤'},
    {'id': 'fitness', 'label': 'Fitness', 'emoji': '💪'},
    {'id': 'cultural', 'label': 'Cultural', 'emoji': '🎭'},
    {'id': 'find_players', 'label': 'Find Players', 'emoji': '👥'},
    {'id': 'custom', 'label': 'Custom', 'emoji': '➕'},
    {'id': 'food', 'label': 'Food', 'emoji': '🍕'},
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadGames();
    _socketService.connect();
    NotificationService().init();
    NotificationService().attachSocketListeners(_socketService);
    WaitlistService.attachSocketListeners(_socketService);
    _socketService.onGamesUpdate((games) {
      if (mounted) {
        setState(() {
          _games = games;
          _applyFilters();
        });
      }
    });
    _socketService.onNewGameCreated((newGame) {
      if (mounted) {
        setState(() {
          _games.add(newGame);
          _applyFilters();
        });
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await Geolocator.openLocationSettings();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        // Recalculate distances when location is obtained
        _applyFilters();
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  String _calculateDistance(double gameLat, double gameLng) {
    // Use saved location if available, otherwise use current GPS location
    if (_savedLocationLat != null && _savedLocationLng != null) {
      try {
        final distanceInMeters = Geolocator.distanceBetween(
          _savedLocationLat!,
          _savedLocationLng!,
          gameLat,
          gameLng,
        );
        final distanceInKm = distanceInMeters / 1000;
        if (distanceInKm < 1) {
          return '${distanceInMeters.toStringAsFixed(0)} m away';
        } else {
          return '${distanceInKm.toStringAsFixed(1)} km away';
        }
      } catch (e) {
        print('Error calculating distance from saved location: $e');
      }
    }
    
    if (_currentPosition == null) {
      return 'Location unknown';
    }

    try {
      final distanceInMeters = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        gameLat,
        gameLng,
      );

      final distanceInKm = distanceInMeters / 1000;
      if (distanceInKm < 1) {
        return '${distanceInMeters.toStringAsFixed(0)} m away';
      } else {
        return '${distanceInKm.toStringAsFixed(1)} km away';
      }
    } catch (e) {
      print('Error calculating distance: $e');
      return 'Distance unknown';
    }
  }

  Future<void> _loadGames() async {
    setState(() => _isLoading = true);
    
    // Load created games from local storage
    List<dynamic> myCreatedGames = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('ps_userId');
      final createdGamesJson = prefs.getString('ps_created_games');
      if (createdGamesJson != null) {
        myCreatedGames = jsonDecode(createdGamesJson) as List<dynamic>;
        // Mark as my games
        myCreatedGames = myCreatedGames.map((game) {
          game['isMyGame'] = true;
          return game;
        }).toList();
      }
      
      _socketService.getGames((games) {
        if (mounted) {
          // Combine my games first, then other games
          final allGames = [...myCreatedGames, ...games];
          // Remove duplicates by ID
          final uniqueGames = <String, dynamic>{};
          for (var game in allGames) {
            if (game['id'] != null) {
              uniqueGames[game['id'].toString()] = game;
            }
          }
          
          setState(() {
            _games = uniqueGames.values.toList();
            _applyFilters();
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      print('Error loading created games: $e');
      // No fallback to demo games - show empty state instead
      if (mounted) {
        setState(() {
          _games = [];
          _applyFilters();
          _isLoading = false;
        });
      }
    }
    
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredGames = _games.where((game) {
        // Apply category filter
        bool categoryMatch = _filter == 'all' || 
            (game['category']?.toString().toLowerCase() == _filter.toLowerCase()) ||
            (game['type']?.toString().toLowerCase() == _filter.toLowerCase());
        
        // Apply search filter
        bool searchMatch = _searchQuery.isEmpty ||
            (game['name']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (game['location']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        
        return categoryMatch && searchMatch;
      }).map((game) {
        // Calculate distance for games with lat/lng
        final gameLat = (game['lat'] as num?)?.toDouble();
        final gameLng = (game['lng'] as num?)?.toDouble();
        if (gameLat != null && gameLng != null) {
          game['calculatedDistance'] = _calculateDistance(gameLat, gameLng);
        } else {
          game['calculatedDistance'] = null;
        }
        return game;
      }).toList();
      
      // Sort by distance if location is available
      if (_currentPosition != null) {
        _filteredGames.sort((a, b) {
          final aLat = (a['lat'] as num?)?.toDouble();
          final aLng = (a['lng'] as num?)?.toDouble();
          final bLat = (b['lat'] as num?)?.toDouble();
          final bLng = (b['lng'] as num?)?.toDouble();
          
          if (aLat == null || aLng == null) return 1;
          if (bLat == null || bLng == null) return -1;
          
          final aDistance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            aLat,
            aLng,
          );
          final bDistance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            bLat,
            bLng,
          );
          
          return aDistance.compareTo(bDistance);
        });
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Container(
          color: PSColors.bg,
          child: Column(
        children: [
          _buildStickyHeader(),
          Expanded(
            child: RefreshWrapper(
              onRefresh: _loadGames,
              child: ListView(
                controller: _scrollController,
                cacheExtent: 500,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                children: [
                  _buildQuickActions(),
                  const SizedBox(height: 12),
                  _buildCategoryChips(),
                  const SizedBox(height: 18),
                  _buildMyGamesSection(),
                  const SizedBox(height: 18),
                  _buildRisingAthletesSection(),
                  const SizedBox(height: 18),
                  _buildSectionLabel('📍 GAMES NEAR YOU', PSColors.gold),
                  const SizedBox(height: 10),
                  _isLoading
                      ? const GameCardSkeleton()
                      : _buildGamesGrid(),
                  const SizedBox(height: 18),
                  _buildSectionLabel('🎉 UPCOMING EVENTS', PSColors.lilac),
                  const SizedBox(height: 10),
                  _buildEventsList(),
                ],
              ),
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildStickyHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 12),
      decoration: BoxDecoration(
        color: PSColors.bg.withOpacity(0.96),
        border: const Border(bottom: BorderSide(color: PSColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            text: TextSpan(
              style: PSText.brand,
              children: const [
                TextSpan(text: 'Play'),
                TextSpan(text: 'Spot', style: TextStyle(color: PSColors.goldBright)),
                TextSpan(text: '.', style: TextStyle(color: PSColors.fire)),
              ],
            ),
          ),
          Row(
            children: [
              ValueListenableBuilder<List<NotificationItem>>(
                valueListenable: NotificationService().items,
                builder: (context, items, _) {
                  final unread = items.where((n) => !n.read).length;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        onPressed: widget.onNotificationsTap,
                        icon: const Text('🔔', style: TextStyle(fontSize: 20)),
                      ),
                      if (unread > 0)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            constraints: const BoxConstraints(minWidth: 16),
                            decoration: const BoxDecoration(
                              color: PSColors.fire,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unread > 9 ? '9+' : '$unread',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              IconButton(
                onPressed: widget.onFriendsTap,
                icon: const Text('👥', style: TextStyle(fontSize: 20)),
                tooltip: 'Friends',
              ),
              GestureDetector(
                onTap: widget.onProfileTap,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: PSColors.surface2,
                    shape: BoxShape.circle,
                    border: Border.all(color: PSColors.border, width: 2),
                  ),
                  child: const Center(child: Text('🙂', style: TextStyle(fontSize: 17))),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(child: _quickActionBtn('🗺️', 'MAP', widget.onMapTap)),
        const SizedBox(width: 8),
        Expanded(child: _quickActionBtn('🎉', 'EVENTS', widget.onEventsTap)),
        const SizedBox(width: 8),
        Expanded(child: _quickActionBtn('🏆', 'RANKS', widget.onLeaderboardTap)),
      ],
    );
  }

  Widget _buildCategoryChips() {
    return Column(
      children: [
        // Search bar
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search games by name or location...',
              hintStyle: TextStyle(color: PSColors.inkDim, fontSize: 14),
              filled: true,
              fillColor: PSColors.surface2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(Icons.search, color: PSColors.gold),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: PSColors.inkDim),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
            ),
            style: const TextStyle(color: Color(0xFFFFF8F0), fontSize: 14),
          ),
        ),
        // Category chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((category) {
              final isSelected = _filter == category['id'];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _filter = category['id']!);
                    _applyFilters();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                      ? const Color(0xFFF5A623)
                      : const Color(0xFF1A0E00),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : const Color(0xFFF5A623),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category['emoji']!,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      category['label']!,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF140A00)
                            : const Color(0xFFFFF8F0),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _quickActionBtn(String icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
        decoration: BoxDecoration(
          gradient: PSGradients.quickAction,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PSColors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [PSColors.gold.withOpacity(0.20), PSColors.gold.withOpacity(0.08)],
                ),
              ),
              child: Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(height: 5),
            Text(label, style: PSText.navLabel.copyWith(color: PSColors.inkDim, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'SpaceMono',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: color,
      ),
    );
  }

  Widget _buildMyGamesSection() {
    final myGames = _games.where((game) => game['isMyGame'] == true).toList();
    
    if (myGames.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionLabel('⭐ MY HOSTED GAMES', PSColors.fire),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: PSColors.fire.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: PSColors.fire.withOpacity(0.5)),
              ),
              child: Text(
                '${myGames.length} Active',
                style: TextStyle(
                  color: PSColors.fire,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: myGames.length,
            itemBuilder: (context, index) {
              final game = myGames[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 12),
                child: _GameCard(game: game, isListView: true),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRisingAthletesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.trending_up, color: Color(0xFFF5A623), size: 16),
            const SizedBox(width: 6),
            const Text(
              'FEATURED ATHLETES',
              style: TextStyle(
                color: Color(0xFFF5A623),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Demo accounts for testing',
          style: TextStyle(
            color: Color(0x8CFFF8F0),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: mockPlayers.length,
            itemBuilder: (context, index) {
              final player = mockPlayers[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlayerProfileScreen(player: player, isOwnProfile: false),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: _getAvatarUrl(player.id),
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => _buildAvatarFallback(player),
                              errorWidget: (context, url, error) => _buildAvatarFallback(player),
                            ),
                          ),
                          if (player.isVerified)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0E0700),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.verified,
                                  color: Color(0xFFF5A623),
                                  size: 16,
                                ),
                              ),
                            ),
                          if (player.isLive)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'LIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        player.name,
                        style: const TextStyle(
                          color: Color(0xFFFFF8F0),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_formatCount(player.followerCount)} followers',
                        style: TextStyle(
                          color: PSColors.inkDim,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  String _getAvatarUrl(String playerId) {
    switch (playerId) {
      case '1':
        return 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face';
      case '2':
        return 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&h=150&fit=crop&crop=face';
      case '3':
        return 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&h=150&fit=crop&crop=face';
      case '4':
        return 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face';
      case '5':
        return 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face';
      default:
        return 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face';
    }
  }

  Widget _buildAvatarFallback(PlayerModel player) {
    final initials = player.name.split(' ').map((n) => n[0]).take(2).join();
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Color(0xFFF5A623),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildGamesGrid() {
    if (_filteredGames.isEmpty) {
      return _buildEmptyState();
    }

    if (_isGrid) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _filteredGames.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.82,
        ),
        itemBuilder: (context, i) => _GameCard(game: _filteredGames[i]),
      );
    }
    return Column(
      children: [
        for (final g in _filteredGames)
          Padding(padding: const EdgeInsets.only(bottom: 10), child: _GameCard(game: g, isListView: true)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_esports,
            size: 64,
            color: PSColors.gold.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No games near you yet',
            style: TextStyle(
              color: PSColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to host one!',
            style: TextStyle(
              color: PSColors.inkDim,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.onHostTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: PSColors.gold,
              foregroundColor: const Color(0xFF140A00),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Host a Game',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    return Column(
      children: [
        for (final e in demoEvents)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _EventCard(event: e),
          ),
      ],
    );
  }
}

class _GameCard extends StatelessWidget {
  final dynamic game;
  final bool isListView;
  const _GameCard({required this.game, this.isListView = false});

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

  @override
  Widget build(BuildContext context) {
    final isMyGame = game['isMyGame'] == true;
    final sport = game['sport'] ?? 'unknown';
    final sportEmoji = _getSportEmoji(sport);
    final title = game['title'] ?? game['name'] ?? 'Game';
    // Use calculated distance if available, otherwise fallback to location
    final distanceLabel = game['calculatedDistance'] as String? ?? 
                         (game['location'] ?? 'Unknown location');
    final players = (game['players'] as List?)?.length ?? game['playerCount'] ?? 0;
    final maxPlayers = game['maxPlayers'] ?? 10;
    final isLive = game['isLive'] == true;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMyGame ? PSColors.fire.withOpacity(0.1) : PSColors.surface2,
        borderRadius: BorderRadius.circular(PSRadius.lg),
        border: Border.all(
          color: isMyGame ? PSColors.fire : PSColors.border,
          width: isMyGame ? 2 : 1,
        ),
      ),
      child: isListView
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Text(sportEmoji, style: const TextStyle(fontSize: 28)),
                    if (isMyGame)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Icon(Icons.star, color: PSColors.fire, size: 12),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(child: _cardBody(context, title, distanceLabel, players, maxPlayers, isLive)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Text(sportEmoji, style: const TextStyle(fontSize: 28)),
                    if (isMyGame)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Icon(Icons.star, color: PSColors.fire, size: 12),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(child: _cardBody(context, title, distanceLabel, players, maxPlayers, isLive)),
              ],
            ),
    );
  }

  Widget _cardBody(BuildContext context, String title, String location, int players, int maxPlayers, bool isLive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w700, fontSize: 13, color: PSColors.ink),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            if (isLive)
              Container(
                margin: const EdgeInsets.only(right: 5),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: PSColors.fire, shape: BoxShape.circle),
              ),
            Expanded(
              child: Text(
                location,
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 10,
                  color: isLive ? PSColors.fire : PSColors.inkMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$players/$maxPlayers players',
          style: const TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 11, color: PSColors.inkDim),
        ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  final PSEvent event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PSColors.surface2,
        borderRadius: BorderRadius.circular(PSRadius.lg),
        border: Border.all(color: PSColors.border),
      ),
      child: Row(
        children: [
          Text(event.emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: const TextStyle(fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w700, fontSize: 14, color: PSColors.ink)),
                const SizedBox(height: 3),
                Text('${event.dateLabel} · ${event.attendeeCount} going', style: const TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 12, color: PSColors.inkDim)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
