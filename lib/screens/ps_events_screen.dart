import 'package:flutter/material.dart';
import '../theme/playspot_theme.dart';
import '../models/ps_models.dart';

class PSEventsScreen extends StatelessWidget {
  const PSEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: PSColors.bg,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 32, 20, 110),
        children: [
          const Text('🎉 Events', style: PSText.screenTitle),
          const SizedBox(height: 6),
          const Text('Meetups and tournaments happening nearby', style: PSText.bodyDim),
          const SizedBox(height: 20),
          for (final e in demoEvents) _eventTile(e),
        ],
      ),
    );
  }

  Widget _eventTile(PSEvent e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PSColors.surface2,
        borderRadius: BorderRadius.circular(PSRadius.lg),
        border: Border.all(color: PSColors.border),
      ),
      child: Row(
        children: [
          Text(e.emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.title, style: const TextStyle(fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w700, fontSize: 15, color: PSColors.ink)),
                const SizedBox(height: 4),
                Text('${e.dateLabel} · ${e.attendeeCount} going', style: const TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 12, color: PSColors.inkDim)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
