import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../socket_service.dart';
import 'chat_screen.dart';
import 'host_dashboard_screen.dart';
import 'qr_scanner_screen.dart';

class IngameScreen extends StatefulWidget {
  final String gameId;
  const IngameScreen({super.key, required this.gameId});

  @override
  State<IngameScreen> createState() => _IngameScreenState();
}

class _IngameScreenState extends State<IngameScreen> {
  final SocketService _socketService = SocketService();
  
  Map<String, dynamic>? _game;
  String? _myUserId;
  bool _isHost = false;
  bool _isLoading = true;
  bool _gameNotFound = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _myUserId = prefs.getString('ps_userId');
    
    _socketService.connect();
    _socketService.onGameUpdated((game) {
      if (game['id'] == widget.gameId) {
        setState(() {
          _game = game;
          _isHost = game['hostUserId'] == _myUserId;
          _isLoading = false;
          _gameNotFound = false;
        });
      }
    });
    
    _socketService.onKicked((data) {
      if (data['gameId'] == widget.gameId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You were removed from the game')),
        );
        Navigator.of(context).pop();
      }
    });
    
    // Load initial game data
    _socketService.getGames((games) {
      final game = games.firstWhere(
        (g) => g['id'] == widget.gameId,
        orElse: () => null,
      );
      if (game != null) {
        setState(() {
          _game = game;
          _isHost = game['hostUserId'] == _myUserId;
          _isLoading = false;
          _gameNotFound = false;
        });
      } else {
        // Game not found in initial load, wait for timeout
      }
    });
    
    // 10 second timeout for game not found
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isLoading && _game == null) {
        setState(() {
          _isLoading = false;
          _gameNotFound = true;
        });
      }
    });
  }

  String _getSportEmoji(String sport) {
    final emojis = {
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

  void _showQRCode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A0C00),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'My Check-in QR',
          style: TextStyle(color: Color(0xFFFFF8F0)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 250,
              height: 250,
              child: QrImageView(
                data: 'ps_checkin:$_myUserId',
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ID: ${_myUserId?.substring(0, 12)}...',
              style: const TextStyle(color: Color(0x8CFFF8F0)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFFF5A623)),
            ),
          ),
        ],
      ),
    );
  }

  void _showScanner() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A0C00),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          height: 400,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Scan Player QR',
                  style: TextStyle(
                    color: Color(0xFFFFF8F0),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'QR scanning temporarily unavailable',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFFF5A623)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _verifyPlayer(String qrData) {
    final playerId = qrData.startsWith('ps_checkin:') 
        ? qrData.substring(12) 
        : qrData;
    
    _socketService.verifyCheckin(
      widget.gameId,
      _myUserId ?? '',
      playerId,
      (response) {
      if (response['ok']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${response['playerName']} verified!'),
            backgroundColor: const Color(0xFFC8FF00),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${response['error'] ?? 'Verification failed'}'),
            backgroundColor: const Color(0xFFFF4D1C),
          ),
        );
      }
    });
  }

  void _showDashboard() {
    if (_game == null) return;
    
    final players = _game!['players'] as List<dynamic>? ?? [];
    final checkedIn = players.where((p) => p['checkedIn'] == true).length;
    final attendance = players.isNotEmpty ? (checkedIn / players.length * 100).round() : 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A0C00),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _game!['title'] ?? 'Game',
                        style: const TextStyle(
                          color: Color(0xFFFFF8F0),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard('Players', '${players.length}'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard('Checked In', '$checkedIn'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildAttendanceCard(attendance),
                      const SizedBox(height: 16),
                      // Host dashboard button
                      if (_isHost)
                        ElevatedButton.icon(
                          onPressed: () {
                            if (_game != null) {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => HostDashboardScreen(gameData: _game!),
                              );
                            }
                          },
                          icon: const Icon(Icons.dashboard),
                          label: const Text('Host Dashboard'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF5A623),
                            foregroundColor: const Color(0xFF140A00),
                          ),
                        ),
                      const SizedBox(height: 8),
                      // QR scanner button
                      if (_isHost)
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QRScannerScreen(gameId: widget.gameId),
                              ),
                            );
                          },
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Scan QR'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A0C00),
                            foregroundColor: const Color(0xFFF5A623),
                            side: const BorderSide(color: Color(0xFFF5A623)),
                          ),
                        ),
                      const SizedBox(height: 24),
                      const Text(
                        'Player Roster',
                        style: TextStyle(
                          color: Color(0xFFF5A623),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...players.map((player) {
                        final index = players.indexOf(player);
                        final playerMap = player as Map<String, dynamic>;
                        final isHost = index == 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: playerMap['photoUrl'] != null
                                  ? CachedNetworkImageProvider(playerMap['photoUrl'])
                                  : null,
                              child: playerMap['photoUrl'] == null
                                  ? const Icon(Icons.person, color: Color(0xFFF5A623))
                                  : null,
                            ),
                            title: Text(
                              playerMap['name'] ?? 'Player',
                              style: const TextStyle(color: Color(0xFFFFF8F0)),
                            ),
                            subtitle: Text(
                              playerMap['checkedIn'] == true ? '✅ Checked in' : '⏳ Not checked in',
                              style: const TextStyle(color: Color(0x8CFFF8F0)),
                            ),
                            trailing: isHost
                                ? const Text(
                                    'HOST',
                                    style: TextStyle(
                                      color: Color(0xFFF5A623),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF241200),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1AFFB93C)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFF5A623),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0x8CFFF8F0),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(int percentage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF241200),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1AFFB93C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Attendance',
                style: TextStyle(color: Color(0x8CFFF8F0)),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  color: Color(0xFFF5A623),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: const Color(0xFF1A0C00),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF5A623)),
            ),
          ),
        ],
      ),
    );
  }

  void _leaveGame() {
    final isHost = _isHost;
    final message = isHost 
        ? 'End game for everyone?' 
        : 'Leave this game?';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A0C00),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Confirm',
          style: TextStyle(color: Color(0xFFFFF8F0)),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Color(0x8CFFF8F0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFFF5A623)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (isHost) {
                _socketService.leaveGame(widget.gameId, _myUserId ?? '');
              } else {
                _socketService.leaveGame(widget.gameId, _myUserId ?? '');
              }
              Navigator.of(context).pop();
            },
            child: Text(
              isHost ? 'End Game' : 'Leave',
              style: const TextStyle(color: Color(0xFFFF4D1C)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_gameNotFound) {
      return Scaffold(
        backgroundColor: const Color(0xFF0E0700),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Color(0xFFFF4D1C),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Game not found',
                  style: TextStyle(
                    color: Color(0xFFFFF8F0),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This game may have ended or been cancelled.',
                  style: TextStyle(
                    color: Color(0x8CFFF8F0),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A623),
                    foregroundColor: const Color(0xFF140A00),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isLoading || _game == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0E0700),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFF5A623)),
        ),
      );
    }

    final sport = _game!['sport'] ?? 'unknown';
    final sportEmoji = _getSportEmoji(sport);
    final players = _game!['players'] as List<dynamic>? ?? [];
    final maxPlayers = _game!['maxPlayers'] ?? 10;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0700),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0700),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFFF8F0)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _game!['title'] ?? 'Game',
          style: const TextStyle(
            color: Color(0xFFFFF8F0),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Game info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      sportEmoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _game!['title'] ?? 'Game',
                            style: const TextStyle(
                              color: Color(0xFFFFF8F0),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5A623).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$sportEmoji ${_getSportName(sport)} · ${players.length}/$maxPlayers',
                              style: const TextStyle(
                                color: Color(0xFFF5A623),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Player list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index] as Map<String, dynamic>;
                final isHost = index == 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A0C00),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isHost ? const Color(0xFFF5A623) : const Color(0x1AFFB93C),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: player['photoUrl'] != null
                              ? CachedNetworkImageProvider(player['photoUrl'])
                              : null,
                          child: player['photoUrl'] == null
                              ? const Icon(Icons.person, color: Color(0xFFF5A623))
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                player['name'] ?? 'Player',
                                style: const TextStyle(
                                  color: Color(0xFFFFF8F0),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (isHost)
                                const Text(
                                  'Host',
                                  style: TextStyle(
                                    color: Color(0xFFF5A623),
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (player['checkedIn'] == true)
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFFC8FF00),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        'Chat',
                        Icons.chat,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(gameId: widget.gameId),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        'My QR',
                        Icons.qr_code,
                        _showQRCode,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (_isHost)
                      Expanded(
                        child: _buildActionButton(
                          'Scan Players',
                          Icons.qr_code_scanner,
                          _showScanner,
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    if (_isHost) const SizedBox(width: 8),
                    if (_isHost)
                      Expanded(
                        child: _buildActionButton(
                          'Dashboard',
                          Icons.dashboard,
                          _showDashboard,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _leaveGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A0C00),
                      foregroundColor: const Color(0xFFFF4D1C),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFFF4D1C)),
                      ),
                    ),
                    child: Text(
                      _isHost ? 'End Game' : 'Leave Game',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A0C00),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x1AFFB93C)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFF5A623)),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFFFF8F0),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSportName(String sport) {
    final names = {
      'football': 'Football',
      'cricket': 'Cricket',
      'basketball': 'Basketball',
      'badminton': 'Badminton',
      'volleyball': 'Volleyball',
      'tennis': 'Tennis',
      'running': 'Running',
      'cycling': 'Cycling',
      'frisbee': 'Frisbee',
      'hockey': 'Hockey',
      'kabaddi': 'Kabaddi',
    };
    return names[sport] ?? 'Sport';
  }

  @override
  void dispose() {
    super.dispose();
  }
}
