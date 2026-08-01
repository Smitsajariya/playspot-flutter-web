import 'package:flutter/material.dart';
import '../socket_service.dart';
import 'host_game_edit_screen.dart';

class HostDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> gameData;

  const HostDashboardScreen({super.key, required this.gameData});

  @override
  State<HostDashboardScreen> createState() => _HostDashboardScreenState();
}

class _HostDashboardScreenState extends State<HostDashboardScreen> {
  final SocketService _socketService = SocketService();
  bool _isCancelling = false;

  @override
  Widget build(BuildContext context) {
    final players = widget.gameData['players'] as List<dynamic>? ?? [];
    final maxPlayers = widget.gameData['maxPlayers'] ?? 10;
    final checkedIn = widget.gameData['checkedIn'] as List<dynamic>? ?? [];
    final hostRating = widget.gameData['hostRating'] ?? 4.5;
    final strikes = widget.gameData['strikes'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A0C00),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF5A623)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Host Dashboard',
                  style: TextStyle(
                    color: Color(0xFFF5A623),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFFF5A623)),
                      onPressed: () {
                        final gameId = widget.gameData['id']?.toString();
                        if (gameId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HostGameEditScreen(gameId: gameId),
                            ),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFFFFF8F0)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildStatRow('Players', '${players.length}/$maxPlayers'),
            const SizedBox(height: 12),
            _buildStatRow('Checked In', '${checkedIn.length}/${players.length}'),
            const SizedBox(height: 12),
            _buildStatRow('Check-in Rate', '${_getCheckInRate(players.length, checkedIn.length)}%'),
            const SizedBox(height: 12),
            _buildStatRow('Host Rating', '$hostRating ⭐'),
            const SizedBox(height: 12),
            _buildStatRow('Strikes', strikes.toString()),
            const SizedBox(height: 24),
            const Divider(color: Color(0x1AFFB93C)),
            const SizedBox(height: 16),
            const Text(
              'Potential Earnings',
              style: TextStyle(
                color: Color(0xFFF5A623),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${_calculateEarnings(players.length)}',
              style: const TextStyle(
                color: Color(0xFFFFF8F0),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCancelling ? null : _handleCancel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isCancelling
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Cancel Game',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0x8CFFF8F0),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFFFF8F0),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  int _getCheckInRate(int total, int checkedIn) {
    if (total == 0) return 0;
    return ((checkedIn / total) * 100).round();
  }

  int _calculateEarnings(int playerCount) {
    // Simple calculation: $5 per player
    return playerCount * 5;
  }

  void _handleCancel() async {
    final gameId = widget.gameData['id']?.toString();
    final userId = widget.gameData['hostUserId']?.toString();
    
    if (gameId == null || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Missing game ID or user ID')),
      );
      return;
    }

    setState(() => _isCancelling = true);

    _socketService.cancelGame(gameId, userId, (response) {
      setState(() => _isCancelling = false);
      
      if (response['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Game cancelled successfully')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response['error'] ?? 'Failed to cancel game'}')),
        );
      }
    });
  }
}
