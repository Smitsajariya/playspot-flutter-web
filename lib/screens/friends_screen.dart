import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/player_model.dart';
import '../services/friends_service.dart';
import '../services/follow_service.dart';
import '../theme/playspot_theme.dart';
import 'player_profile_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  List<String> _myInterests = [];
  String _query = '';
  bool _showSportsMap = false;
  LatLng? _origin;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _getLocation();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('ps_profile');
      if (raw != null) {
        final profile = jsonDecode(raw);
        setState(() {
          _myInterests = (profile['interests'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        });
      }
    } catch (e) {
      debugPrint('FriendsScreen profile load error: $e');
    }
  }

  Future<void> _getLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      if (mounted) setState(() => _origin = LatLng(position.latitude, position.longitude));
    } catch (e) {
      // Fallback so the Sports Map still has something to center on.
      if (mounted) setState(() => _origin = const LatLng(52.5200, 13.4050));
    }
  }

  List<FriendEntry> get _filteredFriends {
    final entries = FriendsService.friendEntries(_myInterests);
    if (_query.trim().isEmpty) return entries;
    final q = _query.trim().toLowerCase();
    return entries.where((e) => e.player.name.toLowerCase().contains(q) || e.player.username.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PSColors.bg,
      appBar: AppBar(
        backgroundColor: PSColors.bg,
        title: const Text('Friends', style: PSText.screenTitle),
        actions: [
          IconButton(
            tooltip: _showSportsMap ? 'List view' : 'Sports map',
            icon: Icon(_showSportsMap ? Icons.list : Icons.map_outlined, color: PSColors.gold),
            onPressed: () => setState(() => _showSportsMap = !_showSportsMap),
          ),
        ],
      ),
      body: _showSportsMap ? _buildSportsMap() : _buildList(),
    );
  }

  Widget _buildList() {
    final friends = _filteredFriends;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(color: PSColors.ink),
            decoration: InputDecoration(
              hintText: 'Search friends...',
              hintStyle: const TextStyle(color: PSColors.inkDim),
              prefixIcon: const Icon(Icons.search, color: PSColors.gold),
              filled: true,
              fillColor: PSColors.surface2,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: friends.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_outline, size: 48, color: PSColors.inkMuted),
                      const SizedBox(height: 12),
                      Text(
                        _query.isEmpty ? 'No friends yet — follow players to see them here' : 'No friends match "$_query"',
                        style: PSText.bodyDim,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: friends.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _friendCard(friends[i]),
                ),
        ),
      ],
    );
  }

  Widget _friendCard(FriendEntry entry) {
    final p = entry.player;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerProfileScreen(player: p))),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: PSColors.surface,
          borderRadius: BorderRadius.circular(PSRadius.md),
          border: Border.all(color: PSColors.border),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage: CachedNetworkImageProvider(p.avatarUrl),
                ),
                if (p.isLive)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: PSColors.fire,
                        shape: BoxShape.circle,
                        border: Border.all(color: PSColors.surface, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(p.name,
                            style: const TextStyle(color: PSColors.ink, fontWeight: FontWeight.w700, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (p.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, size: 14, color: PSColors.gold),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (entry.mutualTags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: entry.mutualTags
                          .map((t) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: PSColors.gold.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(PSRadius.full),
                                  border: Border.all(color: PSColors.gold.withOpacity(0.4)),
                                ),
                                child: Text('🤝 $t', style: const TextStyle(color: PSColors.gold, fontSize: 11, fontWeight: FontWeight.w600)),
                              ))
                          .toList(),
                    )
                  else
                    Text('@${p.username}', style: PSText.bodyDim),
                ],
              ),
            ),
            _followButton(p),
          ],
        ),
      ),
    );
  }

  Widget _followButton(PlayerModel p) {
    final status = FollowService.getStatus(p.id);
    final following = status == FollowStatus.following || (status == FollowStatus.none && p.isFollowing);
    return GestureDetector(
      onTap: () => setState(() {
        if (following) {
          FollowService.removeFollower(p.id);
        } else {
          FollowService.acceptFollowRequest(p.id);
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: following ? PSColors.surface2 : PSColors.gold,
          borderRadius: BorderRadius.circular(PSRadius.full),
          border: Border.all(color: following ? PSColors.border : PSColors.gold),
        ),
        child: Text(
          following ? 'Friends' : 'Add',
          style: TextStyle(
            color: following ? PSColors.ink : const Color(0xFF140A00),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  /// "Which venues/pitches do my friends play at" — Nomadtable-style
  /// friends-world-map, adapted for sports. Pin positions are a
  /// deterministic placeholder (see `FriendsService.pseudoLocation`) until
  /// real venue check-ins exist server-side.
  Widget _buildSportsMap() {
    final origin = _origin ?? const LatLng(52.5200, 13.4050);
    final friends = FriendsService.friends();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: origin, initialZoom: 12),
          children: [
            TileLayer(
              // OpenStreetMap standard tiles — colorful, Google Maps-like style
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.example.playspot_flutter',
              maxZoom: 19,
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: origin,
                  width: 46,
                  height: 46,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: PSColors.fire,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Center(child: Text('📍', style: TextStyle(fontSize: 18))),
                  ),
                ),
                for (final f in friends)
                  Marker(
                    point: LatLng(
                      FriendsService.pseudoLocation(origin.latitude, origin.longitude, f.id).$1,
                      FriendsService.pseudoLocation(origin.latitude, origin.longitude, f.id).$2,
                    ),
                    width: 48,
                    height: 48,
                    child: GestureDetector(
                      onTap: () => _showFriendPin(f),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: PSColors.gold,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: PSShadows.glowGoldSm,
                        ),
                        child: ClipOval(
                          child: CachedNetworkImage(imageUrl: f.avatarUrl, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: PSColors.bg.withOpacity(0.85),
              borderRadius: BorderRadius.circular(PSRadius.sm),
              border: Border.all(color: PSColors.border),
            ),
            child: Text(
              'Approximate last-active areas — precise venue pins need check-in data.',
              style: PSText.bodyDim.copyWith(fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }

  void _showFriendPin(PlayerModel f) {
    showModalBottomSheet(
      context: context,
      backgroundColor: PSColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(radius: 24, backgroundImage: CachedNetworkImageProvider(f.avatarUrl)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.name, style: const TextStyle(color: PSColors.ink, fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    f.sportTags.isNotEmpty ? f.sportTags.join(' · ') : 'No sports listed',
                    style: PSText.bodyDim,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
