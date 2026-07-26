import 'package:flutter/material.dart';

class GameCardSkeleton extends StatelessWidget {
  const GameCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0C00),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1AFFB93C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Photo skeleton
          Container(
            height: 148,
            decoration: BoxDecoration(
              color: const Color(0xFF2E1800),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          // Content skeleton
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSkeleton(height: 16, width: 120),
                const SizedBox(height: 8),
                _buildSkeleton(height: 12, width: 80),
                const SizedBox(height: 8),
                _buildSkeleton(height: 12, width: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton({required double height, required double width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: const Color(0x1AFFB93C),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class EventCardSkeleton extends StatelessWidget {
  const EventCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0C00),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1AFFB93C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 148,
            decoration: BoxDecoration(
              color: const Color(0xFF2E1800),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSkeleton(height: 16, width: 140),
                const SizedBox(height: 8),
                _buildSkeleton(height: 12, width: 90),
                const SizedBox(height: 8),
                _buildSkeleton(height: 12, width: 110),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton({required double height, required double width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: const Color(0x1AFFB93C),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
