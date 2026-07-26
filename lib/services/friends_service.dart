import 'dart:math';
import '../data/mock_data.dart';
import '../models/player_model.dart';
import 'follow_service.dart';

/// A friend paired with the sport/interest tags they share with the
/// current user, plus a deterministic "last seen near" pin used by the
/// Sports Map view.
class FriendEntry {
  final PlayerModel player;
  final List<String> mutualTags;

  const FriendEntry({required this.player, required this.mutualTags});
}

/// PlaySpot has `follow_service.dart` (follow/unfollow state) but no
/// dedicated Friends directory or backend endpoint yet. This service treats
/// "friends" as players the current user follows — seeded from
/// `mock_data.dart`'s `isFollowing` flags, then overridden live by whatever
/// the user actually does with `FollowService` in this session.
///
/// If/when a real `friends:list` (or similar) socket event exists, swap
/// `friends()` to read from that instead — the screen consuming this only
/// needs `FriendEntry` objects, so the UI won't need to change.
class FriendsService {
  static List<PlayerModel> get _all => mockPlayers;

  static List<PlayerModel> friends() {
    return _all.where((p) {
      final status = FollowService.getStatus(p.id);
      if (status == FollowStatus.following) return true;
      if (status == FollowStatus.none && p.isFollowing) return true;
      return false;
    }).toList();
  }

  /// Sport tags the friend has that also appear in the current user's own
  /// profile interests (ids like `football`, `tennis` — matched loosely
  /// against the friend's display-name tags like "Football").
  static List<String> mutualTags(PlayerModel friend, List<String> myInterestIds) {
    final mine = myInterestIds.map((e) => e.toLowerCase().replaceAll('_', ' ')).toSet();
    return friend.sportTags.where((t) => mine.contains(t.toLowerCase())).toList();
  }

  static List<FriendEntry> friendEntries(List<String> myInterestIds) {
    return friends()
        .map((p) => FriendEntry(player: p, mutualTags: mutualTags(p, myInterestIds)))
        .toList();
  }

  /// Deterministic pseudo-location for the "Sports Map" — offsets a friend
  /// a small, stable distance from [origin] based on their id, so the map
  /// doesn't reshuffle pins between opens. This is a placeholder: real
  /// "where my friends play" data needs venue check-ins wired server-side
  /// (flag it if you want `venue:checkin` added to the backend).
  static (double, double) pseudoLocation(double originLat, double originLng, String friendId) {
    final hash = friendId.codeUnits.fold<int>(0, (acc, c) => acc + c);
    final rand = Random(hash);
    final dLat = (rand.nextDouble() - 0.5) * 0.06; // ~± 3km
    final dLng = (rand.nextDouble() - 0.5) * 0.06;
    return (originLat + dLat, originLng + dLng);
  }
}
