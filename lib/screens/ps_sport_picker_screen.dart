import 'package:flutter/material.dart';
import '../theme/playspot_theme.dart';
import '../models/ps_models.dart';
import '../widgets/ps_sport_card.dart';

class PSSportPickerScreen extends StatefulWidget {
  final VoidCallback onBack;
  final ValueChanged<PSSport> onSelect;

  const PSSportPickerScreen({super.key, required this.onBack, required this.onSelect});

  @override
  State<PSSportPickerScreen> createState() => _PSSportPickerScreenState();
}

class _PSSportPickerScreenState extends State<PSSportPickerScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: PSGradients.screenSport),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 32, 24, 16),
            child: Row(
              children: [
                IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back, color: PSColors.ink)),
                const SizedBox(width: 4),
                const Text('What are you playing?', style: PSText.screenTitle),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 160),
              itemCount: demoSports.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, i) {
                final sport = demoSports[i];
                return PSSportCard(
                  emoji: sport.emoji,
                  name: sport.name,
                  activeCount: sport.activeCount,
                  selected: _selectedId == sport.id,
                  onTap: () {
                    setState(() => _selectedId = sport.id);
                    widget.onSelect(sport);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
