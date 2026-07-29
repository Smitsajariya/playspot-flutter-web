import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:math';
import '../socket_service.dart';
import '../theme/playspot_theme.dart';
import '../services/presence_service.dart';
import '../services/weather_service.dart';
import '../services/waitlist_service.dart';
import '../services/geocoding_service.dart';
import '../widgets/game_pin_marker.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final SocketService _socketService = SocketService();
  final MapController _mapController = MapController();
  
  List<dynamic> _games = [];
  LatLng? _currentLocation;
  LatLng? _savedLocation; // User's saved location
  String? _savedLocationAddress;
  String? _savedGameType; // User's saved game type
  LatLng? _selectedLocationForSave; // Currently selected location to save
  String? _selectedLocationForSaveAddress;
  String? _myGameId;
  bool _isLoading = false;
  String? _userPhotoUrl;
  String? _userName;
  bool _showOnMap = true;
  String? _selectedSportFilter; // null = "All"
  String _searchQuery = '';
  DateTime? _selectedDateFilter; // null = "All" dates
  bool _showListView = false;
  double _zoom = 14;
  String _mySkillLevel = 'intermediate';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    await _loadUserProfile();
    await _loadSavedLocation();
    await _getCurrentLocation();
    _loadGames();
    _socketService.connect();
    _socketService.onGamesUpdate((games) {
      if (mounted) {
        setState(() => _games = games);
      }
    });
    _socketService.onNewGameCreated((newGame) {
      if (mounted) {
        setState(() {
          _games.add(newGame);
        });
      }
    });

    // Poll every 8 seconds for real-time updates (matching HTML version)
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 8));
      if (mounted) {
        _loadGames();
        return true;
      }
      return false;
    });

    // Timeout after 5 seconds - just stop loading, show empty state
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    });
  }

  Future<void> _loadGames() async {
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
          
          setState(() => _games = uniqueGames.values.toList());
        }
      });
    } catch (e) {
      print('Error loading created games: $e');
      _socketService.getGames((games) {
        if (mounted) {
          setState(() => _games = games);
        }
      });
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('ps_profile');
      if (profileJson != null) {
        final profile = jsonDecode(profileJson);
        setState(() {
          _userPhotoUrl = profile['photoUrl'];
          _userName = profile['name'];
          _showOnMap = profile['showOnMap'] ?? true;
          _mySkillLevel = profile['skillLevel'] ?? 'intermediate';
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<void> _loadSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLat = prefs.getDouble('ps_saved_location_lat');
      final savedLng = prefs.getDouble('ps_saved_location_lng');
      final savedAddress = prefs.getString('ps_saved_location_address');
      final savedGameType = prefs.getString('ps_saved_game_type');
      
      if (savedLat != null && savedLng != null) {
        setState(() {
          _savedLocation = LatLng(savedLat, savedLng);
          _savedLocationAddress = savedAddress;
          _savedGameType = savedGameType;
        });
      }
    } catch (e) {
      print('Error loading saved location: $e');
    }
  }

  Future<void> _saveCurrentLocation() async {
    if (_selectedLocationForSave == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tap on the map to select a location first'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    
    // Show game type selection dialog
    final gameTypes = ['All', 'Sports', 'Nightlife', 'Fitness', 'Cultural', 'Food', 'Custom'];
    String? selectedGameType = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Game Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: gameTypes.map((type) => ListTile(
            title: Text(type),
            onTap: () => Navigator.pop(context, type),
          )).toList(),
        ),
      ),
    );
    
    if (selectedGameType == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationToSave = _selectedLocationForSave!;
      final addressToSave = _selectedLocationForSaveAddress ?? 'Selected location';
      
      await prefs.setDouble('ps_saved_location_lat', locationToSave.latitude);
      await prefs.setDouble('ps_saved_location_lng', locationToSave.longitude);
      await prefs.setString('ps_saved_location_address', addressToSave);
      await prefs.setString('ps_saved_game_type', selectedGameType);
      
      setState(() {
        _savedLocation = locationToSave;
        _savedLocationAddress = addressToSave;
        _savedGameType = selectedGameType;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location saved for $selectedGameType: $addressToSave'),
            backgroundColor: PSColors.gold,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error saving location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save location'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      if (_currentLocation != null) {
        _mapController.move(_currentLocation!, 14);
      }
    } catch (e) {
      print('Error getting location: $e');
    }
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
    return names[sport] ?? 'Other';
  }

  /// Sport -> count of games currently on the map, in first-seen order
  /// so the filter row doesn't reshuffle every time games update.
  Map<String, int> _sportCounts() {
    final counts = <String, int>{};
    for (final game in _games) {
      final sport = (game['sport'] as String?) ?? 'unknown';
      counts[sport] = (counts[sport] ?? 0) + 1;
    }
    return counts;
  }

  List<dynamic> get _filteredGames {
    var list = _games;
    if (_selectedSportFilter != null) {
      list = list.where((g) => (g['sport'] as String?) == _selectedSportFilter).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((g) {
        final title = (g['title'] as String? ?? '').toLowerCase();
        final location = (g['location'] as String? ?? '').toLowerCase();
        return title.contains(q) || location.contains(q);
      }).toList();
    }
    if (_selectedDateFilter != null) {
      list = list.where((g) => _matchesDate(g, _selectedDateFilter!)).toList();
    }
    return list;
  }

  /// Games without a scheduled date (older/manually-created games) always
  /// match, so they don't silently disappear once the date strip is used.
  bool _matchesDate(dynamic game, DateTime day) {
    final raw = game['scheduledFor'] as String?;
    if (raw == null || raw.isEmpty) return true;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return true;
    return parsed.year == day.year && parsed.month == day.month && parsed.day == day.day;
  }

  /// Next 5 days starting today, for the date-strip chips.
  List<DateTime> get _dateStripDays {
    final today = DateTime.now();
    return List.generate(5, (i) => DateTime(today.year, today.month, today.day + i));
  }

  String _dateChipLabel(DateTime day, int index) {
    if (index == 0) return 'Today';
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[day.weekday - 1];
  }

  Future<void> _launchAttributionUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Error launching attribution url: $e');
    }
  }

  /// Groups nearby games into clusters so overlapping markers collapse into
  /// a single badge with a count, instead of stacking illegibly. The
  /// clustering radius shrinks as you zoom in (games spread back out),
  /// which is the same "cluster only when zoomed out" behavior Nomadtable
  /// and most map apps use. No new dependency needed — this is a simple
  /// grid/greedy clustering pass over `flutter_map`'s existing MarkerLayer,
  /// since `flutter_map_marker_cluster` isn't in pubspec.yaml.
  List<_GameCluster> _buildClusters(List<dynamic> games) {
    // Degrees-per-cluster roughly halves every couple of zoom levels.
    final threshold = (0.09 * pow(2, (13 - _zoom))).clamp(0.0006, 0.6).toDouble();
    final clusters = <_GameCluster>[];

    for (final game in games) {
      final lat = game['lat'] as double?;
      final lng = game['lng'] as double?;
      if (lat == null || lng == null) continue;

      _GameCluster? target;
      for (final c in clusters) {
        if ((c.center.latitude - lat).abs() < threshold &&
            (c.center.longitude - lng).abs() < threshold) {
          target = c;
          break;
        }
      }

      if (target != null) {
        target.games.add(game);
        // Re-average the center as games join, so the cluster settles
        // roughly in the middle of its members rather than snapping to
        // whichever game arrived first.
        final avgLat = target.games.map((g) => g['lat'] as double).reduce((a, b) => a + b) / target.games.length;
        final avgLng = target.games.map((g) => g['lng'] as double).reduce((a, b) => a + b) / target.games.length;
        target.center = LatLng(avgLat, avgLng);
      } else {
        clusters.add(_GameCluster(center: LatLng(lat, lng), games: [game]));
      }
    }

    return clusters;
  }

  void _showProfileCard(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A0C00),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: _userPhotoUrl != null
                      ? NetworkImage(_userPhotoUrl!)
                      : null,
                  child: _userPhotoUrl == null
                      ? const Icon(Icons.person, color: Color(0xFFF5A623))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName ?? 'You',
                        style: const TextStyle(
                          color: Color(0xFFFFF8F0),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '@your_username',
                        style: const TextStyle(
                          color: Color(0x8CFFF8F0),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: const [
                Chip(
                  label: Text('Football', style: TextStyle(fontSize: 12)),
                  backgroundColor: Color(0xFFF5A623),
                ),
                Chip(
                  label: Text('Running', style: TextStyle(fontSize: 12)),
                  backgroundColor: Color(0xFF9C27B0),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '1.2K followers',
              style: TextStyle(
                color: Color(0x8CFFF8F0),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5A623),
                      foregroundColor: const Color(0xFF140A00),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Edit Profile'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// The original per-game marker (sport emoji + "my game" star + host
  /// avatar badge) — unchanged, just pulled out so clustering can reuse it
  /// for clusters of size 1.
  Widget _singleGameMarker(dynamic game) {
    final sport = game['sport'] ?? 'unknown';
    final sportEmoji = _getSportEmoji(sport);
    final isMyGame = game['isMyGame'] == true || game['id']?.toString() == _myGameId;
    final hostPhoto = game['photoUrl'] as String?;
    // Handle players field - it might be a List or an int
    final players = game['players'] is List 
        ? game['players'] as List<dynamic>
        : <dynamic>[];
    final host = players.isNotEmpty ? players[0] as Map<String, dynamic>? : null;
    final hostPhotoUrl = host?['photoUrl'] as String?;

    return GestureDetector(
      onTap: () => _showGameBottomSheet(game),
      child: GamePinMarker(
        photoUrl: hostPhotoUrl ?? hostPhoto,
        sportEmoji: sportEmoji,
        isMine: isMyGame,
        size: 46,
      ),
    );
  }

  /// Cluster badge — dominant sport's emoji plus a count bubble. Tapping
  /// zooms in on the cluster; once zoomed in far enough that the cluster
  /// would only contain 1-2 games, they naturally split back into
  /// individual markers instead (handled by `_buildClusters`'s shrinking
  /// threshold), so this also opens a quick list as a fallback for dense
  /// areas that don't fully separate.
  Widget _clusterMarker(_GameCluster cluster) {
    final sportCounts = <String, int>{};
    for (final g in cluster.games) {
      final s = (g['sport'] as String?) ?? 'unknown';
      sportCounts[s] = (sportCounts[s] ?? 0) + 1;
    }
    final dominantSport = sportCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    return GestureDetector(
      onTap: () {
        if (_zoom < 17) {
          _mapController.move(cluster.center, _zoom + 2.5);
        } else {
          _showClusterSheet(cluster);
        }
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: PSColors.copper,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, spreadRadius: 1)],
        ),
        child: Stack(
          children: [
            Center(child: Text(_getSportEmoji(dominantSport), style: const TextStyle(fontSize: 22))),
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: const BoxDecoration(color: PSColors.fire, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                child: Center(
                  child: Text(
                    '${cluster.games.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClusterSheet(_GameCluster cluster) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A0C00),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${cluster.games.length} games here', style: PSText.screenTitle),
              const SizedBox(height: 12),
              ...cluster.games.map((g) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildGameListCard(g),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _showGameBottomSheet(Map<String, dynamic> game) {
    final sport = game['sport'] ?? 'unknown';
    final sportEmoji = _getSportEmoji(sport);
    final title = game['title'] ?? 'Game';
    // Handle players field - it might be a List or an int
    final players = game['players'] is List 
        ? game['players'] as List<dynamic>
        : <dynamic>[];
    final maxPlayersFallback = (game['playerCount'] as int?) ?? players.length;
    final maxPlayers = game['maxPlayers'] ?? 10;
    final rosterCount = players.isNotEmpty ? players.length : maxPlayersFallback;
    final isFull = rosterCount >= maxPlayers;
    final lat = game['lat'] as double?;
    final lng = game['lng'] as double?;
    final gameId = game['id']?.toString();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A0C00),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(sportEmoji, style: const TextStyle(fontSize: 36)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(color: Color(0xFFFFF8F0), fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$rosterCount/$maxPlayers players · ${_getSportName(sport)}',
                    style: const TextStyle(color: Color(0x8CFFF8F0), fontSize: 14),
                  ),
                  if (lat != null && lng != null) ...[
                    const SizedBox(height: 12),
                    _buildWeatherRow(lat, lng),
                  ],
                  const SizedBox(height: 24),
                  if (isFull)
                    _buildWaitlistButton(gameId, title, setSheetState)
                  else
                    ElevatedButton(
                      onPressed: () => _handleJoinTap(sheetContext, game),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5A623),
                        foregroundColor: const Color(0xFF140A00),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Join Game'),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Async weather chip — fetched on demand per open sheet (not preloaded
  /// for every marker) so the map itself stays fast. Fails soft: shows
  /// nothing if the lookup errors or the venue has no coordinates.
  Widget _buildWeatherRow(double lat, double lng) {
    return FutureBuilder(
      future: WeatherService.fetch(lat, lng),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 20,
            child: Row(children: [
              SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: PSColors.gold)),
              SizedBox(width: 8),
              Text('Checking weather...', style: TextStyle(color: Color(0x8CFFF8F0), fontSize: 12)),
            ]),
          );
        }
        final weather = snapshot.data;
        if (weather == null) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: weather.isRainRisk ? const Color(0x1AFF4D1C) : const Color(0x1AC8FF00),
            borderRadius: BorderRadius.circular(PSRadius.sm),
            border: Border.all(color: weather.isRainRisk ? PSColors.fire.withOpacity(0.4) : PSColors.volt.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(weather.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                '${weather.label} · ${weather.tempC.round()}°C'
                '${weather.isRainRisk ? ' · ${weather.precipProbability}% rain risk' : ''}',
                style: TextStyle(
                  color: weather.isRainRisk ? PSColors.fire : PSColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWaitlistButton(String? gameId, String title, void Function(void Function()) setSheetState) {
    if (gameId == null) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF241200),
          foregroundColor: const Color(0x8CFFF8F0),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Game Full'),
      );
    }
    return FutureBuilder<bool>(
      future: WaitlistService.isWaitlisted(gameId),
      builder: (context, snapshot) {
        final onWaitlist = snapshot.data ?? false;
        return ElevatedButton.icon(
          onPressed: onWaitlist
              ? null
              : () async {
                  await WaitlistService.join(gameId);
                  setSheetState(() {});
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("You're on the waitlist for $title — we'll auto-join you if a spot opens."),
                        backgroundColor: PSColors.gold,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
          icon: Icon(onWaitlist ? Icons.check_circle : Icons.hourglass_top, size: 18),
          style: ElevatedButton.styleFrom(
            backgroundColor: onWaitlist ? const Color(0xFF241200) : PSColors.surface2,
            foregroundColor: onWaitlist ? PSColors.volt : PSColors.ink,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: PSColors.gold.withOpacity(0.4))),
          ),
          label: Text(onWaitlist ? "You're on the waitlist" : 'Game Full — Join Waitlist'),
        );
      },
    );
  }

  static const List<String> _skillOrder = ['beginner', 'intermediate', 'advanced'];

  /// Warns the user before joining a game pitched above their own skill
  /// level (from the profile's "My Skill Level" chip). Games marked "any"
  /// or at/below the user's level join immediately, same as before.
  Future<void> _handleJoinTap(BuildContext sheetContext, Map<String, dynamic> game) async {
    final gameSkill = (game['skillLevel'] as String?)?.toLowerCase() ?? 'any';
    final myIndex = _skillOrder.indexOf(_mySkillLevel.toLowerCase());
    final gameIndex = _skillOrder.indexOf(gameSkill);

    final mismatch = gameSkill != 'any' && gameIndex > myIndex && myIndex != -1;

    if (mismatch) {
      final proceed = await showDialog<bool>(
        context: sheetContext,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF1A0C00),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Skill level mismatch', style: TextStyle(color: Color(0xFFFFF8F0))),
          content: Text(
            "This game is ${_capitalize(gameSkill)}, you're marked ${_capitalize(_mySkillLevel)} — join anyway?",
            style: const TextStyle(color: Color(0x8CFFF8F0)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel', style: TextStyle(color: Color(0x8CFFF8F0))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Join Anyway', style: TextStyle(color: PSColors.gold)),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    await _joinGame(game);
    if (sheetContext.mounted) Navigator.pop(sheetContext);
  }

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  Future<void> _joinGame(Map<String, dynamic> game) async {
    final gameId = game['id']?.toString();
    if (gameId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('ps_userId');
      final profileJson = prefs.getString('ps_profile');
      final name = profileJson != null ? (jsonDecode(profileJson)['name'] as String?) ?? 'Player' : 'Player';

      _socketService.joinGame(gameId, {'userId': userId ?? '', 'name': name}, (response) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response is Map && response['ok'] == false
                  ? (response['error']?.toString() ?? "Couldn't join — try again")
                  : "You're in — see you there!"),
              backgroundColor: PSColors.gold,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    } catch (e) {
      print('Join game error: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0700),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? const LatLng(20.5937, 78.9629),
              initialZoom: _currentLocation != null ? 14 : 5,
              onTap: (tapPosition, point) async {
                // Select this location for saving
                setState(() {
                  _selectedLocationForSave = point;
                });
                // Reverse geocode to get address
                List<Placemark> placemarks = await placemarkFromCoordinates(
                  point.latitude,
                  point.longitude,
                );
                
                String address = 'Selected location';
                if (placemarks.isNotEmpty) {
                  Placemark place = placemarks.first;
                  List<String> parts = [];
                  if (place.street?.isNotEmpty == true) parts.add(place.street!);
                  if (place.subLocality?.isNotEmpty == true) parts.add(place.subLocality!);
                  if (place.locality?.isNotEmpty == true) parts.add(place.locality!);
                  if (place.administrativeArea?.isNotEmpty == true) parts.add(place.administrativeArea!);
                  if (place.postalCode?.isNotEmpty == true) parts.add(place.postalCode!);
                  if (place.country?.isNotEmpty == true) parts.add(place.country!);
                  if (parts.isNotEmpty) {
                    address = parts.join(', ');
                  }
                }
                
                setState(() {
                  _selectedLocationForSaveAddress = address;
                });
              },
              onPositionChanged: (position, hasGesture) {
                final z = position.zoom;
                if (z != null && (z - _zoom).abs() > 0.05) {
                  setState(() => _zoom = z);
                }
              },
            ),
            children: [
              TileLayer(
                // OpenStreetMap standard tiles — colorful, Google Maps-like style
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.playspot_flutter',
                maxZoom: 19,
              ),
              // Game markers — clustered when several games sit close
              // together at the current zoom level (see `_buildClusters`).
              MarkerLayer(
                markers: _buildClusters(_filteredGames).map((cluster) {
                  final center = cluster.center;
                  if (cluster.games.length == 1) {
                    final game = cluster.games.first;
                    return Marker(
                      point: center,
                      width: 56,
                      height: 56,
                      child: _singleGameMarker(game),
                    );
                  }
                  return Marker(
                    point: center,
                    width: 60,
                    height: 60,
                    child: _clusterMarker(cluster),
                  );
                }).toList(),
              ),
              // Current location marker with avatar
              if (_currentLocation != null && _showOnMap)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!,
                      width: 60,
                      height: 60,
                      child: GestureDetector(
                        onTap: () => _showProfileCard(context),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFF5A623), width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF5A623).withOpacity(0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(_userPhotoUrl!),
                                )
                              : CircleAvatar(
                                  backgroundColor: const Color(0xFFF5A623),
                                  child: Text(
                                    (_userName != null && _userName!.trim().isNotEmpty)
                                        ? _userName!.trim()[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                const SizedBox.shrink(),
              // Selected location for saving marker
              if (_selectedLocationForSave != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocationForSave!,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.6),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          // Loading indicator
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFF5A623)),
            ),

          // Full-screen list overlay — toggled via the list/map button.
          // Reuses the same filtered games + tap handler as the map markers.
          if (_showListView) _buildListOverlay(),

          // Back button — always visible, top-left, above the map
          Positioned(
            top: 12,
            left: 12,
            child: GestureDetector(
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0E0700).withOpacity(0.85),
                  border: Border.all(color: const Color(0x33FFC850), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFFFFF8F0),
                  size: 22,
                ),
              ),
            ),
          ),

          // Map <-> List toggle — top-right, mirrors the back button
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: () => setState(() => _showListView = !_showListView),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0E0700).withOpacity(0.85),
                  border: Border.all(color: const Color(0x33FFC850), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  _showListView ? Icons.map_outlined : Icons.list,
                  color: const Color(0xFFFFF8F0),
                  size: 22,
                ),
              ),
            ),
          ),

          // Search bar — filters by game title or location text
          Positioned(
            top: 64,
            left: 12,
            right: 64,
            child: _buildSearchBar(),
          ),

          // Sport filter chips — horizontally scrollable, live counts from _games
          Positioned(
            top: 114,
            left: 0,
            right: 0,
            child: _buildFilterChips(),
          ),

          // Date strip — Today + next 4 days
          Positioned(
            top: 162,
            left: 0,
            right: 0,
            child: _buildDateStrip(),
          ),

          // "Players near you" pill — client-side estimate from the games
          // already loaded (see PresenceService for the "needs real backend
          // presence" caveat).
          if (!_showListView)
            Positioned(
              top: 226,
              right: 12,
              child: _buildPresencePill(),
            ),

          // Map data attribution — required by OpenStreetMap/CARTO usage terms
          if (!_showListView)
            Positioned(
              left: 8,
              bottom: 8,
              child: _buildAttribution(),
            ),

          // Save location button - bottom right
          if (!_showListView)
            Positioned(
              right: 12,
              bottom: 80,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: _savedLocation != null ? PSColors.gold : const Color(0xFF0E0700),
                foregroundColor: _savedLocation != null ? const Color(0xFF140A00) : PSColors.gold,
                onPressed: _saveCurrentLocation,
                child: Icon(
                  _savedLocation != null ? Icons.bookmark : Icons.bookmark_border,
                  size: 20,
                ),
              ),
            ),

          // Connection error debug text — temporary diagnostic
          if (SocketService.lastConnectionError != null)
            Positioned(
              bottom: 40,
              left: 8,
              right: 8,
              child: Text(
                'Connection error: ${SocketService.lastConnectionError}',
                style: const TextStyle(color: Colors.red, fontSize: 9),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: PSColors.bg.withOpacity(0.9),
        borderRadius: BorderRadius.circular(PSRadius.full),
        border: Border.all(color: PSColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: PSColors.gold, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: PSColors.ink, fontSize: 13),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search area, venue or game...',
                hintStyle: TextStyle(color: PSColors.inkDim, fontSize: 13),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: const Icon(Icons.clear, color: PSColors.inkDim, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _buildDateStrip() {
    final days = _dateStripDays;
    return SizedBox(
      // Was 44 — too short for chips with a day name + day number stacked
      // on two lines, causing a ~5px bottom overflow on every date chip.
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _dateChip(label: 'All', isSelected: _selectedDateFilter == null, onTap: () {
            setState(() => _selectedDateFilter = null);
          }),
          const SizedBox(width: 8),
          for (int i = 0; i < days.length; i++) ...[
            _dateChip(
              label: _dateChipLabel(days[i], i),
              subLabel: '${days[i].day}',
              isSelected: _selectedDateFilter != null &&
                  _selectedDateFilter!.year == days[i].year &&
                  _selectedDateFilter!.month == days[i].month &&
                  _selectedDateFilter!.day == days[i].day,
              onTap: () => setState(() => _selectedDateFilter = days[i]),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _dateChip({
    required String label,
    String? subLabel,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? PSColors.gold : PSColors.bg.withOpacity(0.85),
          borderRadius: BorderRadius.circular(PSRadius.sm),
          border: Border.all(color: isSelected ? PSColors.gold : PSColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF140A00) : PSColors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subLabel != null)
              Text(
                subLabel,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF140A00) : PSColors.inkDim,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildListOverlay() {
    final games = _filteredGames;
    return Positioned.fill(
      child: Container(
        color: const Color(0xFF0E0700),
        padding: const EdgeInsets.fromLTRB(12, 228, 12, 12),
        child: games.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.event_busy, size: 48, color: PSColors.inkMuted),
                    const SizedBox(height: 12),
                    Text(
                      'No games match your filters',
                      style: PSText.bodyDim,
                    ),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: games.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _buildGameListCard(games[i]),
              ),
      ),
    );
  }

  Widget _buildGameListCard(dynamic game) {
    final sport = game['sport'] ?? 'unknown';
    final title = game['title'] ?? 'Game';
    final location = (game['location'] as String?) ?? '';
    final players = (game['players'] as List<dynamic>? ?? []).length;
    final maxPlayers = game['maxPlayers'] ?? 10;
    final isMyGame = game['isMyGame'] == true;

    return GestureDetector(
      onTap: () => _showGameBottomSheet(game),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: PSColors.surface,
          borderRadius: BorderRadius.circular(PSRadius.md),
          border: Border.all(
            color: isMyGame ? const Color(0xFFFF6B6B) : PSColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isMyGame ? const Color(0xFFFF6B6B) : PSColors.gold,
              ),
              child: Center(
                child: Text(_getSportEmoji(sport), style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(color: PSColors.ink, fontSize: 15, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  if (location.isNotEmpty)
                    Text(location, style: PSText.bodyDim, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('$players/$maxPlayers players', style: const TextStyle(color: PSColors.inkMuted, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: PSColors.inkDim),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final counts = _sportCounts();
    final totalCount = _games.length;
    // Preserve first-seen order of sports so the row doesn't jump around.
    final sportsPresent = counts.keys.toList();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _filterChip(
            label: 'All',
            emoji: null,
            count: totalCount,
            isSelected: _selectedSportFilter == null,
            onTap: () => setState(() => _selectedSportFilter = null),
          ),
          const SizedBox(width: 8),
          for (final sport in sportsPresent) ...[
            _filterChip(
              label: _getSportName(sport),
              emoji: _getSportEmoji(sport),
              count: counts[sport] ?? 0,
              isSelected: _selectedSportFilter == sport,
              onTap: () => setState(() {
                _selectedSportFilter = _selectedSportFilter == sport ? null : sport;
              }),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required String? emoji,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? PSColors.gold : PSColors.bg.withOpacity(0.85),
          borderRadius: BorderRadius.circular(PSRadius.full),
          border: Border.all(
            color: isSelected ? PSColors.gold : PSColors.border,
            width: 1,
          ),
          boxShadow: isSelected ? PSShadows.glowGoldSm : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
            ],
            Text(
              '$label ($count)',
              style: TextStyle(
                color: isSelected ? const Color(0xFF140A00) : PSColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresencePill() {
    final estimate = PresenceService.estimate(games: _filteredGames, origin: _currentLocation);
    if (estimate.playerCount == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: PSColors.bg.withOpacity(0.85),
        borderRadius: BorderRadius.circular(PSRadius.full),
        border: Border.all(color: PSColors.gold.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: PSColors.volt, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '${estimate.playerCount} players near you',
            style: const TextStyle(color: PSColors.ink, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildAttribution() {
    return GestureDetector(
      onTap: () => _launchAttributionUrl('https://www.openstreetmap.org/copyright'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: PSColors.bg.withOpacity(0.7),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          '© OpenStreetMap contributors, © CARTO',
          style: TextStyle(color: Color(0x99FFF8F0), fontSize: 9),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

/// Simple mutable cluster bucket used by `_buildClusters` — a center point
/// (re-averaged as games join) plus the raw game payloads it groups.
class _GameCluster {
  LatLng center;
  final List<dynamic> games;
  _GameCluster({required this.center, required this.games});
}
