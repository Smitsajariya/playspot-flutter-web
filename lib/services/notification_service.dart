import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../socket_service.dart';

enum PSNotificationType { joinRequest, gameActivity, system }

class NotificationItem {
  final String id;
  final PSNotificationType type;
  final String title;
  final String body;
  final String emoji;
  final String? avatarUrl;
  final DateTime timestamp;
  final bool read;
  final String? groupId;
  final String? groupName;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.emoji,
    this.avatarUrl,
    required this.timestamp,
    this.read = false,
    this.groupId,
    this.groupName,
  });

  NotificationItem copyWith({bool? read}) => NotificationItem(
        id: id,
        type: type,
        title: title,
        body: body,
        emoji: emoji,
        avatarUrl: avatarUrl,
        timestamp: timestamp,
        read: read ?? this.read,
        groupId: groupId,
        groupName: groupName,
      );

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? '',
      type: PSNotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PSNotificationType.system,
      ),
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      emoji: json['emoji'] ?? '🔔',
      avatarUrl: json['avatarUrl'],
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      read: json['read'] ?? false,
      groupId: json['groupId'],
      groupName: json['groupName'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'body': body,
        'emoji': emoji,
        'avatarUrl': avatarUrl,
        'timestamp': timestamp.toIso8601String(),
        'read': read,
        'groupId': groupId,
        'groupName': groupName,
      };
}

/// Light-backend notification feed.
///
/// PlaySpot's socket server has no dedicated `notifications` event yet, so
/// this service synthesizes a local feed from events we already receive
/// (new games, games filling up, group RSVP/system messages) and persists
/// it to SharedPreferences so it survives navigation and app restarts.
///
/// If/when a real `onNotification` socket event exists server-side, wire it
/// into `attachSocketListeners` below and this UI needs no changes.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const _prefsKey = 'ps_notifications';
  static const _maxItems = 50;

  final ValueNotifier<List<NotificationItem>> items = ValueNotifier([]);
  bool _loaded = false;
  bool _listenersAttached = false;
  final Map<String, int> _lastKnownPlayerCounts = {};

  int get unreadCount => items.value.where((n) => !n.read).length;

  Future<void> init() async {
    if (_loaded) return;
    _loaded = true;
    await _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        final list = (jsonDecode(raw) as List)
            .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
            .toList();
        items.value = list;
      }
    } catch (e) {
      debugPrint('NotificationService load error: $e');
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode(items.value.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('NotificationService persist error: $e');
    }
  }

  Future<void> add(NotificationItem item) async {
    // Avoid dumping duplicate spam notifications for the same game/group
    // within a short window.
    final recentDupe = items.value.any((n) =>
        n.groupId != null &&
        n.groupId == item.groupId &&
        n.title == item.title &&
        DateTime.now().difference(n.timestamp) < const Duration(minutes: 2));
    if (recentDupe) return;

    final updated = [item, ...items.value];
    items.value = updated.length > _maxItems
        ? updated.sublist(0, _maxItems)
        : updated;
    await _persist();
  }

  Future<void> markAllRead() async {
    items.value = items.value.map((n) => n.copyWith(read: true)).toList();
    await _persist();
  }

  Future<void> markRead(String id) async {
    items.value = items.value
        .map((n) => n.id == id ? n.copyWith(read: true) : n)
        .toList();
    await _persist();
  }

  /// Hooks into existing socket events to generate headline-style
  /// notifications. Safe to call multiple times — only attaches once.
  void attachSocketListeners(SocketService socket) {
    if (_listenersAttached) return;
    _listenersAttached = true;

    socket.onNewGameCreated((game) {
      try {
        final title = (game['title'] as String?)?.trim();
        final sport = (game['sport'] as String?) ?? 'game';
        add(NotificationItem(
          id: 'newgame_${game['id']}_${DateTime.now().millisecondsSinceEpoch}',
          type: PSNotificationType.gameActivity,
          title: 'New game near you',
          body: (title != null && title.isNotEmpty)
              ? '$title just went live 📍'
              : 'A new $sport game just went live near you 📍',
          emoji: _sportEmoji(sport),
          avatarUrl: game['photoUrl'],
          timestamp: DateTime.now(),
          groupId: game['id']?.toString(),
          groupName: title,
        ));
      } catch (e) {
        debugPrint('notif onNewGameCreated error: $e');
      }
    });

    socket.onGamesUpdate((games) {
      try {
        if (games is! List) return;
        for (final game in games) {
          final id = game['id']?.toString();
          if (id == null) continue;
          final players = (game['players'] as List?)?.length ??
              (game['playerCount'] as int?) ??
              0;
          final maxPlayers = (game['maxPlayers'] as int?) ?? 0;
          final prev = _lastKnownPlayerCounts[id];
          _lastKnownPlayerCounts[id] = players;

          if (prev != null && players > prev && maxPlayers > 0) {
            final spotsLeft = maxPlayers - players;
            final title = (game['title'] as String?)?.trim() ?? 'Your game';
            if (spotsLeft <= 2 && spotsLeft > 0) {
              add(NotificationItem(
                id: 'heatup_${id}_$players',
                type: PSNotificationType.gameActivity,
                title: 'Activity Heating Up 🔥',
                body: '$title is filling up — only $spotsLeft spot${spotsLeft == 1 ? '' : 's'} left!',
                emoji: '🔥',
                timestamp: DateTime.now(),
                groupId: id,
                groupName: title,
              ));
            } else if (spotsLeft == 0) {
              add(NotificationItem(
                id: 'full_$id',
                type: PSNotificationType.gameActivity,
                title: 'Game full',
                body: '$title just filled up all its spots.',
                emoji: '✅',
                timestamp: DateTime.now(),
                groupId: id,
                groupName: title,
              ));
            }
          }
        }
      } catch (e) {
        debugPrint('notif onGamesUpdate error: $e');
      }
    });

    socket.onGroupMessage((msg) {
      try {
        final content = (msg['content'] as String?) ?? '';
        final senderName = (msg['senderName'] as String?) ?? 'Someone';
        final groupId = msg['groupId']?.toString();
        // System RSVP messages look like "🙌 I'm in!" — surface those as
        // join-request-style activity so hosts see who's committing.
        if (content.contains("I'm in") || content.toLowerCase().contains('rsvp')) {
          add(NotificationItem(
            id: 'rsvp_${groupId}_${msg['id'] ?? DateTime.now().millisecondsSinceEpoch}',
            type: PSNotificationType.joinRequest,
            title: '$senderName RSVP\'d',
            body: '$senderName is in for the game. You in too?',
            emoji: '🙌',
            avatarUrl: msg['senderPhoto'],
            timestamp: DateTime.now(),
            groupId: groupId,
          ));
        }
      } catch (e) {
        debugPrint('notif onGroupMessage error: $e');
      }
    });
  }

  String _sportEmoji(String sport) {
    const emojis = {
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
}
