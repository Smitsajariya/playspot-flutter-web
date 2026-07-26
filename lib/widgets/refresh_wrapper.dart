import 'package:flutter/material.dart';

class RefreshWrapper extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const RefreshWrapper({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFFF5A623),
      backgroundColor: const Color(0xFF0E0700),
      child: child,
    );
  }
}
