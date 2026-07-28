enum FollowStatus { none, requested, following }

class FollowService {
  static final Map<String, FollowStatus> followStatus = {};

  static void sendFollowRequest(String userId) {
    followStatus[userId] = FollowStatus.requested;
  }

  static void acceptFollowRequest(String userId) {
    followStatus[userId] = FollowStatus.following;
  }

  static void removeFollower(String userId) {
    followStatus[userId] = FollowStatus.none;
  }

  static FollowStatus getStatus(String userId) {
    return followStatus[userId] ?? FollowStatus.none;
  }

  static bool isFollowing(String userId) {
    return followStatus[userId] == FollowStatus.following;
  }

  static bool isRequested(String userId) {
    return followStatus[userId] == FollowStatus.requested;
  }
}
