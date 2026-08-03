import 'package:flutter/material.dart';
import '../theme/playspot_theme.dart';
import '../utils/sport_icons.dart';
import '../controllers/host_event_flow_controller.dart';
import 'location_picker_screen.dart';
import 'host_form_screen.dart';

class HostCategory {
  final String id;
  final String name;
  final String icon;
  final String description;
  final Color color;
  final String? imagePath;

  const HostCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.color,
    this.imagePath,
  });
}

class MainCategory {
  final String id;
  final String name;
  final String icon;
  final String description;
  final Color color;
  final String? imagePath;
  final List<HostCategory> subCategories;

  const MainCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.color,
    this.imagePath,
    required this.subCategories,
  });
}

class HostCategoryScreen extends StatefulWidget {
  final Function(String categoryId) onCategorySelect;
  final VoidCallback? onBack;

  const HostCategoryScreen({
    super.key,
    required this.onCategorySelect,
    this.onBack,
  });

  @override
  State<HostCategoryScreen> createState() => _HostCategoryScreenState();
}

class _HostCategoryScreenState extends State<HostCategoryScreen> {
  MainCategory? selectedMainCategory;
  String searchQuery = '';
  final HostEventFlowController _controller = HostEventFlowController();

  static const List<MainCategory> mainCategories = [
    MainCategory(
      id: 'sports',
      name: 'Sports',
      icon: '⚽',
      description: 'Team sports and athletics',
      color: Color(0xFFF5A623),
      imagePath: 'assets/Activity icon/sports.png',
      subCategories: [
        HostCategory(
          id: 'football',
          name: 'Football',
          icon: '⚽',
          description: 'Join or host football games',
          color: Color(0xFFF5A623),
          imagePath: 'assets/square_blurbg/football.jpg',
        ),
        HostCategory(
          id: 'soccer',
          name: 'Soccer',
          icon: '⚽',
          description: 'Soccer matches and pickup games',
          color: Color(0xFFF5A623),
          imagePath: 'assets/square_blurbg/soccer.jpg',
        ),
        HostCategory(
          id: 'pickleball',
          name: 'Pickleball',
          icon: '🏓',
          description: 'Fast-paced paddle sport games',
          color: Color(0xFFFF9800),
          imagePath: 'assets/square_blurbg/pickleball.jpg',
        ),
        HostCategory(
          id: 'tennis',
          name: 'Tennis',
          icon: '🎾',
          description: 'Singles and doubles matches',
          color: Color(0xFF4CAF50),
          imagePath: 'assets/square_blurbg/tennis.jpg',
        ),
        HostCategory(
          id: 'cricket',
          name: 'Cricket',
          icon: '🏏',
          description: 'Cricket matches and practice',
          color: Color(0xFF2196F3),
          imagePath: 'assets/square_blurbg/cricket.jpg',
        ),
        HostCategory(
          id: 'badminton',
          name: 'Badminton',
          icon: '🏸',
          description: 'Badminton games and tournaments',
          color: Color(0xFF00BCD4),
          imagePath: 'assets/square_blurbg/badminton.jpg',
        ),
        HostCategory(
          id: 'volleyball',
          name: 'Volleyball',
          icon: '🏐',
          description: 'Beach and indoor volleyball',
          color: Color(0xFFFFEB3B),
          imagePath: 'assets/square_blurbg/beach_volleyball.jpg',
        ),
        HostCategory(
          id: 'table_tennis',
          name: 'Table Tennis',
          icon: '🏓',
          description: 'Ping pong matches and games',
          color: Color(0xFF00BCD4),
          imagePath: 'assets/square_blurbg/table_tennis.jpg',
        ),
        HostCategory(
          id: 'squash',
          name: 'Squash',
          icon: '🎾',
          description: 'Squash court games',
          color: Color(0xFF4CAF50),
          imagePath: 'assets/square_blurbg/squash.jpg',
        ),
        HostCategory(
          id: 'golf',
          name: 'Golf',
          icon: '⛳',
          description: 'Golf rounds and driving range',
          color: Color(0xFF8BC34A),
          imagePath: 'assets/square_blurbg/golf_day.jpg',
        ),
        HostCategory(
          id: 'paintball',
          name: 'Paintball',
          icon: '🎨',
          description: 'Paintball games and battles',
          color: Color(0xFFFF5722),
          imagePath: 'assets/square_blurbg/paintball.jpg',
        ),
        HostCategory(
          id: 'dodgeball',
          name: 'Dodgeball',
          icon: '🏐',
          description: 'Dodgeball games and tournaments',
          color: Color(0xFFF44336),
          imagePath: 'assets/square_blurbg/dodgeball.jpg',
        ),
        HostCategory(
          id: 'ultimate_frisbee',
          name: 'Ultimate Frisbee',
          icon: '🥏',
          description: 'Frisbee games and leagues',
          color: Color(0xFF4CAF50),
          imagePath: 'assets/square_blurbg/ultimate_frisbee.jpg',
        ),
        HostCategory(
          id: 'korfball',
          name: 'Korfball',
          icon: '🏐',
          description: 'Korfball matches and games',
          color: Color(0xFFFF9800),
          imagePath: 'assets/square_blurbg/korfball.jpg',
        ),
        HostCategory(
          id: 'padel',
          name: 'Padel',
          icon: '🎾',
          description: 'Padel tennis games',
          color: Color(0xFF00BCD4),
          imagePath: 'assets/square_blurbg/padel.jpg',
        ),
      ],
    ),
    MainCategory(
      id: 'nightlife',
      name: 'Nightlife',
      icon: '🎉',
      description: 'Evening entertainment and social',
      color: Color(0xFF9C27B0),
      imagePath: 'assets/Activity icon/party.png',
      subCategories: [
        HostCategory(
          id: 'karaoke',
          name: 'Karaoke',
          icon: '🎤',
          description: 'Karaoke nights and singing',
          color: Color(0xFF9C27B0),
          imagePath: 'assets/square_blurbg/karaoke_night.jpg',
        ),
        HostCategory(
          id: 'comedy',
          name: 'Comedy',
          icon: '😂',
          description: 'Comedy nights and standup',
          color: Color(0xFFFF9800),
          imagePath: 'assets/square_blurbg/comedy_night.jpg',
        ),
        HostCategory(
          id: 'bowling',
          name: 'Bowling',
          icon: '🎳',
          description: 'Bowling nights and leagues',
          color: Color(0xFF795548),
          imagePath: 'assets/square_blurbg/bowling_night.jpg',
        ),
        HostCategory(
          id: 'darts',
          name: 'Darts',
          icon: '🎯',
          description: 'Darts nights and tournaments',
          color: Color(0xFF607D8B),
          imagePath: 'assets/square_blurbg/darts_night.jpg',
        ),
        HostCategory(
          id: 'chess',
          name: 'Chess',
          icon: '♟️',
          description: 'Chess nights and games',
          color: Color(0xFF5D4037),
          imagePath: 'assets/square_blurbg/chess_night.jpg',
        ),
        HostCategory(
          id: 'trivia',
          name: 'Trivia',
          icon: '❓',
          description: 'Trivia nights and quiz games',
          color: Color(0xFF3F51B5),
          imagePath: 'assets/square_blurbg/trivia_night.jpg',
        ),
        HostCategory(
          id: 'salsa',
          name: 'Salsa',
          icon: '💃',
          description: 'Salsa dancing and lessons',
          color: Color(0xFFE91E63),
          imagePath: 'assets/square_blurbg/salsa_night.jpg',
        ),
      ],
    ),
    MainCategory(
      id: 'fitness',
      name: 'Fitness',
      icon: '💪',
      description: 'Health and wellness activities',
      color: Color(0xFF4CAF50),
      imagePath: 'assets/Activity icon/yoga.png',
      subCategories: [
        HostCategory(
          id: 'fitness',
          name: 'Fitness',
          icon: '💪',
          description: 'Yoga, HIIT, Gym workouts',
          color: Color(0xFF4CAF50),
          imagePath: 'assets/square_blurbg/yoga_flow.jpg',
        ),
        HostCategory(
          id: 'zumba',
          name: 'Zumba',
          icon: '💃',
          description: 'Dance fitness classes',
          color: Color(0xFFE91E63),
          imagePath: 'assets/square_blurbg/zumba.jpg',
        ),
        HostCategory(
          id: 'hiit',
          name: 'HIIT',
          icon: '🔥',
          description: 'High intensity bootcamp',
          color: Color(0xFFFF5722),
          imagePath: 'assets/square_blurbg/hiit_bootcamp.jpg',
        ),
        HostCategory(
          id: 'running',
          name: 'Running',
          icon: '🏃',
          description: 'Run clubs and jogging groups',
          color: Color(0xFFFF5722),
          imagePath: 'assets/square_blurbg/run_club.jpg',
        ),
        HostCategory(
          id: 'cycling',
          name: 'Cycling',
          icon: '🚴',
          description: 'Bike rides and cycling groups',
          color: Color(0xFF607D8B),
          imagePath: 'assets/square_blurbg/bike_ride.jpg',
        ),
        HostCategory(
          id: 'swimming',
          name: 'Swimming',
          icon: '🏊',
          description: 'Pool sessions and open water',
          color: Color(0xFF03A9F4),
          imagePath: 'assets/square_blurbg/swimming.jpg',
        ),
        HostCategory(
          id: 'virtual_run',
          name: 'Virtual Run',
          icon: '🏃',
          description: 'Virtual running challenges',
          color: Color(0xFF2196F3),
          imagePath: 'assets/square_blurbg/virtual_run_club.jpg',
        ),
      ],
    ),
    MainCategory(
      id: 'cultural',
      name: 'Cultural',
      icon: '🎭',
      description: 'Art, music, and cultural events',
      color: Color(0xFFE91E63),
      imagePath: 'assets/Activity icon/art_music.png',
      subCategories: [
        HostCategory(
          id: 'cultural',
          name: 'Cultural',
          icon: '🎭',
          description: 'Art, Music, Food, Events',
          color: Color(0xFFE91E63),
          imagePath: 'assets/square_blurbg/book_club_meetup.jpg',
        ),
        HostCategory(
          id: 'surfing',
          name: 'Surfing',
          icon: '🏄',
          description: 'Surf sessions and beach days',
          color: Color(0xFF00BCD4),
          imagePath: 'assets/square_blurbg/surfing.jpg',
        ),
        HostCategory(
          id: 'skating',
          name: 'Skating',
          icon: '⛸️',
          description: 'Ice skating and roller skating',
          color: Color(0xFF9C27B0),
          imagePath: 'assets/square_blurbg/skating_night.jpg',
        ),
        HostCategory(
          id: 'skateboarding',
          name: 'Skateboarding',
          icon: '🛹',
          description: 'Skate sessions and parks',
          color: Color(0xFFFF5722),
          imagePath: 'assets/square_blurbg/skate_session.jpg',
        ),
        HostCategory(
          id: 'beach_camping',
          name: 'Beach Camping',
          icon: '⛺',
          description: 'Beach camping and outdoor events',
          color: Color(0xFF8BC34A),
          imagePath: 'assets/square_blurbg/beach_camping.jpg',
        ),
        HostCategory(
          id: 'photo_walk',
          name: 'Photo Walk',
          icon: '📸',
          description: 'Photography walks and tours',
          color: Color(0xFF9C27B0),
          imagePath: 'assets/square_blurbg/photo_walk.jpg',
        ),
        HostCategory(
          id: 'community_matchday',
          name: 'Community Matchday',
          icon: '🏆',
          description: 'Community sports events',
          color: Color(0xFFF5A623),
          imagePath: 'assets/square_blurbg/community_matchday.jpg',
        ),
      ],
    ),
    MainCategory(
      id: 'find_players',
      name: 'Find Players',
      icon: '👥',
      description: 'Connect with players nearby',
      color: Color(0xFF2196F3),
      imagePath: 'assets/Activity icon/find people.png',
      subCategories: [],
    ),
    MainCategory(
      id: 'custom',
      name: 'Custom',
      icon: '➕',
      description: 'Create your own sport or event',
      color: Color(0xFFFFD700),
      imagePath: 'assets/Activity icon/coustoms.png',
      subCategories: [],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0700),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0700),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            selectedMainCategory == null ? Icons.arrow_back : Icons.arrow_back,
            color: const Color(0xFFFFF8F0),
          ),
          onPressed: () {
            if (selectedMainCategory != null) {
              setState(() {
                selectedMainCategory = null;
                searchQuery = '';
              });
            } else if (widget.onBack != null) {
              widget.onBack!();
            } else if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          selectedMainCategory == null ? 'What do you want to host?' : selectedMainCategory!.name,
          style: const TextStyle(
            color: Color(0xFFFFF8F0),
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: -0.5,
          ),
          overflow: TextOverflow.visible,
        ),
      ),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0E0700), Color(0xFF0A0500)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: selectedMainCategory == null
                ? _buildMainCategories()
                : _buildSubCategories(),
          ),
        ),
      ),
    );
  }

  Widget _buildMainCategories() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
        childAspectRatio: 1.2,
      ),
      itemCount: mainCategories.length,
      itemBuilder: (context, index) {
        final category = mainCategories[index];
        return _buildMainCategoryCard(category, context);
      },
    );
  }

  Widget _buildSubCategories() {
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A0E00),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFF5A623).withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Color(0xFFF5A623), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  style: const TextStyle(color: Color(0xFFFFF8F0)),
                  decoration: InputDecoration(
                    hintText: 'Search activities...',
                    hintStyle: TextStyle(
                      color: const Color(0xFFFFF8F0).withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Sub-categories grid (square shape like main categories)
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.0,
            ),
            itemCount: _getFilteredSubCategories().length,
            itemBuilder: (context, index) {
              final category = _getFilteredSubCategories()[index];
              return _buildSubCategoryCard(category, context);
            },
          ),
        ),
        // Custom option at bottom
        const SizedBox(height: 10),
        _buildCustomOption(context),
      ],
    );
  }

  List<HostCategory> _getFilteredSubCategories() {
    if (selectedMainCategory == null) return [];
    if (searchQuery.isEmpty) {
      return selectedMainCategory!.subCategories;
    }
    return selectedMainCategory!.subCategories
        .where((cat) =>
            cat.name.toLowerCase().contains(searchQuery) ||
            cat.description.toLowerCase().contains(searchQuery))
        .toList();
  }

  Widget _buildMainCategoryCard(MainCategory category, BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMainCategory = category;
          _controller.setMainCategory(category.id);
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFF5A623),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF5A623).withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (category.imagePath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFF5A623),
                        width: 1.5,
                      ),
                    ),
                    child: Image.asset(
                      category.imagePath!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              // Dark gradient overlay for text readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        color: Color(0xFFFFF8F0),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        shadows: [Shadow(color: Colors.black87, blurRadius: 6)],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category.description,
                      style: TextStyle(
                        color: const Color(0xFFFFF8F0).withOpacity(0.7),
                        fontSize: 12,
                        height: 1.3,
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

  String _getCategoryTitle(String categoryId) {
    switch (categoryId) {
      case 'sports':
        return 'FOOTBALL';
      case 'nightlife':
        return 'KARAOKE NIGHT';
      case 'fitness':
        return 'YOGA FLOW';
      case 'cultural':
        return 'BOOK CLUB MEETUP';
      default:
        return 'ACTIVITY';
    }
  }

  Widget _buildOutlinedCard(MainCategory category, BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (category.id == 'custom') {
          _showCustomCategoryDialog(context);
        } else if (category.id == 'find_players') {
          widget.onCategorySelect('find_players');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A0E00),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: category.id == 'find_players' 
                ? const Color(0xFF2196F3)
                : const Color(0xFF607D8B),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                category.id == 'find_players' ? Icons.people : Icons.add,
                size: 48,
                color: category.id == 'find_players' 
                    ? const Color(0xFF2196F3)
                    : const Color(0xFF607D8B),
              ),
              const SizedBox(height: 12),
              Text(
                category.name,
                style: const TextStyle(
                  color: Color(0xFFFFF8F0),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                category.description,
                style: TextStyle(
                  color: const Color(0xFFFFF8F0).withOpacity(0.7),
                  fontSize: 12,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubCategoryCard(HostCategory category, BuildContext context) {
    return GestureDetector(
      onTap: () {
        _controller.setSubCategory(category.id);
        // Navigate directly to HostFormScreen like custom activities
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HostFormScreen(
              selectedActivity: {
                'id': category.id,
                'name': category.name,
                'icon': category.icon,
                'categoryId': selectedMainCategory!.id,
              },
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFF5A623),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF5A623).withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (category.imagePath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFF5A623),
                        width: 1.5,
                      ),
                    ),
                    child: Image.asset(
                      category.imagePath!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              // Dark gradient overlay for text readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        color: Color(0xFFFFF8F0),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        shadows: [Shadow(color: Colors.black87, blurRadius: 6)],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      category.description,
                      style: TextStyle(
                        color: const Color(0xFFFFF8F0).withOpacity(0.7),
                        fontSize: 10,
                        height: 1.3,
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

  Widget _buildCustomOption(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showCustomCategoryDialog(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A0E00),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFF5A623),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add,
              size: 24,
              color: Color(0xFFF5A623),
            ),
            const SizedBox(width: 12),
            const Text(
              'Create Custom Activity',
              style: TextStyle(
                color: Color(0xFFFFF8F0),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomCategoryDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A0E00),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: const Color(0xFFF5A623).withOpacity(0.3)),
        ),
        title: const Text(
          'Create Custom Activity',
          style: TextStyle(
            color: Color(0xFFFFF8F0),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Color(0xFFFFF8F0)),
              decoration: InputDecoration(
                labelText: 'Activity Name',
                labelStyle: TextStyle(color: const Color(0xFFF5A623).withOpacity(0.7)),
                filled: true,
                fillColor: const Color(0xFF0E0700),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: const Color(0xFFF5A623).withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: const Color(0xFFF5A623).withOpacity(0.3)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: const Color(0xFFF5A623).withOpacity(0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Navigator.pop(context);
                _controller.setCustomActivity(nameController.text, '🏆');
                _controller.setMainCategory('custom');
                _controller.setSubCategory('custom');
                
                // Navigate to LocationPickerScreen and handle result
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LocationPickerScreen(),
                  ),
                ).then((result) {
                  if (result != null && result['location'] != null) {
                    // Location selected, navigate to HostFormScreen with pre-filled data
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HostFormScreen(
                          selectedActivity: {
                            'id': 'custom',
                            'name': nameController.text,
                            'icon': '🏆',
                            'categoryId': 'custom',
                          },
                          preFilledLocation: result['address'], // Use address string, not LatLng object
                          preFilledLat: result['location']?.latitude,
                          preFilledLng: result['location']?.longitude,
                        ),
                      ),
                    );
                  }
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF5A623),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Create',
              style: TextStyle(color: Color(0xFF140A00)),
            ),
          ),
        ],
      ),
    );
  }
}
