import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_models.dart';
import '../socket_service.dart';
import '../services/mvp_vote_service.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final SocketService _socketService = SocketService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  ChatGroup? _groupInfo;
  bool _isLoading = true;
  bool _isAdmin = false;
  bool _gameEnded = false;
  bool _hasVoted = false;
  String? _myUserId;
  bool _hasRsvpd = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _socketService.connect();
    
    // Get current user ID
    final prefs = await SharedPreferences.getInstance();
    _myUserId = prefs.getString('ps_userId');
    _hasRsvpd = prefs.getBool('ps_rsvp_${widget.groupId}') ?? false;
    _gameEnded = await MvpVoteService.isEnded(widget.groupId);
    _hasVoted = await MvpVoteService.hasVoted(widget.groupId);
    if (mounted) setState(() {});
    
    _loadGroupInfo();
    _loadMessages();
    
    _socketService.onGroupMessage((message) {
      if (message['groupId'] == widget.groupId) {
        setState(() {
          _messages.add(ChatMessage.fromJson(message));
        });
        _scrollToBottom();
      }
    });
    
    _socketService.onGroupUpdated((group) {
      if (group['id'] == widget.groupId) {
        setState(() {
          _groupInfo = ChatGroup.fromJson(group);
          _isAdmin = _groupInfo?.adminId == _myUserId;
        });
      }
    });
  }

  Future<void> _loadGroupInfo() async {
    _socketService.getGroupInfo(widget.groupId, (group) {
      if (mounted) {
        setState(() {
          _groupInfo = ChatGroup.fromJson(group);
          _isAdmin = _groupInfo?.adminId == _myUserId;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _loadMessages() async {
    _socketService.getGroupMessages(widget.groupId, (messages) {
      if (mounted) {
        setState(() {
          _messages = messages.map((m) => ChatMessage.fromJson(m)).toList();
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _socketService.sendGroupMessage(
      widget.groupId,
      content,
      MessageType.text.name,
      (response) {
        if (response['ok']) {
          _messageController.clear();
        }
      },
    );
  }

  void _showGroupOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A0C00),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline, color: Color(0xFFF5A623)),
              title: const Text('Group Info', style: TextStyle(color: Color(0xFFFFF8F0))),
              onTap: () => _showGroupInfo(),
            ),
            ListTile(
              leading: const Icon(Icons.people_outline, color: Color(0xFFF5A623)),
              title: const Text('Members', style: TextStyle(color: Color(0xFFFFF8F0))),
              onTap: () => _showMembers(),
            ),
            if (_isAdmin)
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFFF5A623)),
                title: const Text('Edit Group', style: TextStyle(color: Color(0xFFFFF8F0))),
                onTap: () => _editGroup(),
              ),
            if ((_groupInfo?.isGameGroup ?? false) && _isAdmin && !_gameEnded)
              ListTile(
                leading: const Text('🏁', style: TextStyle(fontSize: 20)),
                title: const Text('End Game & Start MVP Vote', style: TextStyle(color: Color(0xFFFFF8F0))),
                onTap: () {
                  Navigator.pop(context);
                  _endGame();
                },
              ),
            if ((_groupInfo?.isGameGroup ?? false) && _gameEnded)
              ListTile(
                leading: const Text('🏅', style: TextStyle(fontSize: 20)),
                title: Text(_hasVoted ? 'MVP Vote (already voted)' : 'Vote for MVP', style: const TextStyle(color: Color(0xFFFFF8F0))),
                onTap: () {
                  Navigator.pop(context);
                  _showMvpVoteSheet();
                },
              ),
            ListTile(
              leading: const Icon(Icons.notifications, color: Color(0xFFF5A623)),
              title: const Text('Notifications', style: TextStyle(color: Color(0xFFFFF8F0))),
              onTap: () => _toggleNotifications(),
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text('Leave Group', style: TextStyle(color: Colors.red)),
              onTap: () => _leaveGroup(),
            ),
          ],
        ),
      ),
    );
  }

  void _showGroupInfo() {
    if (_groupInfo == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A0C00),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_groupInfo!.name, style: const TextStyle(color: Color(0xFFFFF8F0))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_groupInfo!.announcement != null && _groupInfo!.announcement!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Announcement:', style: TextStyle(color: Color(0xFFF5A623), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_groupInfo!.announcement!, style: const TextStyle(color: Color(0x8CFFF8F0))),
                  const SizedBox(height: 12),
                ],
              ),
            Text('Description:', style: const TextStyle(color: Color(0xFFF5A623), fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(_groupInfo!.description, style: const TextStyle(color: Color(0x8CFFF8F0))),
            const SizedBox(height: 12),
            Text('Members: ${_groupInfo!.memberIds.length}', style: const TextStyle(color: Color(0x8CFFF8F0))),
            Text('Created: ${_formatDate(_groupInfo!.createdAt)}', style: const TextStyle(color: Color(0x8CFFF8F0))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFFF5A623))),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRsvp() async {
    setState(() => _hasRsvpd = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ps_rsvp_${widget.groupId}', true);

    // Best-effort: let the group know. Doesn't block the UI if it fails.
    try {
      _socketService.sendGroupMessage(
        widget.groupId,
        "🙌 I'm in!",
        MessageType.system.name,
        (_) {},
      );
    } catch (e) {
      print('RSVP message failed to send: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You're RSVP'd — see you there!"),
          backgroundColor: Color(0xFFF5A623),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Host-only: closes the game for MVP voting. Local-only state (see
  /// MvpVoteService) since there's no `game:end` backend event yet — the
  /// system message is what actually tells everyone else in the group.
  Future<void> _endGame() async {
    await MvpVoteService.markEnded(widget.groupId);
    setState(() => _gameEnded = true);

    try {
      _socketService.sendGroupMessage(
        widget.groupId,
        "🏁 Game ended — tap the menu to vote for MVP!",
        MessageType.system.name,
        (_) {},
      );
    } catch (e) {
      print('End-game system message failed: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Game ended — MVP voting is open'),
          backgroundColor: Color(0xFFF5A623),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Candidates come from distinct senders seen in this chat (a practical
  /// stand-in for a real roster, since the app has no `group:members`
  /// fetch yet — see the TODO in `_showMembers`).
  List<MapEntry<String, String>> get _mvpCandidates {
    final seen = <String, String>{}; // senderId -> senderName
    for (final m in _messages) {
      if (m.type == MessageType.system) continue;
      seen[m.senderId] = m.senderName;
    }
    return seen.entries.toList();
  }

  void _showMvpVoteSheet() {
    final candidates = _mvpCandidates;
    String? selectedId;
    int stars = 5;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A0C00),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Rate the game & vote MVP', style: TextStyle(color: Color(0xFFFFF8F0), fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: List.generate(5, (i) {
                  final filled = i < stars;
                  return IconButton(
                    onPressed: () => setSheetState(() => stars = i + 1),
                    icon: Icon(filled ? Icons.star : Icons.star_border, color: const Color(0xFFF5A623)),
                  );
                }),
              ),
              const SizedBox(height: 8),
              if (candidates.isEmpty)
                const Text('No other players seen in this chat yet.', style: TextStyle(color: Color(0x8CFFF8F0)))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: candidates.map((c) {
                    final isSelected = selectedId == c.key;
                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedId = c.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFF5A623) : const Color(0xFF241200),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFF5A623)),
                        ),
                        child: Text(
                          c.value,
                          style: TextStyle(color: isSelected ? const Color(0xFF140A00) : const Color(0xFFFFF8F0), fontWeight: FontWeight.w600),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: selectedId == null
                    ? null
                    : () async {
                        await MvpVoteService.castVote(groupId: widget.groupId, mvpCandidateId: selectedId!, starRating: stars);
                        setState(() => _hasVoted = true);
                        final name = candidates.firstWhere((c) => c.key == selectedId).value;
                        try {
                          _socketService.sendGroupMessage(
                            widget.groupId,
                            "🏅 Voted $name for MVP ($stars★)",
                            MessageType.system.name,
                            (_) {},
                          );
                        } catch (e) {
                          print('MVP vote message failed: $e');
                        }
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5A623),
                  foregroundColor: const Color(0xFF140A00),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Submit Vote'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMembers() {
    // TODO: Implement members list
  }

  void _editGroup() {
    // TODO: Implement group editing
  }

  void _toggleNotifications() {
    // TODO: Implement notification toggle
  }

  void _leaveGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A0C00),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Leave Group?', style: TextStyle(color: Color(0xFFFFF8F0))),
        content: const Text('Are you sure you want to leave this group?', style: TextStyle(color: Color(0x8CFFF8F0))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFFF5A623))),
          ),
          TextButton(
            onPressed: () {
              _socketService.leaveGroup(widget.groupId, (response) {
                if (response['ok']) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                }
              });
            },
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0700),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0700),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.groupName,
              style: const TextStyle(
                color: Color(0xFFFFF8F0),
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_groupInfo != null)
              Text(
                '${_groupInfo!.memberIds.length} members',
                style: const TextStyle(
                  color: Color(0x8CFFF8F0),
                  fontSize: 12,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFFF5A623)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFFF5A623)),
            onPressed: _showGroupOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Sticky RSVP banner — only for game/event groups, dismissed once tapped
          if (_groupInfo != null &&
              (_groupInfo!.isGameGroup || _groupInfo!.isEventGroup) &&
              !_hasRsvpd)
            GestureDetector(
              onTap: _handleRsvp,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                color: const Color(0xFFF5A623),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Tap to RSVP',
                      style: TextStyle(
                        color: Color(0xFF140A00),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text('👋', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
          // Announcement banner
          if (_groupInfo?.announcement != null && _groupInfo!.announcement!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5A623).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF5A623)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.announcement, color: Color(0xFFF5A623)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _groupInfo!.announcement!,
                      style: const TextStyle(color: Color(0xFFF5A623)),
                    ),
                  ),
                ],
              ),
            ),
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF5A623)),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A0C00),
              border: Border(
                top: BorderSide(color: const Color(0x1AFFB93C)),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Color(0xFFF5A623)),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(color: Color(0x47FFF8F0)),
                      filled: true,
                      fillColor: const Color(0xFF0E0700),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    style: const TextStyle(color: Color(0xFFFFF8F0)),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFFF5A623)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isMe = message.senderId == _myUserId;
    final isAdmin = _groupInfo?.adminId == message.senderId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (message.isPinned)
            Row(
              children: [
                const Icon(Icons.push_pin, size: 12, color: Color(0xFFF5A623)),
                const SizedBox(width: 4),
                const Text('Pinned', style: TextStyle(color: Color(0xFFF5A623), fontSize: 11)),
              ],
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe) ...[
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: message.senderPhoto != null
                          ? CachedNetworkImageProvider(message.senderPhoto!)
                          : null,
                      child: message.senderPhoto == null
                          ? const Icon(Icons.person, size: 16, color: Color(0xFFF5A623))
                          : null,
                    ),
                    // Host crown badge — marks whoever created this game/event group
                    if (isAdmin)
                      Positioned(
                        top: -6,
                        left: -2,
                        child: Text('👑', style: TextStyle(fontSize: 14)),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      Row(
                        children: [
                          Text(
                            message.senderName,
                            style: TextStyle(
                              color: isAdmin ? const Color(0xFFF5A623) : const Color(0xFFFFF8F0),
                              fontWeight: isAdmin ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, size: 12, color: Color(0xFFF5A623)),
                          ],
                        ],
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMe ? const Color(0xFFF5A623) : const Color(0xFF1A0C00),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        message.content,
                        style: TextStyle(
                          color: isMe ? const Color(0xFF140A00) : const Color(0xFFFFF8F0),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          _formatTime(message.timestamp),
                          style: const TextStyle(
                            color: Color(0x47FFF8F0),
                            fontSize: 10,
                          ),
                        ),
                        if (message.isEdited) ...[
                          const SizedBox(width: 4),
                          const Text('edited', style: TextStyle(color: Color(0x47FFF8F0), fontSize: 10)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (isMe) const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
