import 'package:flutter/material.dart';

class GameFilters extends StatefulWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const GameFilters({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  State<GameFilters> createState() => _GameFiltersState();
}

class _GameFiltersState extends State<GameFilters> {
  final List<String> _filters = ['All', 'Now', 'Today', 'Open', 'Nearby'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = widget.selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => widget.onFilterChanged(filter),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF5A623) : const Color(0xFF1A0C00),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFF5A623) : const Color(0x1AFFB93C),
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF140A00) : const Color(0xFFFFF8F0),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
