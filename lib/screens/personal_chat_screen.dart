import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/chat_models.dart';
import '../socket_service.dart';

class PersonalChatScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userPhoto;

  const PersonalChatScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.userPhoto,
  });

  @override
  State<PersonalChatScreen> createState() => _PersonalChatScreenState();
}

class _PersonalChatScreenState extends State<PersonalChatScreen> {
  final SocketService _socketService = SocketService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isOnline = false;
  bool _isBlocked = false;
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _socketService.connect();
    
    final prefs = await SharedPreferences.getInstance();
    _myUserId = prefs.getString('ps_userId');
    
    // Check if recipient allows messages from everyone
    await _checkRecipientPrivacy();
    
    if (!_isBlocked) {
      _loadMessages();
      _checkOnlineStatus();
    }
    
    _socketService.onPersonalMessage((message) {
      if ((message['senderId'] == widget.userId && message['receiverId'] == _myUserId) ||
          (message['senderId'] == _myUserId && message['receiverId'] == widget.userId)) {
        setState(() {
          _messages.add(ChatMessage.fromJson(message));
        });
        _scrollToBottom();
      }
    });
    
    _socketService.onUserStatusChanged((data) {
      if (data['userId'] == widget.userId) {
        setState(() => _isOnline = data['isOnline']);
      }
    });
  }

  Future<void> _checkRecipientPrivacy() async {
    try {
      // Check if there's an existing conversation with this user
      _socketService.getConversations((conversations) {
        final hasExistingConversation = conversations.any((conv) => 
          conv['otherUserId'] == widget.userId && !conv['isGroup']
        );
        
        if (!hasExistingConversation) {
          // No existing conversation - check recipient's privacy settings
          // Note: In a real app, this would fetch the recipient's profile from the backend
          // For now, we'll allow it since we don't have a backend endpoint to fetch other users' privacy settings
          // TODO: Add backend endpoint to fetch user privacy settings and check here
          setState(() {
            _isBlocked = false; // Allow for demo purposes
          });
        } else {
          // Existing conversation - always allow
          setState(() {
            _isBlocked = false;
          });
        }
      });
    } catch (e) {
      print('Error checking recipient privacy: $e');
      setState(() {
        _isBlocked = false; // Allow on error for demo
      });
    }
  }

  Future<void> _loadMessages() async {
    _socketService.getPersonalMessages(widget.userId, (messages) {
      if (mounted) {
        setState(() {
          _messages = messages.map((m) => ChatMessage.fromJson(m)).toList();
          _isLoading = false;
        });
        _scrollToBottom();
      }
    });
  }

  Future<void> _checkOnlineStatus() async {
    _socketService.getUserStatus(widget.userId, (status) {
      if (mounted) {
        setState(() => _isOnline = status['isOnline'] ?? false);
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

    _socketService.sendPersonalMessage(
      widget.userId,
      content,
      MessageType.text.name,
      (response) {
        if (response['ok']) {
          _messageController.clear();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0700),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0700),
        elevation: 0,
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  backgroundImage: widget.userPhoto != null
                      ? CachedNetworkImageProvider(widget.userPhoto!)
                      : null,
                  child: widget.userPhoto == null
                      ? const Icon(Icons.person, color: Color(0xFFF5A623))
                      : null,
                ),
                if (_isOnline)
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
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: const TextStyle(
                    color: Color(0xFFFFF8F0),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: _isOnline ? Colors.green : const Color(0x8CFFF8F0),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: Color(0xFFF5A623)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.videocam, color: Color(0xFFF5A623)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFFF5A623)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isBlocked
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.block,
                          size: 64,
                          color: const Color(0xFFF5A623),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Cannot start conversation',
                          style: TextStyle(
                            color: Color(0xFFFFF8F0),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This user only accepts messages from people they follow.',
                          style: TextStyle(
                            color: Color(0x8CFFF8F0),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF5A623),
                            foregroundColor: const Color(0xFF140A00),
                          ),
                          child: const Text('Go Back'),
                        ),
                      ],
                    ),
                  )
                : _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFFF5A623)),
                      )
                    : _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  backgroundImage: widget.userPhoto != null
                                      ? CachedNetworkImageProvider(widget.userPhoto!)
                                      : null,
                                  radius: 48,
                                  child: widget.userPhoto == null
                                      ? const Icon(Icons.person, size: 48, color: Color(0xFFF5A623))
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  widget.userName,
                                  style: const TextStyle(
                                    color: Color(0xFFFFF8F0),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isOnline ? 'Online' : 'Offline',
                                  style: TextStyle(
                                    color: _isOnline ? Colors.green : const Color(0x8CFFF8F0),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Start a conversation',
                                  style: TextStyle(
                                    color: Color(0x47FFF8F0),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
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
          if (!_isBlocked)
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
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
