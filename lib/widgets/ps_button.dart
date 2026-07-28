import 'package:flutter/material.dart';
import '../theme/playspot_theme.dart';

/// Mirrors `.btn`, `.btn-volt`, `.btn-ghost`, `.btn-full` from the CSS.
enum PSButtonStyle { volt, ghost, ghostDanger }

class PSButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final PSButtonStyle style;
  final bool fullWidth;
  final bool disabled;

  const PSButton({
    super.key,
    required this.label,
    this.onTap,
    this.style = PSButtonStyle.volt,
    this.fullWidth = true,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isVolt = style == PSButtonStyle.volt;
    final isDanger = style == PSButtonStyle.ghostDanger;

    final Color bg = isVolt ? PSColors.gold : Colors.transparent;
    final Color fg = isVolt
        ? const Color(0xFF140A00)
        : (isDanger ? PSColors.fire : PSColors.ink);
    final Color borderColor = isVolt
        ? Colors.transparent
        : (isDanger ? PSColors.fire : PSColors.border);

    final button = AnimatedOpacity(
      opacity: disabled ? 0.45 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(PSRadius.full),
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(PSRadius.full),
          splashColor: isVolt ? Colors.black12 : PSColors.gold.withOpacity(0.12),
          child: Container(
            height: 52,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: PSSpace.s6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(PSRadius.full),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: isVolt ? PSShadows.glowGoldSm : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
