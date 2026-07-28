import 'package:latlong2/latlong.dart';

class PresenceEstimate {
  final int playerCount;
  final int gameCount;
  const PresenceEstimate({required this.playerCount, required this.gameCount});
}

/// Estimates "players near me" from the games list the screen already has
/// loaded, instead of a true backend presence/heartbeat signal (PlaySpot's
/// socket server doesn't emit one yet). Counts distinct players across
/// games within [radiusKm] of [origin].
///
/// If you want a real live-presence pill later, this is the seam: add a
/// `user:heartbeat` emit + `presence:nearby` listener server-side, and
/// swap the body of `estimate()` for that — callers only touch
/// [PresenceEstimate], so the UI doesn't change.
class PresenceService {
  static const _distance = Distance();

  static PresenceEstimate estimate({
    required List<dynamic> games,
    required LatLng? origin,
    double radiusKm = 3,
  }) {
    if (origin == null || games.isEmpty) {
      return const PresenceEstimate(playerCount: 0, gameCount: 0);
    }

    int gameCount = 0;
    final players = <String>{};

    for (final g in games) {
      final lat = g['lat'] as double?;
      final lng = g['lng'] as double?;
      if (lat == null || lng == null) continue;

      final d = _distance.as(LengthUnit.Kilometer, origin, LatLng(lat, lng));
      if (d > radiusKm) continue;

      gameCount++;
      final host = (g['hostName'] ?? g['name'])?.toString();
      if (host != null && host.isNotEmpty) players.add('host:$host');

      final rosterLen = (g['players'] as List?)?.length;
      final playerCount = rosterLen ?? (g['playerCount'] as int?) ?? (host != null ? 1 : 0);
      // We don't have individual player identities from the games payload,
      // only a roster size — so count each seat as a distinct nearby
      // person using a per-game synthetic key.
      for (var i = 0; i < playerCount; i++) {
        players.add('${g['id']}_seat_$i');
      }
    }

    return PresenceEstimate(playerCount: players.length, gameCount: gameCount);
  }
}
