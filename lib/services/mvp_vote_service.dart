import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Post-game MVP vote + rating, scoped to a single group chat. Stored
/// locally (SharedPreferences) since there's no `game:end` / `vote:cast`
/// backend event yet — each device tallies its own votes and posts a
/// system message summarizing them to the group so everyone sees the
/// prompt, but a true shared tally needs a backend vote-aggregation
/// endpoint. Flag it if you want `game:end` + `vote:cast` wired
/// server-side; this service's method signatures would stay the same.
class MvpVoteService {
  static String _endedKey(String groupId) => 'ps_mvp_ended_$groupId';
  static String _votedKey(String groupId) => 'ps_mvp_voted_$groupId';
  static String _tallyKey(String groupId) => 'ps_mvp_tally_$groupId';
  static String _ratingSumKey(String groupId) => 'ps_mvp_rating_sum_$groupId';
  static String _ratingCountKey(String groupId) => 'ps_mvp_rating_count_$groupId';

  static Future<bool> isEnded(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_endedKey(groupId)) ?? false;
  }

  static Future<void> markEnded(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_endedKey(groupId), true);
  }

  static Future<bool> hasVoted(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_votedKey(groupId)) ?? false;
  }

  static Future<void> castVote({
    required String groupId,
    required String mvpCandidateId,
    required int starRating, // 1-5, rating of the overall game
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_tallyKey(groupId));
    final tally = raw != null
        ? Map<String, dynamic>.from(jsonDecode(raw) as Map).map((k, v) => MapEntry(k, v as int))
        : <String, int>{};
    tally[mvpCandidateId] = (tally[mvpCandidateId] ?? 0) + 1;
    await prefs.setString(_tallyKey(groupId), jsonEncode(tally));

    final sum = (prefs.getInt(_ratingSumKey(groupId)) ?? 0) + starRating;
    final count = (prefs.getInt(_ratingCountKey(groupId)) ?? 0) + 1;
    await prefs.setInt(_ratingSumKey(groupId), sum);
    await prefs.setInt(_ratingCountKey(groupId), count);

    await prefs.setBool(_votedKey(groupId), true);
  }

  static Future<Map<String, int>> tally(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_tallyKey(groupId));
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map).map((k, v) => MapEntry(k, v as int));
  }

  static Future<double?> averageRating(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_ratingCountKey(groupId)) ?? 0;
    if (count == 0) return null;
    final sum = prefs.getInt(_ratingSumKey(groupId)) ?? 0;
    return sum / count;
  }

  /// Candidate with the most votes so far, or null if no votes yet.
  static Future<String?> leader(String groupId) async {
    final t = await tally(groupId);
    if (t.isEmpty) return null;
    final entries = t.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }
}
