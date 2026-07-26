/// Placeholder models — no backend wiring yet.
/// These shapes mirror what the Socket.io backend sends (`game:update`, `events:update`),
/// so swapping in real data later should be mostly drop-in.

class PSGame {
  final String id;
  final String sportEmoji;
  final String sportName;
  final String title;
  final String hostName;
  final int playerCount;
  final int maxPlayers;
  final String skillLevel;
  final bool isLive;
  final String timeLabel; // e.g. "Today, 6:00 PM"
  final String distanceLabel; // e.g. "1.2 km away"
  final bool isMyGame; // Whether this game was created by the current user

  const PSGame({
    required this.id,
    required this.sportEmoji,
    required this.sportName,
    required this.title,
    required this.hostName,
    required this.playerCount,
    required this.maxPlayers,
    required this.skillLevel,
    required this.isLive,
    required this.timeLabel,
    required this.distanceLabel,
    this.isMyGame = false,
  });
}

class PSEvent {
  final String id;
  final String title;
  final String emoji;
  final String dateLabel;
  final int attendeeCount;

  const PSEvent({
    required this.id,
    required this.title,
    required this.emoji,
    required this.dateLabel,
    required this.attendeeCount,
  });
}

class PSSport {
  final String id;
  final String emoji;
  final String name;
  final int activeCount;

  const PSSport({
    required this.id,
    required this.emoji,
    required this.name,
    this.activeCount = 0,
  });
}

/// Sample/demo data so screens render meaningfully before backend wiring.
const demoSports = <PSSport>[
  PSSport(id: 'football', emoji: '⚽', name: 'Football', activeCount: 3),
  PSSport(id: 'basketball', emoji: '🏀', name: 'Basketball', activeCount: 1),
  PSSport(id: 'tennis', emoji: '🎾', name: 'Tennis'),
  PSSport(id: 'badminton', emoji: '🏸', name: 'Badminton', activeCount: 2),
  PSSport(id: 'volleyball', emoji: '🏐', name: 'Volleyball'),
  PSSport(id: 'cricket', emoji: '🏏', name: 'Cricket'),
  PSSport(id: 'running', emoji: '🏃', name: 'Running', activeCount: 1),
  PSSport(id: 'cycling', emoji: '🚴', name: 'Cycling'),
];

const demoGames = <PSGame>[
  PSGame(
    id: 'g1',
    sportEmoji: '⚽',
    sportName: 'Football',
    title: '5-a-side at Tempelhofer Feld',
    hostName: 'Lukas',
    playerCount: 7,
    maxPlayers: 10,
    skillLevel: 'Intermediate',
    isLive: true,
    timeLabel: 'Live now',
    distanceLabel: '0.8 km away',
  ),
  PSGame(
    id: 'g2',
    sportEmoji: '🏀',
    sportName: 'Basketball',
    title: 'Pickup 3v3',
    hostName: 'Maya',
    playerCount: 4,
    maxPlayers: 6,
    skillLevel: 'Beginner',
    isLive: false,
    timeLabel: 'Today, 6:00 PM',
    distanceLabel: '1.4 km away',
  ),
  PSGame(
    id: 'g3',
    sportEmoji: '🏸',
    sportName: 'Badminton',
    title: 'Evening doubles',
    hostName: 'Jonas',
    playerCount: 2,
    maxPlayers: 4,
    skillLevel: 'Advanced',
    isLive: false,
    timeLabel: 'Tomorrow, 7:30 PM',
    distanceLabel: '2.1 km away',
  ),
];

const demoEvents = <PSEvent>[
  PSEvent(id: 'e1', title: 'Sunday League Kickoff', emoji: '🎉', dateLabel: 'Sun, 29 Jun', attendeeCount: 18),
  PSEvent(id: 'e2', title: 'Beach Volleyball Meetup', emoji: '🏖️', dateLabel: 'Sat, 5 Jul', attendeeCount: 12),
];
