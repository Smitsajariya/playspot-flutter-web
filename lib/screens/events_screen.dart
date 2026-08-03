import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../socket_service.dart';
import 'event_form_screen.dart';
import '../widgets/refresh_wrapper.dart';
import '../widgets/skeleton_loaders.dart';
import '../utils/share_utils.dart';
import '../utils/sport_icons.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final SocketService _socketService = SocketService();
  List<dynamic> _events = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _socketService.connect();
    _socketService.onEventsUpdate((events) {
      if (mounted) {
        setState(() => _events = events);
      }
    });

    _socketService.onEventCancelled((data) {
      print('[EVENTS SCREEN] Received event:cancelled: $data');
      if (mounted) {
        final cancelledEventId = data['eventId'];
        print('[EVENTS SCREEN] Removing event with ID: $cancelledEventId');
        print('[EVENTS SCREEN] Current events before removal: ${_events.map((e) => e['id']).toList()}');
        setState(() {
          _events.removeWhere((event) => event['id'] == cancelledEventId);
        });
        print('[EVENTS SCREEN] Current events after removal: ${_events.map((e) => e['id']).toList()}');
      }
    });
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    _socketService.getEvents((events) {
      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
      }
    });

    // Timeout after 5 seconds - just stop loading, show empty state
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    });
  }

  String _getCategoryEmoji(String category) {
    final emojis = {
      'music': '🎵',
      'art': '🎨',
      'food': '🍔',
      'sports': '⚽',
      'tech': '💻',
      'social': '🎉',
      'culture': '🏛️',
      'fitness': '🏋️',
    };
    return emojis[category] ?? '📅';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0700),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0700),
        elevation: 0,
        title: const Text(
          'Events',
          style: TextStyle(
            color: Color(0xFFFFF8F0),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFFF5A623)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EventFormScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshWrapper(
        onRefresh: _loadEvents,
        child: _isLoading
            ? const EventCardSkeleton()
            : _events.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event,
                          size: 64,
                          color: const Color(0x47FFF8F0),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No events yet',
                          style: TextStyle(
                            color: Color(0x47FFF8F0),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create one to get started!',
                          style: TextStyle(
                            color: Color(0x47FFF8F0),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const EventFormScreen()),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Create Event'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF5A623),
                            foregroundColor: const Color(0xFF140A00),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                    final event = _events[index];
                    final category = event['category'] ?? 'culture';
                    final categoryEmoji = _getCategoryEmoji(category);
                    final title = event['title'] ?? 'Event';
                    final location = event['location'] ?? 'Location';
                    final date = event['date'] ?? '';
                    final photoUrl = event['photoUrl'];
                    final attendees = event['attendees'] as List<dynamic>? ?? [];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A0C00),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0x1AFFB93C)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Photo header
                            SizedBox(
                              height: 148,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (photoUrl != null && photoUrl.isNotEmpty)
                                    CachedNetworkImage(
                                      imageUrl: photoUrl,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, error, stackTrace) =>
                                          _buildGradientBackground(categoryEmoji, category),
                                    )
                                  else
                                    _buildGradientBackground(categoryEmoji, category),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.7),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 12,
                                    left: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5A623).withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '$categoryEmoji ${category.toUpperCase()}',
                                        style: const TextStyle(
                                          color: Color(0xFF140A00),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1A0C00),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${attendees.length} attending',
                                        style: const TextStyle(
                                          color: Color(0xFFF5A623),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Event details
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: Color(0xFFFFF8F0),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '📅 $date',
                                    style: const TextStyle(
                                      color: Color(0x8CFFF8F0),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '📍 $location',
                                    style: const TextStyle(
                                      color: Color(0x8CFFF8F0),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Share button
                                  GestureDetector(
                                    onTap: () {
                                      ShareUtils.shareEventOnWhatsApp(
                                        eventTitle: title,
                                        category: category,
                                        location: location,
                                        date: date,
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        const Text('📲', style: TextStyle(fontSize: 16)),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'Share',
                                          style: TextStyle(
                                            color: Color(0xFFF5A623),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                ),
    );
  }

  Widget _buildGradientBackground(String emoji, [String? category]) {
    final assetPath = category != null ? SportIcons.getAssetPath(category) : null;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E1800), Color(0xFF221000)],
        ),
      ),
      child: assetPath != null
          ? Image.asset(
              assetPath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Text(emoji, style: const TextStyle(fontSize: 48)),
              ),
            )
          : Center(
              child: Text(emoji, style: const TextStyle(fontSize: 48)),
            ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
