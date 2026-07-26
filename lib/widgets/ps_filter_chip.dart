import 'package:flutter/material.dart';
import '../theme/playspot_theme.dart';

/// Mirrors `.filter-chip` / `.filter-chip.active` in the filter bar.
class PSFilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const PSFilterChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(PSRadius.full),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? PSColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(PSRadius.full),
          border: Border.all(color: active ? PSColors.gold : PSColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? const Color(0xFF140A00) : PSColors.inkDim,
          ),
        ),
      ),
    );
  }
}

/// Small grid/list view toggle pair — mirrors `.feed-view-toggle` / `.feed-view-btn`.
class PSViewToggle extends StatelessWidget {
  final bool isGrid;
  final ValueChanged<bool> onChanged;

  const PSViewToggle({super.key, required this.isGrid, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PSColors.surface2,
        borderRadius: BorderRadius.circular(PSRadius.md),
        border: Border.all(color: PSColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn('⊞', isGrid, () => onChanged(true)),
          _btn('☰', !isGrid, () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _btn(String icon, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? PSColors.gold.withOpacity(0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(PSRadius.md),
        ),
        child: Text(icon, style: TextStyle(fontSize: 16, color: active ? PSColors.goldBright : PSColors.inkMuted)),
      ),
    );
  }
}
