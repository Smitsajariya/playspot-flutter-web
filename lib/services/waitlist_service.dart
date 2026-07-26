import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../socket_service.dart';
import 'notification_service.dart';

/// Local-only waitlist: PlaySpot's backend has no `waitlist:*` events yet,
/// so this tracks "which full games I've asked to be notified about" in
/// SharedPreferences, and watches the same `games:update` stream
/// `NotificationService` already listens to. When a game the user is
/// waitlisted on drops below capacity, it's treated as "a spot opened up" —
/// the user is auto-joined (best-effort `player:join` emit) and notified.
///
/// If a real backend waitlist queue exists later (so promotion is
/// server-ordered/fair across multiple waitlisted users instead of
/// first-client-to-notice), swap `checkForPromotions` for a
/// `waitlist:promoted` listener — callers of `join`/`leave`/`isWaitlisted`
/// don't need to change.
class WaitlistService {
  static const _key = 'ps_waitlist_game_ids';
  static bool _listenersAttached = false;

  static Future<Set<String>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    try {
      return Set<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return {};
    }
  }

  static Future<void> _save(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(ids.toList()));
  }

  static Future<bool> isWaitlisted(String gameId) async {
    final ids = await _load();
    return ids.contains(gameId);
  }

  static Future<void> join(String gameId) async {
    final ids = await _load();
    ids.add(gameId);
    await _save(ids);
  }

  static Future<void> leave(String gameId) async {
    final ids = await _load();
    ids.remove(gameId);
    await _save(ids);
  }

  /// Attach once per app session — mirrors `NotificationService.attachSocketListeners`.
  static void attachSocketListeners(SocketService socket) {
    if (_listenersAttached) return;
    _listenersAttached = true;
    socket.onGamesUpdate((games) => checkForPromotions(games, socket));
  }

  static Future<void> checkForPromotions(dynamic games, SocketService socket) async {
    try {
      if (games is! List) return;
      final waitlisted = await _load();
      if (waitlisted.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('ps_userId');
      final profileJson = prefs.getString('ps_profile');
      final profileName = profileJson != null
          ? (jsonDecode(profileJson)['name'] as String?) ?? 'Player'
          : 'Player';

      for (final g in games) {
        final id = g['id']?.toString();
        if (id == null || !waitlisted.contains(id)) continue;

        final playerCount = (g['players'] as List?)?.length ?? (g['playerCount'] as int?) ?? 0;
        final maxPlayers = (g['maxPlayers'] as int?) ?? 0;
        if (maxPlayers <= 0 || playerCount >= maxPlayers) continue;

        // A spot is free — promote.
        waitlisted.remove(id);
        await _save(waitlisted);

        if (userId != null) {
          socket.joinGame(id, {'userId': userId, 'name': profileName}, (_) {});
        }

        final title = (g['title'] as String?)?.trim() ?? 'A game';
        await NotificationService().add(NotificationItem(
          id: 'waitlist_promo_${id}_${DateTime.now().millisecondsSinceEpoch}',
          type: PSNotificationType.gameActivity,
          title: 'A spot opened up! 🎉',
          body: "$title had a spot free up — you're in from the waitlist.",
          emoji: '🎉',
          timestamp: DateTime.now(),
          groupId: id,
          groupName: title,
        ));
      }
    } catch (e) {
      debugPrint('WaitlistService.checkForPromotions error: $e');
    }
  }
}
