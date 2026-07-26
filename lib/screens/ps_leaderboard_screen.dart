import 'package:flutter/material.dart';
import '../theme/playspot_theme.dart';

class _LbEntry {
  final int rank;
  final String name;
  final String emoji;
  final String meta;
  final int points;
  const _LbEntry(this.rank, this.name, this.emoji, this.meta, this.points);
}

const _demoLeaderboard = <_LbEntry>[
  _LbEntry(1, 'Lukas M.', '🥇', '24 games played', 1280),
  _LbEntry(2, 'Maya R.', '🥈', '19 games played', 1110),
  _LbEntry(3, 'Jonas K.', '🥉', '21 games played', 980),
  _LbEntry(4, 'Sara T.', '🙂', '14 games played', 740),
  _LbEntry(5, 'Devon P.', '🙂', '11 games played', 690),
];

class PSLeaderboardScreen extends StatelessWidget {
  const PSLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: PSGradients.screenLeaderboard),
      child: ListView(
        padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 32, 24, 110),
        children: [
          const Text('🏆 Leaderboard', style: PSText.screenTitle),
          const SizedBox(height: 6),
          const Text('Top players in your area this month', style: PSText.bodyDim),
          const SizedBox(height: 20),
          for (final e in _demoLeaderboard) _lbRow(e),
        ],
      ),
    );
  }

  Widget _lbRow(_LbEntry e) {
    Color rankColor = PSColors.inkMuted;
    if (e.rank == 1) rankColor = const Color(0xFFFFD060);
    if (e.rank == 2) rankColor = const Color(0xFFC0C0C0);
    if (e.rank == 3) rankColor = const Color(0xFFCD7F32);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: PSColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PSColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('${e.rank}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: rankColor)),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: PSColors.surface, shape: BoxShape.circle),
            child: Center(child: Text(e.emoji, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.name, style: const TextStyle(fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w700, fontSize: 14, color: PSColors.ink)),
                Text(e.meta, style: const TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 12, color: PSColors.inkDim)),
              ],
            ),
          ),
          Text('${e.points}', style: const TextStyle(fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w800, fontSize: 16, color: PSColors.gold)),
        ],
      ),
    );
  }
}
