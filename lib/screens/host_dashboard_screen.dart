import 'package:flutter/material.dart';

class HostDashboardScreen extends StatelessWidget {
  final Map<String, dynamic> gameData;

  const HostDashboardScreen({super.key, required this.gameData});

  @override
  Widget build(BuildContext context) {
    final players = gameData['players'] as List<dynamic>? ?? [];
    final maxPlayers = gameData['maxPlayers'] ?? 10;
    final checkedIn = gameData['checkedIn'] as List<dynamic>? ?? [];
    final hostRating = gameData['hostRating'] ?? 4.5;
    final strikes = gameData['strikes'] ?? 0;

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
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFFFFF8F0)),
                  onPressed: () => Navigator.of(context).pop(),
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
}
