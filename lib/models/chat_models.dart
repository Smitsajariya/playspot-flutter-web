class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderPhoto;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isPinned;
  final bool isEdited;
  final String? replyToMessageId;
  final List<String> attachments;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderPhoto,
    required this.content,
    this.type = MessageType.text,
    required this.timestamp,
    this.isPinned = false,
    this.isEdited = false,
    this.replyToMessageId,
    this.attachments = const [],
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? 'Unknown',
      senderPhoto: json['senderPhoto'],
      content: json['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isPinned: json['isPinned'] ?? false,
      isEdited: json['isEdited'] ?? false,
      replyToMessageId: json['replyToMessageId'],
      attachments: List<String>.from(json['attachments'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhoto': senderPhoto,
      'content': content,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'isPinned': isPinned,
      'isEdited': isEdited,
      'replyToMessageId': replyToMessageId,
      'attachments': attachments,
    };
  }
}

enum MessageType {
  text,
  image,
  video,
  audio,
  file,
  system,
  announcement,
}

class ChatGroup {
  final String id;
  final String name;
  final String? photo;
  final List<String> memberIds;
  final String adminId;
  final String description;
  final DateTime createdAt;
  final String? announcement;
  final bool isPublic;
  final bool isGameGroup;
  final String? gameId;
  final bool isEventGroup;
  final String? eventId;
  final int? maxParticipants;
  final int memberCount;
  final bool isSearchable;

  ChatGroup({
    required this.id,
    required this.name,
    this.photo,
    required this.memberIds,
    required this.adminId,
    this.description = '',
    required this.createdAt,
    this.announcement,
    this.isPublic = false,
    this.isGameGroup = false,
    this.gameId,
    this.isEventGroup = false,
    this.eventId,
    this.maxParticipants,
    this.memberCount = 0,
    this.isSearchable = true,
  });

  factory ChatGroup.fromJson(Map<String, dynamic> json) {
    return ChatGroup(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Group',
      photo: json['photo'],
      memberIds: List<String>.from(json['memberIds'] ?? []),
      adminId: json['adminId'] ?? '',
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      announcement: json['announcement'],
      isPublic: json['isPublic'] ?? false,
      isGameGroup: json['isGameGroup'] ?? false,
      gameId: json['gameId'],
      isEventGroup: json['isEventGroup'] ?? false,
      eventId: json['eventId'],
      maxParticipants: json['maxParticipants'],
      memberCount: json['memberCount'] ?? json['memberIds']?.length ?? 0,
      isSearchable: json['isSearchable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'photo': photo,
      'memberIds': memberIds,
      'adminId': adminId,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'announcement': announcement,
      'isPublic': isPublic,
      'isGameGroup': isGameGroup,
      'gameId': gameId,
      'isEventGroup': isEventGroup,
      'eventId': eventId,
      'maxParticipants': maxParticipants,
      'memberCount': memberCount,
      'isSearchable': isSearchable,
    };
  }
}

class ChatConversation {
  final String id;
  final String name;
  final String? photo;
  final bool isGroup;
  final String? groupId;
  final String? otherUserId;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final bool isMuted;
  final bool isPinned;
  final List<String> onlineMemberIds;
  final bool isGameGroup;
  final bool isEventGroup;

  ChatConversation({
    required this.id,
    required this.name,
    this.photo,
    this.isGroup = false,
    this.groupId,
    this.otherUserId,
    this.lastMessage,
    this.unreadCount = 0,
    this.isMuted = false,
    this.isPinned = false,
    this.onlineMemberIds = const [],
    this.isGameGroup = false,
    this.isEventGroup = false,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Chat',
      photo: json['photo'],
      isGroup: json['isGroup'] ?? false,
      groupId: json['groupId'],
      otherUserId: json['otherUserId'],
      lastMessage: json['lastMessage'] != null && json['lastMessage'] is Map
          ? ChatMessage.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      isMuted: json['isMuted'] ?? false,
      isPinned: json['isPinned'] ?? false,
      onlineMemberIds: json['onlineMemberIds'] != null
          ? List<String>.from(json['onlineMemberIds'])
          : [],
      // Backend may not send these yet on the conversations list endpoint —
      // default to false so older payloads keep working unchanged.
      isGameGroup: json['isGameGroup'] ?? false,
      isEventGroup: json['isEventGroup'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'photo': photo,
      'isGroup': isGroup,
      'groupId': groupId,
      'otherUserId': otherUserId,
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'isMuted': isMuted,
      'isPinned': isPinned,
      'onlineMemberIds': onlineMemberIds,
      'isGameGroup': isGameGroup,
      'isEventGroup': isEventGroup,
    };
  }
}
