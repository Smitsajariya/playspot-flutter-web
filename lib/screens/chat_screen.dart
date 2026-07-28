import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../socket_service.dart';

class ChatScreen extends StatefulWidget {
  final String gameId;
  const ChatScreen({super.key, required this.gameId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final SocketService _socketService = SocketService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> _messages = [];
  String? _myUserId;
  String? _myName;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _myUserId = prefs.getString('ps_userId');
    final profileJson = prefs.getString('ps_profile');
    if (profileJson != null) {
      final profile = Map<String, dynamic>.from(
        (jsonDecode(profileJson) as Map)
      );
      _myName = profile['name'];
    }
    
    _socketService.connect();
    _socketService.onChatMessage((message) {
      if (message['gameId'] == widget.gameId) {
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final message = {
      'gameId': widget.gameId,
      'userId': _myUserId,
      'name': _myName ?? 'Player',
      'text': text,
      'ts': DateTime.now().millisecondsSinceEpoch,
    };

    _socketService.sendChat(widget.gameId, message);
    
    setState(() {
      _messages.add(message);
    });
    
    _messageController.clear();
    _scrollToBottom();
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

  String _formatTime(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
        title: const Text(
          'Game Chat',
          style: TextStyle(
            color: Color(0xFFFFF8F0),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _messages.isEmpty
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
                        const Text(
                          'No messages yet',
                          style: TextStyle(
                            color: Color(0x47FFF8F0),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Say hi to start the conversation!',
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
                      final isMe = message['userId'] == _myUserId;
                      final senderName = message['name'] ?? 'Player';
                      final text = message['text'] ?? '';
                      final timestamp = message['ts'] ?? DateTime.now().millisecondsSinceEpoch;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Padding(
                                padding: const EdgeInsets.only(left: 8, bottom: 4),
                                child: Text(
                                  senderName,
                                  style: const TextStyle(
                                    color: Color(0x8CFFF8F0),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            Row(
                              mainAxisAlignment: isMe
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              children: [
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? const Color(0xFFF5A623)
                                        : const Color(0xFF1A0C00),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        text,
                                        style: TextStyle(
                                          color: isMe
                                              ? const Color(0xFF140A00)
                                              : const Color(0xFFFFF8F0),
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTime(timestamp),
                                        style: TextStyle(
                                          color: isMe
                                              ? const Color(0x80140A00)
                                              : const Color(0x80FFF8F0),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          
          // Input bar
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
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: const Color(0xFF241200),
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
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5A623),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Color(0xFF140A00),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
