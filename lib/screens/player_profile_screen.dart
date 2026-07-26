import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_model.dart';
import '../theme/playspot_theme.dart';

class PlayerProfileScreen extends StatefulWidget {
  final PlayerModel player;
  final bool isOwnProfile;

  const PlayerProfileScreen({super.key, required this.player, this.isOwnProfile = false});

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFollowing = false;
  bool _isPrivate = false;
  bool _allowMessages = false;
  bool _showOnMap = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _isFollowing = widget.player.isFollowing;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0700),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150,
            pinned: true,
            backgroundColor: const Color(0xFF0E0700),
            leading: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0E0700).withOpacity(0.6),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFFFFF8F0)),
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.player.coverPhotoUrl != null)
                    Image.network(
                      widget.player.coverPhotoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                PSColors.gold.withOpacity(0.2),
                                const Color(0xFF0E0700),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            PSColors.gold.withOpacity(0.2),
                            const Color(0xFF0E0700),
                          ],
                        ),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF0E0700).withOpacity(0.8),
                          const Color(0xFF0E0700),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 40),
                _buildAvatarSection(),
                const SizedBox(height: 16),
                _buildNameSection(),
                const SizedBox(height: 12),
                _buildBioSection(),
                const SizedBox(height: 12),
                _buildSportTags(),
                const SizedBox(height: 16),
                _buildStatsRow(),
                const SizedBox(height: 16),
                _buildActionButtons(),
                const SizedBox(height: 16),
                if (widget.isOwnProfile) _buildPrivacySettings(),
                const SizedBox(height: 16),
                _buildTabs(),
              ],
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPostsGrid(),
                _buildVideosGrid(),
                _buildTaggedGrid(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: NetworkImage(widget.player.avatarUrl),
          backgroundColor: PSColors.gold.withOpacity(0.2),
        ),
        if (widget.player.isVerified)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF0E0700),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified,
                color: Color(0xFFF5A623),
                size: 20,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNameSection() {
    return Column(
      children: [
        Text(
          widget.player.name,
          style: const TextStyle(
            color: Color(0xFFFFF8F0),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '@${widget.player.username}',
          style: TextStyle(
            color: PSColors.gold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildBioSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        widget.player.bio,
        style: TextStyle(
          color: PSColors.inkDim,
          fontSize: 13,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildSportTags() {
    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.player.sportTags.length,
        itemBuilder: (context, index) {
          final tag = widget.player.sportTags[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: PSColors.gold),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  color: PSColors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('Posts', _formatCount(widget.player.postCount)),
        _buildStatItem('Followers', _formatCount(widget.player.followerCount)),
        _buildStatItem('Following', _formatCount(widget.player.followingCount)),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return GestureDetector(
      onTap: () => _showFollowersList(label),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFFFF8F0),
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: PSColors.inkDim,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _isFollowing
                ? OutlinedButton(
                    onPressed: () => setState(() => _isFollowing = false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: PSColors.gold),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      'Following',
                      style: TextStyle(color: PSColors.gold),
                    ),
                  )
                : ElevatedButton(
                    onPressed: () => setState(() => _isFollowing = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5A623),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Follow',
                      style: TextStyle(color: Color(0xFF140A00)),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          if (widget.player.isFollowing || widget.player.allowMessagesFromAll)
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.message, size: 18),
                label: const Text('Message'),
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A0E00),
                  side: BorderSide(color: PSColors.gold),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: PSColors.gold.withOpacity(0.5)),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.share, color: PSColors.gold, size: 20),
              onPressed: () {},
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySettings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: PSColors.surface2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PSColors.gold.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text(
                'Private Account',
                style: TextStyle(color: Color(0xFFFFF8F0)),
              ),
              subtitle: const Text(
                'Only approved followers see your posts',
                style: TextStyle(color: Color(0x8CFFF8F0)),
              ),
              activeColor: const Color(0xFFF5A623),
              value: _isPrivate,
              onChanged: (val) => setState(() => _isPrivate = val),
            ),
            SwitchListTile(
              title: const Text(
                'Allow Messages From Everyone',
                style: TextStyle(color: Color(0xFFFFF8F0)),
              ),
              activeColor: const Color(0xFFF5A623),
              value: _allowMessages,
              onChanged: (val) => setState(() => _allowMessages = val),
            ),
            SwitchListTile(
              title: const Text(
                'Show My Location on Map',
                style: TextStyle(color: Color(0xFFFFF8F0)),
              ),
              subtitle: const Text(
                'Others can see you on the map',
                style: TextStyle(color: Color(0x8CFFF8F0)),
              ),
              activeColor: const Color(0xFFF5A623),
              value: _showOnMap,
              onChanged: (val) => setState(() => _showOnMap = val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return TabBar(
      controller: _tabController,
      labelColor: PSColors.gold,
      unselectedLabelColor: PSColors.inkDim,
      indicatorColor: PSColors.gold,
      tabs: const [
        Tab(text: 'Posts'),
        Tab(text: 'Videos'),
        Tab(text: 'Tagged'),
      ],
    );
  }

  Widget _buildPostsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        return _buildGridItem(isVideo: false);
      },
    );
  }

  Widget _buildVideosGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        return _buildGridItem(isVideo: true, duration: '0:${30 + index}');
      },
    );
  }

  Widget _buildTaggedGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return _buildGridItem(isVideo: false);
      },
    );
  }

  Widget _buildGridItem({bool isVideo = false, String? duration}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: PSGradients.sportCard,
            border: Border.all(color: PSColors.gold.withOpacity(0.1)),
          ),
          child: Center(
            child: Icon(
              isVideo ? Icons.play_circle_outline : Icons.image,
              color: PSColors.gold.withOpacity(0.3),
              size: 32,
            ),
          ),
        ),
        if (isVideo && duration != null)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.play_arrow,
                    size: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    duration,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (widget.player.isLive)
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              color: Colors.red,
              child: const Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
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

  String _getRandomPhotoId(int index) {
    final photoIds = [
      '1507003211169-0a1dd7228f2d',
      '1494790108377-be9c29b29330',
      '1500648767791-00dcc994a43e',
      '1438761681033-6461ffad8d80',
      '1472099645785-5658abf4ff4e',
      '1506794778202-cad84cf45f1d',
      '1517841905240-472988babdf9',
      '1531427186611-ecfd6d936c79',
      '1544005313-94ddf0286df2',
      '1504257432389-52343af06ae3',
    ];
    return photoIds[index % photoIds.length];
  }

  void _showFollowersList(String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PSColors.surface2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          type,
          style: const TextStyle(color: Color(0xFFFFF8F0)),
        ),
        content: SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: 10,
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                    'https://images.unsplash.com/photo-${_getRandomPhotoId(index)}?w=50&h=50&fit=crop&crop=face',
                  ),
                ),
                title: Text(
                  'User $index',
                  style: const TextStyle(color: Color(0xFFFFF8F0)),
                ),
                subtitle: Text(
                  '@user$index',
                  style: TextStyle(color: PSColors.inkDim),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
