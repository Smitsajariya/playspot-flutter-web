import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import '../theme/playspot_theme.dart';
import '../models/player_model.dart';
import '../data/mock_data.dart';
import 'player_profile_screen.dart';

class PostComment {
  final String id;
  final String postId;
  final String userName;
  final String text;
  final DateTime createdAt;

  PostComment({
    required this.id,
    required this.postId,
    required this.userName,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'postId': postId,
        'userName': userName,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PostComment.fromJson(Map<String, dynamic> json) => PostComment(
        id: json['id'],
        postId: json['postId'],
        userName: json['userName'],
        text: json['text'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class SocialPost {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String? avatarUrl;
  final String content;
  final String? imageUrl;
  final String? videoUrl;
  final Uint8List? mediaBytes;
  final int likes;
  final int comments;
  final int shares;
  final DateTime createdAt;
  final bool isLive;
  final bool isFollowing;
  final String category;
  final String categoryEmoji;
  final String? location;
  final String? filter;

  SocialPost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    this.avatarUrl,
    required this.content,
    this.imageUrl,
    this.videoUrl,
    this.mediaBytes,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.createdAt,
    this.isLive = false,
    this.isFollowing = false,
    required this.category,
    required this.categoryEmoji,
    this.location,
    this.filter,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'avatarUrl': avatarUrl,
      'content': content,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'mediaBytes': mediaBytes != null ? base64Encode(mediaBytes!) : null,
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'createdAt': createdAt.toIso8601String(),
      'isLive': isLive,
      'isFollowing': isFollowing,
      'category': category,
      'categoryEmoji': categoryEmoji,
      'location': location,
      'filter': filter,
    };
  }

  factory SocialPost.fromJson(Map<String, dynamic> json) {
    return SocialPost(
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'],
      userAvatar: json['userAvatar'],
      avatarUrl: json['avatarUrl'],
      content: json['content'],
      imageUrl: json['imageUrl'],
      videoUrl: json['videoUrl'],
      mediaBytes: json['mediaBytes'] != null ? base64Decode(json['mediaBytes']) : null,
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      shares: json['shares'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      isLive: json['isLive'] ?? false,
      isFollowing: json['isFollowing'] ?? false,
      category: json['category'],
      categoryEmoji: json['categoryEmoji'],
      location: json['location'],
      filter: json['filter'],
    );
  }
}

class Story {
  final String id;
  final String userId;
  final String userName;
  final String? avatarUrl;
  final String userEmoji;
  final bool isOwnStory;
  final bool isViewed;

  Story({
    required this.id,
    required this.userId,
    required this.userName,
    this.avatarUrl,
    required this.userEmoji,
    this.isOwnStory = false,
    this.isViewed = false,
  });
}

class SocialFeedScreen extends StatefulWidget {
  final VoidCallback onCreatePost;
  final VoidCallback onGoLive;
  final Function(Map<String, dynamic>)? onPostCreated;

  const SocialFeedScreen({
    super.key,
    required this.onCreatePost,
    required this.onGoLive,
    this.onPostCreated,
  });

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<PlayerModel> _searchResults = [];
  List<SocialPost> _posts = [];
  
  final List<Story> _stories = [
    Story(
      id: 'own',
      userId: 'me',
      userName: 'Your Story',
      userEmoji: '➕',
      isOwnStory: true,
    ),
    Story(
      id: '1',
      userId: 'user1',
      userName: 'Alex J.',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop&crop=face',
      userEmoji: '🏃',
      isViewed: false,
    ),
    Story(
      id: '2',
      userId: 'user2',
      userName: 'Sarah C.',
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&h=100&fit=crop&crop=face',
      userEmoji: '🎾',
      isViewed: false,
    ),
    Story(
      id: '3',
      userId: 'user3',
      userName: 'Mike S.',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&h=100&fit=crop&crop=face',
      userEmoji: '⚽',
      isViewed: true,
    ),
    Story(
      id: '4',
      userId: 'user4',
      userName: 'Emma W.',
      avatarUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100&h=100&fit=crop&crop=face',
      userEmoji: '🏀',
      isViewed: false,
    ),
    Story(
      id: '5',
      userId: 'user5',
      userName: 'David K.',
      avatarUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&h=100&fit=crop&crop=face',
      userEmoji: '🎱',
      isViewed: true,
    ),
  ];

  final List<SocialPost> _defaultPosts = [
    SocialPost(
      id: '1',
      userId: 'user1',
      userName: 'Alex Johnson',
      userAvatar: '🏃',
      content: 'Just finished an amazing 5K run! 🏃‍♂️💪',
      imageUrl: null,
      likes: 42,
      comments: 8,
      shares: 3,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isFollowing: false,
      category: 'Running',
      categoryEmoji: '🏃',
    ),
    SocialPost(
      id: '2',
      userId: 'user2',
      userName: 'Sarah Chen',
      userAvatar: '🎾',
      content: 'Tennis practice with the team today! Great matches all around 🎾',
      imageUrl: null,
      likes: 89,
      comments: 15,
      shares: 7,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      isFollowing: true,
      category: 'Tennis',
      categoryEmoji: '🎾',
    ),
    SocialPost(
      id: '3',
      userId: 'user3',
      userName: 'Mike Sports',
      userAvatar: '⚽',
      content: 'Live now at the community football match! Come join us! 🔴',
      imageUrl: null,
      likes: 156,
      comments: 32,
      shares: 18,
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      isLive: true,
      isFollowing: false,
      category: 'Football',
      categoryEmoji: '⚽',
    ),
  ];

  final Set<String> _likedPosts = {};
  final Set<String> _bookmarkedPosts = {};
  final Set<String> _followedUserIds = {};
  final Set<String> _reportedPostIds = {};
  List<PostComment> _comments = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPosts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  Future<void> _loadPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final postsJson = prefs.getString('ps_posts');
      final likedJson = prefs.getString('ps_liked_posts');
      final bookmarkedJson = prefs.getString('ps_bookmarked_posts');
      
      if (postsJson != null) {
        final List<dynamic> postsList = jsonDecode(postsJson);
        setState(() {
          _posts = postsList.map((json) => SocialPost.fromJson(json)).toList();
        });
      } else {
        setState(() {
          _posts = List.from(_defaultPosts);
        });
      }

      if (likedJson != null) {
        setState(() {
          _likedPosts.addAll(jsonDecode(likedJson).cast<String>());
        });
      }

      if (bookmarkedJson != null) {
        setState(() {
          _bookmarkedPosts.addAll(jsonDecode(bookmarkedJson).cast<String>());
        });
      }

      final commentsJson = prefs.getString('ps_comments');
      if (commentsJson != null) {
        final List<dynamic> commentsList = jsonDecode(commentsJson);
        setState(() {
          _comments = commentsList.map((json) => PostComment.fromJson(json)).toList();
        });
      }

      final followedJson = prefs.getString('ps_followed_users');
      if (followedJson != null) {
        setState(() {
          _followedUserIds.addAll(jsonDecode(followedJson).cast<String>());
        });
      }

      final reportedJson = prefs.getString('ps_reported_posts');
      if (reportedJson != null) {
        setState(() {
          _reportedPostIds.addAll(jsonDecode(reportedJson).cast<String>());
        });
      }
    } catch (e) {
      print('Error loading posts: $e');
      setState(() {
        _posts = List.from(_defaultPosts);
      });
    }
  }

  Future<void> _savePosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final postsJson = jsonEncode(_posts.map((post) => post.toJson()).toList());
      await prefs.setString('ps_posts', postsJson);
      await prefs.setString('ps_liked_posts', jsonEncode(_likedPosts.toList()));
      await prefs.setString('ps_bookmarked_posts', jsonEncode(_bookmarkedPosts.toList()));
      await prefs.setString('ps_comments', jsonEncode(_comments.map((c) => c.toJson()).toList()));
      await prefs.setString('ps_followed_users', jsonEncode(_followedUserIds.toList()));
      await prefs.setString('ps_reported_posts', jsonEncode(_reportedPostIds.toList()));
    } catch (e) {
      print('Error saving posts: $e');
    }
  }

  void addPost(Map<String, dynamic> postData) {
    final newPost = SocialPost(
      id: postData['id'],
      userId: postData['userId'] ?? 'me',
      userName: postData['userName'] ?? 'You',
      userAvatar: postData['userAvatar'] ?? '👤',
      avatarUrl: postData['avatarUrl'],
      content: postData['content'] ?? '',
      mediaBytes: postData['mediaBytes'] != null ? base64Decode(postData['mediaBytes']) : null,
      likes: 0,
      comments: 0,
      shares: 0,
      createdAt: DateTime.parse(postData['createdAt']),
      category: postData['category'] ?? 'General',
      categoryEmoji: postData['categoryEmoji'] ?? '📝',
      location: postData['location'],
      filter: postData['filter'],
    );
    
    setState(() {
      _posts.insert(0, newPost);
    });
    
    _savePosts();
  }

  Future<void> _addComment(String postId, String text) async {
    if (text.trim().isEmpty) return;

    final comment = PostComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      postId: postId,
      userName: 'You',
      text: text.trim(),
      createdAt: DateTime.now(),
    );

    setState(() {
      _comments.add(comment);
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        _posts[postIndex] = SocialPost(
          id: _posts[postIndex].id,
          userId: _posts[postIndex].userId,
          userName: _posts[postIndex].userName,
          userAvatar: _posts[postIndex].userAvatar,
          avatarUrl: _posts[postIndex].avatarUrl,
          content: _posts[postIndex].content,
          imageUrl: _posts[postIndex].imageUrl,
          videoUrl: _posts[postIndex].videoUrl,
          mediaBytes: _posts[postIndex].mediaBytes,
          likes: _posts[postIndex].likes,
          comments: _posts[postIndex].comments + 1,
          shares: _posts[postIndex].shares,
          createdAt: _posts[postIndex].createdAt,
          isLive: _posts[postIndex].isLive,
          isFollowing: _posts[postIndex].isFollowing,
          category: _posts[postIndex].category,
          categoryEmoji: _posts[postIndex].categoryEmoji,
          location: _posts[postIndex].location,
          filter: _posts[postIndex].filter,
        );
      }
    });
    _savePosts();
  }

  void _openComments(SocialPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PSColors.surface2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final textController = TextEditingController();
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final postComments = _comments.where((c) => c.postId == post.id).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.65,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: PSColors.inkDim.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Comments',
                      style: TextStyle(
                        color: PSColors.ink,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: postComments.isEmpty
                          ? Center(
                              child: Text(
                                'No comments yet. Be the first!',
                                style: TextStyle(color: PSColors.inkDim),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: postComments.length,
                              itemBuilder: (context, index) {
                                final c = postComments[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.userName,
                                        style: TextStyle(
                                          color: PSColors.ink,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        c.text,
                                        style: TextStyle(color: PSColors.inkDim, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: textController,
                                style: TextStyle(color: PSColors.ink),
                                decoration: InputDecoration(
                                  hintText: 'Add a comment...',
                                  hintStyle: TextStyle(color: PSColors.inkDim),
                                  filled: true,
                                  fillColor: PSColors.surface2,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide(color: PSColors.inkDim.withOpacity(0.3)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.send, color: Color(0xFFF5A623)),
                              onPressed: () async {
                                final text = textController.text;
                                if (text.trim().isEmpty) return;
                                await _addComment(post.id, text);
                                textController.clear();
                                setSheetState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _sharePost(SocialPost post) async {
    final caption = post.content.isNotEmpty ? post.content : 'Check out this post on PlaySpot!';
    await Share.share(
      '$caption\n\nShared from PlaySpot',
      subject: 'PlaySpot post from ${post.userName}',
    );
  }

  List<SocialPost> get _visiblePosts =>
      _posts.where((p) => !_reportedPostIds.contains(p.id)).toList();

  void _toggleLike(String postId) {
    setState(() {
      if (_likedPosts.contains(postId)) {
        _likedPosts.remove(postId);
        final postIndex = _posts.indexWhere((p) => p.id == postId);
        if (postIndex != -1) {
          _posts[postIndex] = SocialPost(
            id: _posts[postIndex].id,
            userId: _posts[postIndex].userId,
            userName: _posts[postIndex].userName,
            userAvatar: _posts[postIndex].userAvatar,
            avatarUrl: _posts[postIndex].avatarUrl,
            content: _posts[postIndex].content,
            imageUrl: _posts[postIndex].imageUrl,
            videoUrl: _posts[postIndex].videoUrl,
            mediaBytes: _posts[postIndex].mediaBytes,
            likes: _posts[postIndex].likes - 1,
            comments: _posts[postIndex].comments,
            shares: _posts[postIndex].shares,
            createdAt: _posts[postIndex].createdAt,
            isLive: _posts[postIndex].isLive,
            isFollowing: _posts[postIndex].isFollowing,
            category: _posts[postIndex].category,
            categoryEmoji: _posts[postIndex].categoryEmoji,
            location: _posts[postIndex].location,
            filter: _posts[postIndex].filter,
          );
        }
      } else {
        _likedPosts.add(postId);
        final postIndex = _posts.indexWhere((p) => p.id == postId);
        if (postIndex != -1) {
          _posts[postIndex] = SocialPost(
            id: _posts[postIndex].id,
            userId: _posts[postIndex].userId,
            userName: _posts[postIndex].userName,
            userAvatar: _posts[postIndex].userAvatar,
            avatarUrl: _posts[postIndex].avatarUrl,
            content: _posts[postIndex].content,
            imageUrl: _posts[postIndex].imageUrl,
            videoUrl: _posts[postIndex].videoUrl,
            mediaBytes: _posts[postIndex].mediaBytes,
            likes: _posts[postIndex].likes + 1,
            comments: _posts[postIndex].comments,
            shares: _posts[postIndex].shares,
            createdAt: _posts[postIndex].createdAt,
            isLive: _posts[postIndex].isLive,
            isFollowing: _posts[postIndex].isFollowing,
            category: _posts[postIndex].category,
            categoryEmoji: _posts[postIndex].categoryEmoji,
            location: _posts[postIndex].location,
            filter: _posts[postIndex].filter,
          );
        }
      }
    });
    _savePosts();
  }

  void _toggleFollow(SocialPost post) {
    setState(() {
      if (_followedUserIds.contains(post.userId)) {
        _followedUserIds.remove(post.userId);
      } else {
        _followedUserIds.add(post.userId);
      }
    });
    _savePosts();
  }

  void _showPostOptions(SocialPost post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: PSColors.surface2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.redAccent),
                title: const Text('Report post', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _reportPost(post);
                },
              ),
              ListTile(
                leading: Icon(Icons.link, color: PSColors.inkDim),
                title: Text('Copy link', style: TextStyle(color: PSColors.ink)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _sharePost(post);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _reportPost(SocialPost post) async {
    // Stores the report locally so this post is flagged for this user and
    // available to sync later. TODO: POST to a backend /api/reports
    // endpoint once one exists, so reports reach an admin/moderation queue
    // instead of staying only on-device.
    setState(() {
      _reportedPostIds.add(post.id);
    });
    await _savePosts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post reported. Thanks for helping keep PlaySpot safe.')),
      );
    }
  }

  void _handleDoubleTapLike(SocialPost post) {
    if (!_likedPosts.contains(post.id)) {
      _toggleLike(post.id);
    }
  }

  void _toggleBookmark(String postId) {
    setState(() {
      if (_bookmarkedPosts.contains(postId)) {
        _bookmarkedPosts.remove(postId);
      } else {
        _bookmarkedPosts.add(postId);
      }
    });
    _savePosts();
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    // Simulate loading more posts
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
  }

  Future<void> _refreshPosts() async {
    await _loadPosts();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _searchResults = [];
      } else {
        _searchResults = mockPlayers.where((player) {
          final nameLower = player.name.toLowerCase();
          final usernameLower = player.username.toLowerCase();
          final queryLower = query.toLowerCase();
          return nameLower.contains(queryLower) || 
                 usernameLower.contains(queryLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0700),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0700),
        elevation: 0,
        title: const Text(
          'Social Feed',
          style: TextStyle(
            color: Color(0xFFFFF8F0),
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Color(0xFFF5A623)),
            onPressed: widget.onCreatePost,
          ),
          IconButton(
            icon: const Icon(Icons.videocam, color: Color(0xFFF5A623)),
            onPressed: widget.onGoLive,
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0E0700), Color(0xFF0A0500)],
          ),
        ),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 16),
            if (_isSearching)
              Expanded(
                child: _buildSearchResults(),
              )
            else ...[
              _buildStoriesSection(),
              const SizedBox(height: 16),
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFFF5A623),
                  backgroundColor: const Color(0xFF1A0E00),
                  onRefresh: _refreshPosts,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                    itemCount: _visiblePosts.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _visiblePosts.length) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFF5A623),
                            ),
                          ),
                        );
                      }
                      return _buildPostCard(_visiblePosts[index]);
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: PSGradients.sportCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: PSColors.gold.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: const TextStyle(
            color: Color(0xFFFFF8F0),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: 'Search people...',
            hintStyle: TextStyle(
              color: PSColors.inkDim,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: PSColors.gold,
            ),
            suffixIcon: _isSearching
                ? IconButton(
                    icon: const Icon(Icons.clear, color: PSColors.inkDim),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: PSColors.inkDim.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(
                color: PSColors.inkDim,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final player = _searchResults[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlayerProfileScreen(player: player, isOwnProfile: false),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: PSGradients.sportCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: PSColors.gold.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(player.avatarUrl),
                  backgroundColor: PSColors.gold.withOpacity(0.2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            player.name,
                            style: const TextStyle(
                              color: Color(0xFFFFF8F0),
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          if (player.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              color: Color(0xFFF5A623),
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${player.username}',
                        style: TextStyle(
                          color: PSColors.gold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        player.bio,
                        style: TextStyle(
                          color: PSColors.inkDim,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (player.isLive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStoriesSection() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _stories.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildStoryItem(_stories[index]),
          );
        },
      ),
    );
  }

  Widget _buildStoryItem(Story story) {
    return GestureDetector(
      onTap: () => _openStoryViewer(story),
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: story.isOwnStory
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFFF5A623).withOpacity(0.3),
                              const Color(0xFFF5A623).withOpacity(0.1),
                            ],
                          )
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFFF5A623),
                              const Color(0xFFFFB93C),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: const Color(0xFFF5A623).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E0700),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: story.isOwnStory
                          ? Center(
                              child: Icon(Icons.add, color: PSColors.gold, size: 24),
                            )
                          : story.avatarUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    story.avatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Text(
                                          story.userEmoji,
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    story.userEmoji,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                    ),
                  ),
                ),
                if (story.isOwnStory)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: PSGradients.primaryButton,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF0E0700), width: 2),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Color(0xFF140A00),
                        size: 14,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              story.userName,
              style: TextStyle(
                color: PSColors.inkDim,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(SocialPost post) {
    return GestureDetector(
      onDoubleTap: () => _handleDoubleTapLike(post),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          gradient: PSGradients.sportCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: PSColors.gold.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPostHeader(post),
                if (post.isLive) _buildLiveIndicator(),
                _buildPostContent(post),
                _buildPostActions(post),
              ],
            ),
            Positioned(
              top: 80,
              right: 20,
              child: _buildHeartAnimation(post.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostHeader(SocialPost post) {
    final player = mockPlayers.firstWhere(
      (p) => p.id == post.userId,
      orElse: () => PlayerModel(
        id: post.userId,
        name: post.userName,
        username: post.userName.toLowerCase().replaceAll(' ', '_'),
        bio: '',
        avatarUrl: post.avatarUrl ?? '',
        sportTags: [post.category],
        followerCount: 0,
        followingCount: 0,
        postCount: 0,
        isVerified: false,
        isFollowing: post.isFollowing,
        isLive: post.isLive,
      ),
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerProfileScreen(player: player, isOwnProfile: false),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: PSGradients.goldAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  post.userAvatar,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.userName,
                    style: const TextStyle(
                      color: Color(0xFFFFF8F0),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: PSColors.gold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: PSColors.gold.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              post.categoryEmoji,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              post.category,
                              style: TextStyle(
                                color: PSColors.gold,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getTimeAgo(post.createdAt),
                    style: TextStyle(
                      color: PSColors.inkDim,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (!post.isFollowing && !_followedUserIds.contains(post.userId))
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: OutlinedButton(
                  onPressed: () => _toggleFollow(post),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: PSColors.gold),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Follow',
                    style: TextStyle(
                      color: PSColors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            IconButton(
              icon: Icon(Icons.more_horiz, color: PSColors.inkDim, size: 20),
              onPressed: () => _showPostOptions(post),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red, Colors.red.shade700],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostContent(SocialPost post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.content,
            style: const TextStyle(
              color: Color(0xFFFFF8F0),
              fontSize: 15,
              height: 1.4,
            ),
          ),
          if (post.location != null && post.location!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, color: PSColors.gold, size: 14),
                const SizedBox(width: 4),
                Text(
                  post.location!,
                  style: TextStyle(
                    color: PSColors.gold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
          if (post.mediaBytes != null || post.imageUrl != null || post.videoUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  if (post.mediaBytes != null)
                    Container(
                      height: 250,
                      child: Image.memory(
                        post.mediaBytes!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 250,
                            decoration: BoxDecoration(
                              gradient: PSGradients.sportCard,
                              border: Border.all(
                                color: PSColors.gold.withOpacity(0.2),
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 64,
                                color: PSColors.gold.withOpacity(0.5),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        gradient: PSGradients.sportCard,
                        border: Border.all(
                          color: PSColors.gold.withOpacity(0.2),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          post.videoUrl != null ? Icons.play_circle_outline : Icons.image,
                          size: 64,
                          color: PSColors.gold.withOpacity(0.5),
                        ),
                      ),
                    ),
                  if (post.videoUrl != null)
                    Positioned(
                      top: 8,
                      right: 8,
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
                              '0:45',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (post.videoUrl != null)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (post.comments > 0) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _openComments(post),
              child: Text(
                '💬 View all ${post.comments} comments',
                style: TextStyle(
                  color: PSColors.inkDim,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPostActions(SocialPost post) {
    final isLiked = _likedPosts.contains(post.id);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildActionButton(
                icon: isLiked ? Icons.favorite : Icons.favorite_border,
                label: _formatCount(post.likes),
                onTap: () => _toggleLike(post.id),
                color: isLiked ? Colors.red : PSColors.inkDim,
              ),
              const SizedBox(width: 20),
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: _formatCount(post.comments),
                onTap: () => _openComments(post),
              ),
              const SizedBox(width: 20),
              _buildActionButton(
                icon: Icons.send,
                label: _formatCount(post.shares),
                onTap: () => _sharePost(post),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _bookmarkedPosts.contains(post.id)
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  color: _bookmarkedPosts.contains(post.id)
                      ? PSColors.gold
                      : PSColors.inkDim,
                  size: 20,
                ),
                onPressed: () => _toggleBookmark(post.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          color: PSColors.gold.withOpacity(0.1),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color ?? PSColors.ink, size: 22),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: PSColors.inkDim,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _openStoryViewer(Story story) {
    if (story.isOwnStory) {
      widget.onCreatePost();
      return;
    }
    
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (context) => StoryViewer(story: story),
    );
  }

  void _showCreatePostBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: PSGradients.sportCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: PSColors.gold.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildCreateOption(
              icon: Icons.photo_camera,
              label: 'Take Photo',
              onTap: () {},
            ),
            _buildCreateOption(
              icon: Icons.photo_library,
              label: 'Choose from Gallery',
              onTap: () {},
            ),
            _buildCreateOption(
              icon: Icons.videocam,
              label: 'Record Video',
              onTap: () {},
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: PSColors.gold),
      title: Text(
        label,
        style: const TextStyle(color: Color(0xFFFFF8F0)),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _showGoLiveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PSColors.surface2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Go Live',
          style: TextStyle(color: Color(0xFFFFF8F0)),
        ),
        content: const Text(
          'Start a live stream to share your game with the community!',
          style: TextStyle(color: Color(0xFFFFF8F0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onGoLive();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PSColors.gold,
            ),
            child: const Text('Go Live'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartAnimation(String postId) {
    return AnimatedOpacity(
      opacity: _likedPosts.contains(postId) ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.favorite,
          color: Colors.red,
          size: 80,
        ),
      ),
    );
  }
}

class StoryViewer extends StatefulWidget {
  final Story story;
  
  const StoryViewer({super.key, required this.story});

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> {
  double _progress = 0;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _startProgress();
  }

  void _startProgress() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted && !_isPaused) {
        setState(() {
          _progress += 0.01;
        });
        if (_progress >= 1.0) {
          Navigator.pop(context);
          return false;
        }
        return true;
      }
      return false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _isPaused = !_isPaused);
        if (!_isPaused) _startProgress();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.story.userEmoji,
                    style: const TextStyle(fontSize: 80),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.story.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 40,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
