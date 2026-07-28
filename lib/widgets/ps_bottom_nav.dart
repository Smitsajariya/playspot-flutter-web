import 'package:flutter/material.dart';
import '../theme/playspot_theme.dart';

enum PSNavTab { home, map, host, events, ranks, chats, social }

/// Floating bottom nav pill — mirrors `#bottom-nav > .nav-pill`.
/// The HOST button is visually distinct (gold "+" badge), matching the original.
class PSBottomNav extends StatelessWidget {
  final PSNavTab current;
  final ValueChanged<PSNavTab> onSelect;
  final VoidCallback onHostTap;

  const PSBottomNav({
    super.key,
    required this.current,
    required this.onSelect,
    required this.onHostTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0E0700),
            borderRadius: BorderRadius.circular(PSRadius.full),
            border: Border.all(
              color: PSColors.gold.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: PSColors.gold.withOpacity(0.15),
                blurRadius: 28,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navBtn(Icons.home, 'HOME', PSNavTab.home),
              _navBtn(Icons.map, 'MAP', PSNavTab.map),
              _hostBtn(),
              _navBtn(Icons.photo_library, 'SOCIAL', PSNavTab.social),
              _navBtn(Icons.chat, 'CHATS', PSNavTab.chats),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navBtn(IconData icon, String label, PSNavTab tab) {
    final active = current == tab;
    return InkWell(
      onTap: () => onSelect(tab),
      borderRadius: BorderRadius.circular(PSRadius.full),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(PSRadius.full),
          gradient: active
              ? PSGradients.goldAccent
              : null,
          boxShadow: active
              ? [
                  BoxShadow(
                    color: PSColors.gold.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: active ? 1.0 : 0.5,
              child: Icon(
                icon,
                size: 22,
                color: active ? const Color(0xFF140A00) : PSColors.inkMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: PSText.navLabel.copyWith(
                color: active ? const Color(0xFF140A00) : PSColors.inkMuted,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hostBtn() {
    return InkWell(
      onTap: onHostTap,
      borderRadius: BorderRadius.circular(PSRadius.full),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: PSGradients.primaryButton,
                boxShadow: [
                  BoxShadow(
                    color: PSColors.gold.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: PSColors.gold.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                '+',
                style: TextStyle(
                  color: Color(0xFF140A00),
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'HOST',
              style: PSText.navLabel.copyWith(
                color: PSColors.goldBright,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
