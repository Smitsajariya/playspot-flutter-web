import 'package:flutter/material.dart';
import '../theme/playspot_theme.dart';
import '../utils/sport_icons.dart';

/// One tile in the sport-picker grid. Mirrors `.sport-card` / `.sport-card.selected`.
class PSSportCard extends StatelessWidget {
  final String emoji;
  final String name;
  final int? activeCount; // shows "3 playing now" style count if > 0
  final bool selected;
  final VoidCallback onTap;

  const PSSportCard({
    super.key,
    required this.emoji,
    required this.name,
    required this.selected,
    required this.onTap,
    this.activeCount,
  });

  @override
  Widget build(BuildContext context) {
    final hasActivity = (activeCount ?? 0) > 0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: PSCurves.spring,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: PSSpace.s4),
        decoration: BoxDecoration(
          gradient: selected ? PSGradients.sportCardSelected : PSGradients.sportCard,
          borderRadius: BorderRadius.circular(PSRadius.lg),
          border: Border.all(
            color: selected
                ? PSColors.goldBright
                : (hasActivity ? const Color(0x59FFB93C) : const Color(0x2EFFB93C)),
            width: 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(color: PSColors.gold.withOpacity(0.25), blurRadius: 36),
                ]
              : PSShadows.sm,
        ),
        child: Column(
          children: [
            SportIcons.getSportImage(name, size: 48),
            const SizedBox(height: 10),
            Text(
              name.toUpperCase(),
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.84,
                color: selected ? PSColors.goldBright : PSColors.ink.withOpacity(0.65),
              ),
            ),
            if (activeCount != null) ...[
              const SizedBox(height: 5),
              Text(
                hasActivity ? '$activeCount playing now' : '—',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: hasActivity ? PSColors.goldBright : PSColors.ink.withOpacity(0.3),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
