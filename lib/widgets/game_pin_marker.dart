import 'package:flutter/material.dart';
import '../theme/playspot_theme.dart';

class GamePinMarker extends StatelessWidget {
  final String? photoUrl;
  final String sportEmoji;
  final bool isMine;
  final bool isEvent;
  final double size;

  const GamePinMarker({
    super.key,
    this.photoUrl,
    required this.sportEmoji,
    this.isMine = false,
    this.isEvent = false,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size + 12, // Extra height for tail
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Pin body (photo container)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isMine
                      ? const Color(0xFFFF4D1C)
                      : isEvent
                          ? const Color(0xFF9B8FFF)
                          : PSColors.gold,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isMine
                        ? const Color(0xFFFF4D1C).withOpacity(0.5)
                        : isEvent
                            ? const Color(0xFF9B8FFF).withOpacity(0.45)
                            : PSColors.gold.withOpacity(0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: photoUrl != null
                    ? Image.network(
                        photoUrl!,
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: size,
                            height: size,
                            color: const Color(0xFF2E1800),
                            child: Center(
                              child: Text(
                                sportEmoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        width: size,
                        height: size,
                        color: const Color(0xFF2E1800),
                        child: Center(
                          child: Text(
                            sportEmoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          // Pin badge (sport emoji)
          Positioned(
            bottom: -3,
            right: -3,
            child: Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A0C00),
                border: Border.all(
                  color: PSColors.goldBright,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  sportEmoji,
                  style: const TextStyle(fontSize: 9),
                ),
              ),
            ),
          ),
          // Pin tail
          Positioned(
            bottom: -12,
            left: (size / 2) - 6,
            child: CustomPaint(
              size: const Size(12, 12),
              painter: PinTailPainter(
                color: isMine
                    ? const Color(0xFFFF4D1C)
                    : isEvent
                        ? const Color(0xFF9B8FFF)
                        : PSColors.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PinTailPainter extends CustomPainter {
  final Color color;

  PinTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
