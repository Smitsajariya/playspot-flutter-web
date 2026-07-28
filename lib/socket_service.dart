import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  static const String _serverUrl = 'https://playspot-backend.onrender.com';
  static bool _useMock = false;
  static String? lastConnectionError;
  final Map<String, List<Function(dynamic)>> _mockListeners = {};
  int _retryCount = 0;
  static const int _maxRetries = 3;
  Function(bool)? _onConnectionStatusChanged;

  static void setMockMode(bool useMock) {
    _useMock = useMock;
  }

  void setConnectionStatusCallback(Function(bool) callback) {
    _onConnectionStatusChanged = callback;
  }

  io.Socket get socket {
    if (kDebugMode && _useMock) {
      // Mock mode - return a mock socket that doesn't throw
      return _MockSocket();
    }
    _socket ??= io.io(_serverUrl, _buildOptions());
    return _socket!;
  }

  /// Websocket-only was failing hard on web builds: Render's free tier
  /// spins the backend down when idle (cold start can take 30-50s), and a
  /// websocket-only handshake has no fallback while it wakes up. Allowing
  /// polling as a fallback transport plus a longer connect timeout lets the
  /// client ride out that cold start instead of immediately erroring with
  /// "Could not connect".
  dynamic _buildOptions() {
    return io.OptionBuilder()
        .setTransports(['websocket', 'polling'])
        .setTimeout(20000)
        .enableReconnection()
        .setReconnectionAttempts(5)
        .setReconnectionDelay(3000)
        .build();
  }

  void connect() {
    if (kDebugMode && _useMock) {
      // Mock mode - don't connect
      _notifyConnectionStatus(true);
      return;
    }
    if (_socket == null || !_socket!.connected) {
      _socket = io.io(_serverUrl, _buildOptions());
      
      _socket!.onConnect((_) {
        _retryCount = 0;
        _notifyConnectionStatus(true);
        print('Socket connected successfully');
      });
      
      _socket!.onDisconnect((_) {
        _notifyConnectionStatus(false);
        print('Socket disconnected');
        _attemptReconnect();
      });
      
      _socket!.onConnectError((error) {
        lastConnectionError = error.toString();
        _notifyConnectionStatus(false);
        print('Socket connection error: $error');
        _attemptReconnect();
      });
      
      _socket!.onError((error) {
        lastConnectionError = error.toString();
        print('Socket error: $error');
      });
    }
  }

  void _attemptReconnect() {
    if (_retryCount < _maxRetries) {
      _retryCount++;
      // Render's free-tier cold start can take up to ~50s, so back off
      // slower than before (was retryCount*2s, maxing out at 6s total —
      // nowhere near enough to outlast a cold start).
      final delaySeconds = (_retryCount * 8).clamp(5, 30);
      print('Attempting to reconnect... ($_retryCount/$_maxRetries), waiting ${delaySeconds}s');
      Future.delayed(Duration(seconds: delaySeconds), () {
        connect();
      });
    } else {
      print('Max reconnection attempts reached');
    }
  }

  void _notifyConnectionStatus(bool connected) {
    _onConnectionStatusChanged?.call(connected);
  }

  bool get isConnected => _socket?.connected ?? false;

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _mockListeners.clear();
  }

  // Socket methods matching the exact event names from the backend
  Future<void> getGames(Function(dynamic) callback) async {
    if (kDebugMode && _useMock) {
      // Return mock games data with proper structure
      Future.delayed(const Duration(milliseconds: 500), () {
        callback([
          {
            'id': '1',
            'sport': 'basketball',
            'sportEmoji': '🏀',
            'title': 'Basketball Pickup',
            'hostName': 'John',
            'playerCount': 8,
            'maxPlayers': 10,
            'skillLevel': 'Intermediate',
            'isLive': true,
            'timeLabel': 'Live now',
            'distanceLabel': '0.5 km away',
            'isMyGame': false,
            'category': 'sports',
            'type': 'sports',
            'name': 'Basketball Pickup',
            'location': 'Central Park',
          },
          {
            'id': '2',
            'sport': 'tennis',
            'sportEmoji': '🎾',
            'title': 'Tennis Match',
            'hostName': 'Sarah',
            'playerCount': 4,
            'maxPlayers': 4,
            'skillLevel': 'Beginner',
            'isLive': false,
            'timeLabel': 'Today, 6:00 PM',
            'distanceLabel': '1.2 km away',
            'isMyGame': false,
            'category': 'sports',
            'type': 'sports',
            'name': 'Tennis Match',
            'location': 'Court 1',
          },
        ]);
      });
      return;
    }
    
    try {
      final completer = Completer<dynamic>();
      final timer = Timer(const Duration(seconds: 15), () {
        if (!completer.isCompleted) {
          completer.complete([]);
        }
      });
      socket.emitWithAck('games:get', {}, ack: (response) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete(response);
      });
      final result = await completer.future;
      callback(result);
    } catch (e) {
      callback([]);
    }
  }

  void createGame(Map<String, dynamic> data, Function(dynamic) callback) async {
    if (kDebugMode && _useMock) {
      Future.delayed(const Duration(milliseconds: 500), () {
        callback({'ok': true, 'game': {'id': 'mock_game_${DateTime.now().millisecondsSinceEpoch}'}});
      });
      return;
    }
    
    // Check connection and connect if needed
    if (!socket.connected) {
      connect();
      // Wait a bit for connection to establish
      await Future.delayed(const Duration(seconds: 2));
    }
    
    try {
      final completer = Completer<dynamic>();
      final timer = Timer(const Duration(seconds: 30), () {
        if (!completer.isCompleted) {
          completer.complete({'ok': false, 'error': 'Server is waking up, please try again in a few seconds'});
        }
      });
      socket.emitWithAck('host:create', data, ack: (response) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete(response);
      });
      final result = await completer.future;
      callback(result);
    } catch (e) {
      callback({'ok': false, 'error': 'Connection error: $e'});
    }
  }

  void joinGame(String gameId, Map<String, dynamic> player, Function(dynamic) callback) async {
    if (kDebugMode && _useMock) {
      Future.delayed(const Duration(milliseconds: 500), () {
        callback({'ok': true, 'gameId': gameId});
      });
      return;
    }
    
    // Check connection and connect if needed
    if (!socket.connected) {
      connect();
      // Wait a bit for connection to establish
      await Future.delayed(const Duration(seconds: 2));
    }
    
    try {
      final completer = Completer<dynamic>();
      final timer = Timer(const Duration(seconds: 30), () {
        if (!completer.isCompleted) {
          completer.complete({'ok': false, 'error': 'Server is waking up, please try again in a few seconds'});
        }
      });
      socket.emitWithAck('player:join', {'gameId': gameId, ...player}, ack: (response) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete(response);
      });
      final result = await completer.future;
      callback(result);
    } catch (e) {
      callback({'ok': false, 'error': 'Connection error: $e'});
    }
  }

  void leaveGame(String gameId, String userId) {
    if (kDebugMode && _useMock) {
      return;
    }
    socket.emit('player:leave', {'gameId': gameId, 'userId': userId});
  }

  void kickPlayer(String gameId, String userId, String targetId) {
    if (kDebugMode && _useMock) {
      return;
    }
    socket.emit('host:kick', {'gameId': gameId, 'userId': userId, 'playerId': targetId});
  }

  Future<void> getEvents(Function(dynamic) callback) async {
    if (kDebugMode && _useMock) {
      Future.delayed(const Duration(milliseconds: 500), () {
        callback([
          {'id': '1', 'name': 'Sports Festival', 'date': '2024-07-15', 'attendees': 150},
          {'id': '2', 'name': 'Marathon', 'date': '2024-08-01', 'attendees': 500},
        ]);
      });
      return;
    }
    
    try {
      final completer = Completer<dynamic>();
      final timer = Timer(const Duration(seconds: 15), () {
        if (!completer.isCompleted) {
          completer.complete([]);
        }
      });
      socket.emitWithAck('events:get', {}, ack: (response) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete(response);
      });
      final result = await completer.future;
      callback(result);
    } catch (e) {
      callback([]);
    }
  }

  void createEvent(Map<String, dynamic> data, Function(dynamic) callback) async {
    if (kDebugMode && _useMock) {
      Future.delayed(const Duration(milliseconds: 500), () {
        callback({'ok': true, 'event': {'id': 'mock_event_${DateTime.now().millisecondsSinceEpoch}'}});
      });
      return;
    }
    
    try {
      final completer = Completer<dynamic>();
      final timer = Timer(const Duration(seconds: 30), () {
        if (!completer.isCompleted) {
          completer.complete({'ok': false, 'error': 'Server is waking up, please try again in a few seconds'});
        }
      });
      socket.emitWithAck('event:create', data, ack: (response) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete(response);
      });
      final result = await completer.future;
      callback(result);
    } catch (e) {
      callback({'ok': false, 'error': 'Connection error: $e'});
    }
  }

  void joinEvent(String eventId, String userId, Function(dynamic) callback) async {
    if (kDebugMode && _useMock) {
      Future.delayed(const Duration(milliseconds: 500), () {
        callback({'ok': true, 'eventId': eventId});
      });
      return;
    }
    
    try {
      final completer = Completer<dynamic>();
      final timer = Timer(const Duration(seconds: 30), () {
        if (!completer.isCompleted) {
          completer.complete({'ok': false, 'error': 'Server is waking up, please try again in a few seconds'});
        }
      });
      socket.emitWithAck('event:join', {'eventId': eventId, 'userId': userId}, ack: (response) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete(response);
      });
      final result = await completer.future;
      callback(result);
    } catch (e) {
      callback({'ok': false, 'error': 'Connection error: $e'});
    }
  }

  void verifyCheckin(String gameId, String hostId, String playerId, Function(dynamic) callback) async {
    if (kDebugMode && _useMock) {
      Future.delayed(const Duration(milliseconds: 500), () {
        callback({'ok': true, 'verified': true});
      });
      return;
    }
    
    try {
      final completer = Completer<dynamic>();
      final timer = Timer(const Duration(seconds: 30), () {
        if (!completer.isCompleted) {
          completer.complete({'ok': false, 'error': 'Server is waking up, please try again in a few seconds'});
        }
      });
      socket.emitWithAck('checkin:verify', {'gameId': gameId, 'hostUserId': hostId, 'playerUserId': playerId}, ack: (response) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete(response);
      });
      final result = await completer.future;
      callback(result);
    } catch (e) {
      callback({'ok': false, 'error': 'Connection error: $e'});
    }
  }

  void sendChat(String gameId, Map<String, dynamic> message) {
    if (kDebugMode && _useMock) {
      return;
    }
    socket.emit('chat:send', {'gameId': gameId, ...message});
  }

  void onGameUpdated(Function(dynamic) callback) {
    if (kDebugMode && _useMock) {
      return;
    }
    socket.on('game:update', callback);
  }

  void onChatMessage(Function(dynamic) callback) {
    if (kDebugMode && _useMock) {
      return;
    }
    socket.on('chat:message', callback);
  }

  void onKicked(Function(dynamic) callback) {
    if (kDebugMode && _useMock) {
      return;
    }
    socket.on('game:kicked', callback);
  }

  void onGamesUpdate(Function(dynamic) callback) {
    if (kDebugMode && _useMock) {
      return;
    }
    socket.on('games:update', callback);
  }

  void onEventsUpdate(Function(dynamic) callback) {
    if (kDebugMode && _useMock) {
      return;
    }
    socket.on('events:update', callback);
  }

  // Chat methods
  Future<void> getConversations(Function(dynamic) callback) async {
    if (kDebugMode && _useMock) {
      Future.delayed(const Duration(milliseconds: 500), () {
        callback([
          {'id': '1', 'name': 'Basketball Group', 'lastMessage': 'See you there!', 'unread': 2},
          {'id': '2', 'name': 'Sarah Chen', 'lastMessage': 'Great game!', 'unread': 0},
        ]);
      });
      return;
    }
    
    try {
      final completer = Completer<dynamic>();
      final timer = Timer(const Duration(seconds: 15), () {
        if (!completer.isCompleted) {
          completer.complete([]);
        }
      });
      socket.emitWithAck('conversations:get', {}, ack: (response) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete(response);
      });
      final result = await completer.future;
      callback(result);
    } catch (e) {
      callback([]);
    }
  }

  Future<void> getGroupMessages(String groupId, Function(dynamic) callback) async {
    if (kDebugMode && _useMock) {
      Future.delayed(const Duration(milliseconds: 500), () {
        callback([
          {'id': '1', 'sender': 'John', 'content': 'Hey everyone!', 'timestamp': '10:30 AM'},
          {'id': '2', 'sender': 'Sarah', 'content': 'Ready for the game?', 'timestamp': '10:32 AM'},
        ]);
      });
      return;
    }
    
    try {
      final completer = Completer<dynamic>();
      final timer = Timer(const Duration(seconds: 15), () {
        if (!completer.isCompleted) {
          completer.complete([]);
        }
      });
      socket.emitWithAck('group:messages:get', {'groupId': groupId}, ack: (response) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete(response);
      });
      final result = await completer.future;
      callback(result);
    } catch (e) {
      callback([]);
    }
  }

  Future<void> getPersonalMessages(String userId, Function(dynamic) callback) async {
    if (kDebugMode && _useMock) {
      Future.delayed(const Duration(milliseconds: 500), () {
        callback([
          {'id': '1', 'sender': userId, 'content': 'Hi there!', 'timestamp': '10:30 AM'},
          {'id': '2', 'sender': 'other', 'content': 'Hello!', 'timestamp': '10:31 AM'},
        ]);
      });
      return;
    }
    
    try {
      final completer = Completer<dynamic>();
      final timer = Timer(const Duration(seconds: 15), () {
        if (!completer.isCompleted) {
          completer.complete([]);
        }
      });
      socket.emitWithAck('personal:messages:get', {'userId': userId}, ack: (response) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete(response);
      });
      final result = await completer.future;
      callback(result);
    } catch (e) {
      callback([]);
    }
  }

  void sendGroupMessage(String groupId, String content, String type, Function(dynamic) callback) async {
    if (kDebugMode && _useMock) {
      Future.delayed(const Duration(milliseconds: 500), () {
        callback({'ok': true, 'messageId': 'mock_msg_${DateTime.now().millisecondsSinceEpoch}'});
      });
      return;
    }
    
    try {
      final completer = Completer<dynamic>();
      final timer = Timer(const Duration(seconds: 30), () {
        if (!completer.isCompleted) {
          completer.complete({'ok': false, 'error': 'Server is waking up, please try again in a few seconds'});
        }
      });
      socket.emitWithAck('group:message:send', {'groupId': groupId, 'content': content, 'type': type}, ack: (response) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete(response);
      });
      final result = await completer.future;
      callback(result);
    } catch (e) {
      callback({'ok': false, 'error': 'Connection error: $e'});
    }
  }

  void sendPersonalMessage(String userId, String content, String type, Function(dynamic) callback) async {
    if (kDebugMode && _useMock) {
      Future.delayed(const Duration(milliseconds: 500), () {
        callback({'ok': true, 'messageId': 'mock_msg_${DateTime.now().millisecondsSinceEpoch}'});
      });
      return;
    }
    
    try {
      final completer = Completer<dynamic>();
      final timer = Timer(const Duration(seconds: 30), () {
        if (!completer.isCompleted) {
          completer.complete({'ok': false, 'error': 'Server is waking up, please try again in a few seconds'});
        }
      });
      socket.emitWithAck('personal:message:send', {'userId': userId, 'content': content, 'type': type}, ack: (response) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete(response);
      });
      final result = await completer.future;
      callback(result);
    } catch (e) {
      callback({'ok': false, 'error': 'Connection error: $e'});
    }
  }

  void createGroup({
    required String name,
    required String description,
    required String announcement,
    required bool isPublic,
    required bool isSearchable,
    required bool isEventGroup,
    String? eventId,
    int? maxParticipants,
    required Function(dynamic) callback,
  }) async {
    if (kDebugMode && _useMock) {
      Future.delayed(const Duration(milliseconds: 500), () {
        callback({'ok': true, 'group': {'id': 'mock_group_${DateTime.now().millisecondsSinceEpoch}'}});
      });
      return;
    }
    
    try {
      final completer = Completer<dynamic>();
      final timer = Timer(const Duration(seconds: 30), () {
        if (!completer.isCompleted) {
          completer.complete({'ok': false, 'error': 'Server is waking up, please try again in a few seconds'});
        }
      });
      socket.emitWithAck('group:create', {
        'name': name,
        'description': description,
        'announcement': announcement,
        'isPublic': isPublic,
        'isSearchable': isSearchable,
        'isEventGroup': isEventGroup,
        'eventId': eventId,
        'maxParticipants': maxParticipants,
      }, ack: (response) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete(response);
      });
      final result = await completer.future;
      callback(result);
    } catch (e) {
      callback({'ok': false, 'error': 'Connection error: $e'});
    }
  }

  Future<void> searchPublicGroups(String query, Function(dynamic) callback) async {
    if (kDebugMode && _useMock) {
      Future.delayed(const Duration(milliseconds: 500), () {
        callback([
          {'id': '1', 'name': 'Basketball Lovers', 'members': 150},
          {'id': '2', 'name': 'Tennis Players', 'members': 89},
        ]);
      });
      return;
    }
    
    try {
      final completer = Completer<dynamic>();
      final timer = Timer(const Duration(seconds: 15), () {
        if (!completer.isCompleted) {
          completer.complete([]);
        }
      });
      socket.emitWithAck('groups:search', {'query': query}, ack: (response) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete(response);
      });
      final result = await completer.future;
      callback(result);
    } catch (e) {
      callback([]);
    }
  }

  void joinPublicGroup(String groupId, Function(dynamic) callback) async {
    if (kDebugMode && _useMock) {
      Future.delayed(const Duration(milliseconds: 500), () {
        callback({'ok': true, 'groupId': groupId});
      });
      return;
    }
    
    try {
      final completer = Completer<dynamic>();
      final timer = Timer(const Duration(seconds: 30), () {
        if (!completer.isCompleted) {
          completer.complete({'ok': false, 'error': 'Server is waking up, please try again in a few seconds'});
        }
      });
      socket.emitWithAck('group:join', {'groupId': groupId}, ack: (response) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete(response);
      });
      final result = await completer.future;
      callback(result);
    } catch (e) {
      callback({'ok': false, 'error': 'Connection error: $e'});
    }
  }

  Future<void> getGroupInfo(String groupId, Function(dynamic) callback) async {
    if (kDebugMode && _useMock) {
      Future.delayed(const Duration(milliseconds: 500), () {
        callback({
          'id': groupId,
          'name': 'Mock Group',
          'description': 'A mock group for testing',
          'members': 50,
        });
      });
      return;
    }
    
    try {
      final completer = Completer<dynamic>();
      final timer = Timer(const Duration(seconds: 15), () {
        if (!completer.isCompleted) {
          completer.complete({});
        }
      });
      socket.emitWithAck('group:info:get', {'groupId': groupId}, ack: (response) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete(response);
      });
      final result = await completer.future;
      callback(result);
    } catch (e) {
      callback({});
    }
  }

  void leaveGroup(String groupId, Function(dynamic) callback) async {
    if (kDebugMode && _useMock) {
      Future.delayed(const Duration(milliseconds: 500), () {
        callback({'ok': true, 'groupId': groupId});
      });
      return;
    }
    
    try {
      final completer = Completer<dynamic>();
      final timer = Timer(const Duration(seconds: 30), () {
        if (!completer.isCompleted) {
          completer.complete({'ok': false, 'error': 'Server is waking up, please try again in a few seconds'});
        }
      });
      socket.emitWithAck('group:leave', {'groupId': groupId}, ack: (response) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete(response);
      });
      final result = await completer.future;
      callback(result);
    } catch (e) {
      callback({'ok': false, 'error': 'Connection error: $e'});
    }
  }

  Future<void> getUserStatus(String userId, Function(dynamic) callback) async {
    if (kDebugMode && _useMock) {
      Future.delayed(const Duration(milliseconds: 500), () {
        callback({'userId': userId, 'online': true, 'lastSeen': DateTime.now().toIso8601String()});
      });
      return;
    }
    
    try {
      final completer = Completer<dynamic>();
      final timer = Timer(const Duration(seconds: 15), () {
        if (!completer.isCompleted) {
          completer.complete({});
        }
      });
      socket.emitWithAck('user:status:get', {'userId': userId}, ack: (response) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete(response);
      });
      final result = await completer.future;
      callback(result);
    } catch (e) {
      callback({});
    }
  }

  void onNewMessage(Function(dynamic) callback) {
    if (kDebugMode && _useMock) {
      return;
    }
    socket.on('message:new', callback);
  }

  void onGroupMessage(Function(dynamic) callback) {
    if (kDebugMode && _useMock) {
      return;
    }
    socket.on('group:message', callback);
  }

  void onPersonalMessage(Function(dynamic) callback) {
    if (kDebugMode && _useMock) {
      return;
    }
    socket.on('personal:message', callback);
  }

  void onGroupUpdated(Function(dynamic) callback) {
    if (kDebugMode && _useMock) {
      return;
    }
    socket.on('group:update', callback);
  }

  void onUserStatusChanged(Function(dynamic) callback) {
    if (kDebugMode && _useMock) {
      return;
    }
    socket.on('user:status:changed', callback);
  }

  void onEventUpdate(Function(dynamic) callback) {
    if (kDebugMode && _useMock) {
      return;
    }
    socket.on('event:update', callback);
  }

  void onNewGameCreated(Function(dynamic) callback) {
    if (kDebugMode && _useMock) {
      return;
    }
    socket.on('game:created', callback);
  }
}

// Mock socket class for web testing
class _MockSocket implements io.Socket {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Do nothing for all socket operations in mock mode
    return null;
  }
}
