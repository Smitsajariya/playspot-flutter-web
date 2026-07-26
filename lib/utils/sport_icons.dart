import 'package:flutter/material.dart';

class SportIcons {
  static const Map<String, IconData> _sportIconMap = {
    'football': Icons.sports_soccer,
    'soccer': Icons.sports_soccer,
    'basketball': Icons.sports_basketball,
    'tennis': Icons.sports_tennis,
    'volleyball': Icons.sports_volleyball,
    'cricket': Icons.sports_cricket,
    'baseball': Icons.sports_baseball,
    'golf': Icons.sports_golf,
    'hockey': Icons.sports_hockey,
    'rugby': Icons.sports_rugby,
    'badminton': Icons.sports,
    'swimming': Icons.pool,
    'running': Icons.directions_run,
    'cycling': Icons.directions_bike,
    'gym': Icons.fitness_center,
    'yoga': Icons.self_improvement,
    'hiking': Icons.terrain,
    'skiing': Icons.downhill_skiing,
    'snowboarding': Icons.snowboarding,
    'skating': Icons.skateboarding,
    'boxing': Icons.sports_mma,
    'mma': Icons.sports_mma,
    'gymnastics': Icons.accessibility_new,
    'athletics': Icons.directions_run,
    'table_tennis': Icons.sports_tennis,
    'ping_pong': Icons.sports_tennis,
    'darts': Icons.sports_esports,
    'bowling': Icons.sports,
    'fishing': Icons.phishing,
    'surfing': Icons.surfing,
    'kayaking': Icons.rowing,
    'rowing': Icons.rowing,
    'sailing': Icons.sailing,
    'climbing': Icons.terrain,
    'horse_riding': Icons.pets,
    'equestrian': Icons.pets,
    'archery': Icons.gps_fixed,
    'shooting': Icons.gps_fixed,
    'fencing': Icons.sports_martial_arts,
    'martial_arts': Icons.sports_martial_arts,
    'karate': Icons.sports_martial_arts,
    'judo': Icons.sports_martial_arts,
    'taekwondo': Icons.sports_martial_arts,
    'wrestling': Icons.sports_martial_arts,
  };

  static const Map<String, String> _assetMap = {
    // Sports
    'football': 'assets/football.png',
    'basketball': 'assets/community_matchday.png',
    'tennis': 'assets/tennis.png',
    'badminton': 'assets/badminton.png',
    'volleyball': 'assets/beach_volleyball.png',
    'cricket': 'assets/cricket.png',
    'running': 'assets/run_club.png',
    'cycling': 'assets/bike_ride.png',
    'swimming': 'assets/swimming.png',
    'golf': 'assets/golf_day.png',
    // Nightlife
    'karaoke': 'assets/karaoke_night.png',
    'comedy': 'assets/comedy_night.png',
    'trivia': 'assets/trivia_night.png',
    'bowling': 'assets/bowling_night.png',
    'darts': 'assets/darts_night.png',
    'salsa': 'assets/salsa_night.png',
    // Fitness
    'yoga': 'assets/yoga_flow.png',
    'hiit': 'assets/hiit_bootcamp.png',
    'zumba': 'assets/zumba.png',
    // Cultural
    'book_club': 'assets/book_club_meetup.png',
    'photo_walk': 'assets/photo_walk.png',
    'chess': 'assets/chess_night.png',
    'hiking': 'assets/beach_camping.png',
    // Categories
    'sports': 'assets/football.png',
    'nightlife': 'assets/karaoke_night.png',
    'fitness': 'assets/yoga_flow.png',
    'cultural': 'assets/book_club_meetup.png',
    'find_players': 'assets/run_club.png',
  };

  static IconData getIcon(String sportName) {
    final key = sportName.toLowerCase().trim();
    return _sportIconMap[key] ?? Icons.sports;
  }

  static String? getAssetPath(String sportName) {
    final key = sportName.toLowerCase().trim();
    return _assetMap[key];
  }

  static String getImageUrl(String sportName) {
    // Using placeholder sport images from a free CDN
    // You can replace these with your own hosted sport images
    final key = sportName.toLowerCase().replaceAll(' ', '_');
    final imageMap = {
      'football': 'https://cdn-icons-png.flaticon.com/512/925/925531.png',
      'soccer': 'https://cdn-icons-png.flaticon.com/512/925/925531.png',
      'basketball': 'https://cdn-icons-png.flaticon.com/512/925/925530.png',
      'tennis': 'https://cdn-icons-png.flaticon.com/512/925/925532.png',
      'volleyball': 'https://cdn-icons-png.flaticon.com/512/925/925533.png',
      'cricket': 'https://cdn-icons-png.flaticon.com/512/925/925534.png',
      'baseball': 'https://cdn-icons-png.flaticon.com/512/925/925535.png',
      'golf': 'https://cdn-icons-png.flaticon.com/512/925/925536.png',
      'hockey': 'https://cdn-icons-png.flaticon.com/512/925/925537.png',
      'rugby': 'https://cdn-icons-png.flaticon.com/512/925/925538.png',
      'badminton': 'https://cdn-icons-png.flaticon.com/512/925/925539.png',
      'swimming': 'https://cdn-icons-png.flaticon.com/512/925/925540.png',
      'running': 'https://cdn-icons-png.flaticon.com/512/925/925541.png',
      'cycling': 'https://cdn-icons-png.flaticon.com/512/925/925542.png',
      'gym': 'https://cdn-icons-png.flaticon.com/512/925/925543.png',
      'yoga': 'https://cdn-icons-png.flaticon.com/512/925/925544.png',
      'hiking': 'https://cdn-icons-png.flaticon.com/512/925/925545.png',
      'skiing': 'https://cdn-icons-png.flaticon.com/512/925/925546.png',
      'snowboarding': 'https://cdn-icons-png.flaticon.com/512/925/925547.png',
      'skating': 'https://cdn-icons-png.flaticon.com/512/925/925548.png',
      'boxing': 'https://cdn-icons-png.flaticon.com/512/925/925549.png',
      'mma': 'https://cdn-icons-png.flaticon.com/512/925/925550.png',
      'gymnastics': 'https://cdn-icons-png.flaticon.com/512/925/925551.png',
      'athletics': 'https://cdn-icons-png.flaticon.com/512/925/925552.png',
      'table_tennis': 'https://cdn-icons-png.flaticon.com/512/925/925553.png',
      'ping_pong': 'https://cdn-icons-png.flaticon.com/512/925/925553.png',
      'darts': 'https://cdn-icons-png.flaticon.com/512/925/925554.png',
      'bowling': 'https://cdn-icons-png.flaticon.com/512/925/925555.png',
      'fishing': 'https://cdn-icons-png.flaticon.com/512/925/925556.png',
      'surfing': 'https://cdn-icons-png.flaticon.com/512/925/925557.png',
      'kayaking': 'https://cdn-icons-png.flaticon.com/512/925/925558.png',
      'rowing': 'https://cdn-icons-png.flaticon.com/512/925/925559.png',
      'sailing': 'https://cdn-icons-png.flaticon.com/512/925/925560.png',
      'climbing': 'https://cdn-icons-png.flaticon.com/512/925/925561.png',
      'horse_riding': 'https://cdn-icons-png.flaticon.com/512/925/925562.png',
      'equestrian': 'https://cdn-icons-png.flaticon.com/512/925/925562.png',
      'archery': 'https://cdn-icons-png.flaticon.com/512/925/925563.png',
      'shooting': 'https://cdn-icons-png.flaticon.com/512/925/925564.png',
      'fencing': 'https://cdn-icons-png.flaticon.com/512/925/925565.png',
      'martial_arts': 'https://cdn-icons-png.flaticon.com/512/925/925566.png',
      'karate': 'https://cdn-icons-png.flaticon.com/512/925/925567.png',
      'judo': 'https://cdn-icons-png.flaticon.com/512/925/925568.png',
      'taekwondo': 'https://cdn-icons-png.flaticon.com/512/925/925569.png',
      'wrestling': 'https://cdn-icons-png.flaticon.com/512/925/925570.png',
    };
    
    return imageMap[key] ?? 'https://cdn-icons-png.flaticon.com/512/925/925571.png';
  }

  static Widget getSportIcon(String sportName, {double size = 24, Color? color}) {
    return Icon(
      getIcon(sportName),
      size: size,
      color: color,
    );
  }

  static Widget getSportImage(String sportName, {double size = 48}) {
    final assetPath = getAssetPath(sportName);
    if (assetPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.2),
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            getIcon(sportName),
            size: size,
            color: const Color(0xFFF5A623),
          ),
        ),
      );
    }
    return Icon(
      getIcon(sportName),
      size: size,
      color: const Color(0xFFF5A623),
    );
  }
}
