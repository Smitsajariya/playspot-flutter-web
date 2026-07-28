import 'package:flutter/material.dart';
import '../theme/playspot_theme.dart';

/// One circle in the horizontal "stories" row. Mirrors `.story-item` / `.story-ring`.
class PSStoryItem extends StatelessWidget {
  final Widget avatarChild; // emoji Text, network image, or "+" for host
  final String label;
  final bool seen; // dims the gradient ring once viewed
  final Color labelColor;
  final VoidCallback onTap;

  const PSStoryItem({
    super.key,
    required this.avatarChild,
    required this.label,
    required this.onTap,
    this.seen = false,
    this.labelColor = PSColors.inkDim,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62,
            height: 62,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: seen
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [PSColors.gold.withOpacity(0.25), PSColors.gold.withOpacity(0.1)],
                    )
                  : PSGradients.storyRing,
              boxShadow: seen ? null : [BoxShadow(color: PSColors.gold.withOpacity(0.4), blurRadius: 18)],
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [PSColors.surface3, PSColors.surface],
                ),
              ),
              child: Center(child: avatarChild),
            ),
          ),
          const SizedBox(height: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 64),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
