import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/chat_models.dart';
import '../socket_service.dart';
import 'group_chat_screen.dart';
import 'personal_chat_screen.dart';
import 'create_group_screen.dart';
import 'public_groups_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

enum _ChatTab { all, unread, games }

class _ChatListScreenState extends State<ChatListScreen> {
  final SocketService _socketService = SocketService();
  List<ChatConversation> _conversations = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _searchQuery = '';
  _ChatTab _tab = _ChatTab.all;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _connectWithTimeout();
  }

  Future<void> _connectWithTimeout() async {
    try {
      await Future.delayed(const Duration(seconds: 10));
      if (_isLoading) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    _hasError = false;
    
    _socketService.connect();
    _socketService.onNewMessage((message) {
      _loadConversations();
    });
    _socketService.onUserStatusChanged((data) {
      _updateUserStatus(data['userId'], data['isOnline']);
    });
    
    _socketService.getConversations((conversations) {
      if (mounted) {
        setState(() {
          _conversations = conversations
              .map((c) => ChatConversation.fromJson(c))
              .toList();
          _isLoading = false;
          _hasError = false;
        });
      }
    });
  }

  void _updateUserStatus(String userId, bool isOnline) {
    setState(() {
      _conversations = _conversations.map((conv) {
        if (!conv.isGroup && conv.otherUserId == userId) {
          return ChatConversation(
            id: conv.id,
            name: conv.name,
            photo: conv.photo,
            isGroup: conv.isGroup,
            groupId: conv.groupId,
            otherUserId: conv.otherUserId,
            lastMessage: conv.lastMessage,
            unreadCount: conv.unreadCount,
            isMuted: conv.isMuted,
            isPinned: conv.isPinned,
            onlineMemberIds: isOnline ? [userId] : [],
            isGameGroup: conv.isGameGroup,
            isEventGroup: conv.isEventGroup,
          );
        }
        return conv;
      }).toList();
    });
  }

  List<ChatConversation> get _filteredConversations {
    Iterable<ChatConversation> list = _conversations;
    switch (_tab) {
      case _ChatTab.all:
        break;
      case _ChatTab.unread:
        list = list.where((c) => c.unreadCount > 0);
        break;
      case _ChatTab.games:
        list = list.where((c) => c.isGameGroup || c.isEventGroup);
        break;
    }
    if (_searchQuery.isNotEmpty) {
      list = list.where((conv) =>
          conv.name.toLowerCase().contains(_searchQuery.toLowerCase()));
    }
    return list.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0700),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0700),
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Color(0xFFFFF8F0),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFFF5A623)),
            onPressed: () {
              setState(() => _searchQuery = '');
            },
          ),
          IconButton(
            icon: const Icon(Icons.group_add, color: Color(0xFFF5A623)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateGroupScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.public, color: Color(0xFFF5A623)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PublicGroupsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          if (_searchQuery.isNotEmpty || true)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  hintStyle: const TextStyle(color: Color(0x47FFF8F0)),
                  filled: true,
                  fillColor: const Color(0xFF1A0C00),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFFF5A623),
                  ),
                ),
                style: const TextStyle(color: Color(0xFFFFF8F0)),
              ),
            ),
          // Segmented tabs: All / Unread / Games
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _buildTabChip('All', _ChatTab.all),
                const SizedBox(width: 8),
                _buildTabChip(
                  'Unread',
                  _ChatTab.unread,
                  count: _conversations.where((c) => c.unreadCount > 0).length,
                ),
                const SizedBox(width: 8),
                _buildTabChip(
                  'Games',
                  _ChatTab.games,
                  count: _conversations.where((c) => c.isGameGroup || c.isEventGroup).length,
                ),
              ],
            ),
          ),
          // Conversations list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF5A623)),
                  )
                : _hasError
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: const Color(0xFFF5A623),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Could not connect',
                              style: TextStyle(
                                color: Color(0xFFFFF8F0),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tap to retry',
                              style: TextStyle(
                                color: Color(0x8CFFF8F0),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadConversations,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF5A623),
                                foregroundColor: const Color(0xFF140A00),
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredConversations.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: const Color(0x47FFF8F0),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _tab == _ChatTab.unread
                                      ? 'No unread chats'
                                      : _tab == _ChatTab.games
                                          ? 'No game chats yet'
                                          : 'No conversations yet',
                                  style: const TextStyle(
                                    color: Color(0x47FFF8F0),
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Start a chat to get started!',
                                  style: TextStyle(
                                    color: Color(0x47FFF8F0),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredConversations.length,
                            itemBuilder: (context, index) {
                              final conversation = _filteredConversations[index];
                              return _buildConversationTile(conversation);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip(String label, _ChatTab value, {int? count}) {
    final selected = _tab == value;
    return GestureDetector(
      onTap: () => setState(() => _tab = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF5A623) : const Color(0xFF1A0C00),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFFF5A623) : const Color(0x1AFFB93C),
          ),
        ),
        child: Text(
          count != null && count > 0 ? '$label ($count)' : label,
          style: TextStyle(
            color: selected ? const Color(0xFF140A00) : const Color(0xFFFFF8F0),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildConversationTile(ChatConversation conversation) {
    final isOnline = !conversation.isGroup &&
        conversation.onlineMemberIds.contains(conversation.otherUserId);

    return ListTile(
      onTap: () {
        if (conversation.isGroup && conversation.groupId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupChatScreen(
                groupId: conversation.groupId!,
                groupName: conversation.name,
              ),
            ),
          );
        } else if (conversation.otherUserId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PersonalChatScreen(
                userId: conversation.otherUserId!,
                userName: conversation.name,
                userPhoto: conversation.photo,
              ),
            ),
          );
        }
      },
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundImage: conversation.photo != null
                ? CachedNetworkImageProvider(conversation.photo!)
                : null,
            child: conversation.photo == null
                ? Icon(
                    conversation.isGroup ? Icons.group : Icons.person,
                    color: const Color(0xFFF5A623),
                  )
                : null,
          ),
          if (isOnline)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0E0700), width: 2),
                ),
              ),
            ),
          if (conversation.isGameGroup)
            Positioned(
              top: -2,
              left: -2,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5A623),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0E0700), width: 1.5),
                ),
                child: const Center(
                  child: Text('🏆', style: TextStyle(fontSize: 10)),
                ),
              ),
            )
          else if (conversation.isEventGroup)
            Positioned(
              top: -2,
              left: -2,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5A623),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0E0700), width: 1.5),
                ),
                child: const Icon(Icons.location_pin, size: 11, color: Color(0xFF140A00)),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.name,
              style: const TextStyle(
                color: Color(0xFFFFF8F0),
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (conversation.isPinned)
            const Icon(Icons.push_pin, size: 16, color: Color(0xFFF5A623)),
          if (conversation.isMuted)
            const Icon(Icons.notifications_off, size: 16, color: Color(0x8CFFF8F0)),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              conversation.lastMessage?.content ?? 'No messages yet',
              style: const TextStyle(
                color: Color(0x8CFFF8F0),
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (conversation.lastMessage != null)
            Text(
              _formatTime(conversation.lastMessage!.timestamp),
              style: const TextStyle(
                color: Color(0x47FFF8F0),
                fontSize: 11,
              ),
            ),
        ],
      ),
      trailing: conversation.unreadCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF5A623),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                conversation.unreadCount > 99 ? '99+' : conversation.unreadCount.toString(),
                style: const TextStyle(
                  color: Color(0xFF140A00),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
