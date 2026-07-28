import 'package:flutter/material.dart';
import '../theme/playspot_theme.dart';
import '../utils/sport_icons.dart';

class HostActivity {
  final String id;
  final String name;
  final String icon;
  final String description;
  final String categoryId;
  final String? imagePath;

  const HostActivity({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.categoryId,
    this.imagePath,
  });
}

class HostActivityScreen extends StatelessWidget {
  final String categoryId;
  final Function(Map<String, dynamic> activity) onActivitySelect;

  const HostActivityScreen({
    super.key,
    required this.categoryId,
    required this.onActivitySelect,
  });

  static const Map<String, List<HostActivity>> activitiesByCategory = {
    'sports': [
      HostActivity(
        id: 'football',
        name: 'Football',
        icon: '⚽',
        description: '5-a-side, 7-a-side, 11-a-side',
        categoryId: 'sports',
        imagePath: 'assets/football.png',
      ),
      HostActivity(
        id: 'basketball',
        name: 'Basketball',
        icon: '🏀',
        description: 'Pickup games, tournaments',
        categoryId: 'sports',
        imagePath: 'assets/community_matchday.png',
      ),
      HostActivity(
        id: 'tennis',
        name: 'Tennis',
        icon: '🎾',
        description: 'Singles, doubles matches',
        categoryId: 'sports',
        imagePath: 'assets/tennis.png',
      ),
      HostActivity(
        id: 'badminton',
        name: 'Badminton',
        icon: '🏸',
        description: 'Singles, doubles games',
        categoryId: 'sports',
        imagePath: 'assets/badminton.png',
      ),
      HostActivity(
        id: 'volleyball',
        name: 'Volleyball',
        icon: '🏐',
        description: 'Beach, indoor volleyball',
        categoryId: 'sports',
        imagePath: 'assets/beach_volleyball.png',
      ),
      HostActivity(
        id: 'cricket',
        name: 'Cricket',
        icon: '🏏',
        description: 'Tape ball, hard ball matches',
        categoryId: 'sports',
        imagePath: 'assets/cricket.png',
      ),
      HostActivity(
        id: 'running',
        name: 'Running Club',
        icon: '🏃',
        description: '5K, 10K, marathon training',
        categoryId: 'sports',
        imagePath: 'assets/run_club.png',
      ),
      HostActivity(
        id: 'cycling',
        name: 'Cycling',
        icon: '🚴',
        description: 'Road rides, mountain biking',
        categoryId: 'sports',
        imagePath: 'assets/bike_ride.png',
      ),
      HostActivity(
        id: 'swimming',
        name: 'Swimming',
        icon: '🏊',
        description: 'Lap swimming, water polo',
        categoryId: 'sports',
        imagePath: 'assets/swimming.png',
      ),
      HostActivity(
        id: 'golf',
        name: 'Golf',
        icon: '⛳',
        description: '9-hole, 18-hole rounds',
        categoryId: 'sports',
        imagePath: 'assets/golf_day.png',
      ),
    ],
    'nightlife': [
      HostActivity(
        id: 'karaoke',
        name: 'Karaoke Night',
        icon: '🎤',
        description: 'Sing your favorite songs',
        categoryId: 'nightlife',
        imagePath: 'assets/karaoke_night.png',
      ),
      HostActivity(
        id: 'comedy',
        name: 'Comedy Night',
        icon: '😂',
        description: 'Stand-up comedy shows',
        categoryId: 'nightlife',
        imagePath: 'assets/comedy_night.png',
      ),
      HostActivity(
        id: 'trivia',
        name: 'Trivia Night',
        icon: '🧠',
        description: 'Quiz competitions',
        categoryId: 'nightlife',
        imagePath: 'assets/trivia_night.png',
      ),
      HostActivity(
        id: 'bowling',
        name: 'Bowling Night',
        icon: '🎳',
        description: 'Bowling games and tournaments',
        categoryId: 'nightlife',
        imagePath: 'assets/bowling_night.png',
      ),
      HostActivity(
        id: 'darts',
        name: 'Darts Night',
        icon: '🎯',
        description: 'Darts competitions',
        categoryId: 'nightlife',
        imagePath: 'assets/darts_night.png',
      ),
      HostActivity(
        id: 'salsa',
        name: 'Salsa Night',
        icon: '💃',
        description: 'Salsa dancing events',
        categoryId: 'nightlife',
        imagePath: 'assets/salsa_night.png',
      ),
    ],
    'fitness': [
      HostActivity(
        id: 'yoga',
        name: 'Yoga',
        icon: '🧘',
        description: 'Vinyasa, hatha, power yoga',
        categoryId: 'fitness',
        imagePath: 'assets/yoga_flow.png',
      ),
      HostActivity(
        id: 'hiit',
        name: 'HIIT Bootcamp',
        icon: '🔥',
        description: 'High intensity interval training',
        categoryId: 'fitness',
        imagePath: 'assets/hiit_bootcamp.png',
      ),
      HostActivity(
        id: 'zumba',
        name: 'Zumba',
        icon: '💃',
        description: 'Dance fitness classes',
        categoryId: 'fitness',
        imagePath: 'assets/zumba.png',
      ),
      HostActivity(
        id: 'running',
        name: 'Running',
        icon: '🏃',
        description: 'Solo and group runs',
        categoryId: 'fitness',
        imagePath: 'assets/run_club.png',
      ),
      HostActivity(
        id: 'cycling',
        name: 'Cycling',
        icon: '🚴',
        description: 'Road and mountain biking',
        categoryId: 'fitness',
        imagePath: 'assets/bike_ride.png',
      ),
      HostActivity(
        id: 'swimming',
        name: 'Swimming',
        icon: '🏊',
        description: 'Pool and open water swimming',
        categoryId: 'fitness',
        imagePath: 'assets/swimming.png',
      ),
    ],
    'cultural': [
      HostActivity(
        id: 'book_club',
        name: 'Book Club',
        icon: '📚',
        description: 'Reading groups, discussions',
        categoryId: 'cultural',
        imagePath: 'assets/book_club_meetup.png',
      ),
      HostActivity(
        id: 'photo_walk',
        name: 'Photo Walk',
        icon: '📸',
        description: 'Photography tours',
        categoryId: 'cultural',
        imagePath: 'assets/photo_walk.png',
      ),
      HostActivity(
        id: 'chess',
        name: 'Chess Night',
        icon: '♟️',
        description: 'Chess tournaments and games',
        categoryId: 'cultural',
        imagePath: 'assets/chess_night.png',
      ),
      HostActivity(
        id: 'hiking',
        name: 'Hiking & Camping',
        icon: '🏕️',
        description: 'Outdoor adventures',
        categoryId: 'cultural',
        imagePath: 'assets/beach_camping.png',
      ),
    ],
    'find_players': [
      HostActivity(
        id: 'football_players',
        name: 'Football Players',
        icon: '⚽',
        description: 'Find teammates for your team',
        categoryId: 'find_players',
        imagePath: 'assets/football.png',
      ),
      HostActivity(
        id: 'basketball_players',
        name: 'Basketball Players',
        icon: '🏀',
        description: 'Find pickup game players',
        categoryId: 'find_players',
        imagePath: 'assets/community_matchday.png',
      ),
      HostActivity(
        id: 'tennis_partners',
        name: 'Tennis Partners',
        icon: '🎾',
        description: 'Find singles/doubles partners',
        categoryId: 'find_players',
        imagePath: 'assets/tennis.png',
      ),
      HostActivity(
        id: 'running_group',
        name: 'Running Group',
        icon: '🏃',
        description: 'Join running communities',
        categoryId: 'find_players',
        imagePath: 'assets/run_club.png',
      ),
      HostActivity(
        id: 'cycling_group',
        name: 'Cycling Group',
        icon: '🚴',
        description: 'Find riding partners',
        categoryId: 'find_players',
        imagePath: 'assets/bike_ride.png',
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final activities = activitiesByCategory[categoryId] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0E0700),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0700),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFFF8F0)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _getCategoryName(categoryId),
          style: const TextStyle(
            color: Color(0xFFFFF8F0),
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0E0700), Color(0xFF0A0500)],
          ),
        ),
        child: activities.isEmpty
            ? Center(
                child: Text(
                  'No activities available',
                  style: TextStyle(
                    color: const Color(0xFFFFF8F0).withOpacity(0.5),
                    fontSize: 16,
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(20),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return _buildActivityCard(activity);
                  },
                ),
              ),
      ),
    );
  }

  String _getCategoryName(String categoryId) {
    final names = {
      'sports': 'Sports Activities',
      'nightlife': 'Nightlife Events',
      'fitness': 'Fitness Activities',
      'cultural': 'Cultural Events',
      'find_players': 'Find Players',
    };
    return names[categoryId] ?? 'Activities';
  }

  Widget _buildActivityCard(HostActivity activity) {
    return GestureDetector(
      onTap: () => onActivitySelect({
        'id': activity.id,
        'name': activity.name,
        'icon': activity.icon,
        'categoryId': activity.categoryId,
      }),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: PSGradients.sportCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: PSColors.gold.withOpacity(0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: PSColors.gold.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo background, if we have one for this activity yet.
              // Falls back to nothing (transparent) so the existing gold
              // gradient card still shows if the image is missing.
              if (activity.imagePath != null)
                Image.asset(
                  activity.imagePath!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              // Dark scrim so text stays readable over a photo
              if (activity.imagePath != null)
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.05),
                        Colors.black.withOpacity(0.75),
                      ],
                    ),
                  ),
                ),
              // Foreground content
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Small icon badge stays as a familiar accent even
                    // once a photo background is present.
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: PSColors.gold.withOpacity(0.4),
                        ),
                      ),
                      child: Text(
                        activity.icon,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      activity.name,
                      style: const TextStyle(
                        color: Color(0xFFFFF8F0),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        shadows: [Shadow(color: Colors.black87, blurRadius: 6)],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      activity.description,
                      style: TextStyle(
                        color: const Color(0xFFFFF8F0).withOpacity(0.85),
                        fontSize: 11,
                        height: 1.4,
                        shadows: const [Shadow(color: Colors.black87, blurRadius: 6)],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
