import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/sport_icons.dart';

class StoriesRow extends StatelessWidget {
  final List<Map<String, dynamic>> stories;
  final Function(String userId) onStoryTap;

  const StoriesRow({
    super.key,
    required this.stories,
    required this.onStoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stories.length,
        itemBuilder: (context, index) {
          final story = stories[index];
          final userId = story['userId'] ?? '';
          final photoUrl = story['photoUrl'];
          final name = story['name'] ?? 'User';
          final hasUnseen = story['hasUnseen'] ?? true;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => onStoryTap(userId),
              child: Column(
                children: [
                  // Story circle
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: hasUnseen
                          ? const LinearGradient(
                              colors: [Color(0xFFF5A623), Color(0xFFFFB93C)],
                            )
                          : null,
                      border: hasUnseen
                          ? Border.all(color: const Color(0xFFF5A623), width: 2)
                          : Border.all(color: const Color(0x1AFFB93C), width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1A0C00),
                        ),
                        child: ClipOval(
                          child: photoUrl != null && photoUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: photoUrl,
                                  fit: BoxFit.cover,
                                  width: 56,
                                  height: 56,
                                  errorWidget: (context, error, stackTrace) =>
                                      userId == 'host'
                                          ? const Icon(
                                              Icons.person,
                                              size: 28,
                                              color: Color(0xFFF5A623),
                                            )
                                          : SportIcons.getSportImage(name, size: 28),
                                )
                              : userId == 'host'
                                  ? const Icon(
                                      Icons.person,
                                      size: 28,
                                      color: Color(0xFFF5A623),
                                    )
                                  : SportIcons.getSportImage(name, size: 28),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Name
                  SizedBox(
                    width: 64,
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: Color(0x8CFFF8F0),
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
