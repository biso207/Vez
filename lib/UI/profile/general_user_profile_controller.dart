// controller for loading and mutating another user's public profile data.

import 'package:flutter/foundation.dart';

import '../../models/general_user_profile.dart';
import '../../services/getters_service.dart';
import '../../services/setters_service.dart';
import '../../services/translation_service.dart';

/// manages profile data and follow actions for a viewed user.
class GeneralUserProfileController extends ChangeNotifier {
  GeneralUserProfileController({
    required this.localUserId,
    required this.viewedUserId,
  }) : _localGet = GetDBService(userID: localUserId),
       _localSet = SetDBService(userID: localUserId),
       _viewedGet = GetDBService(userID: viewedUserId);

  final String localUserId;
  final String viewedUserId;
  final GetDBService _localGet;
  final SetDBService _localSet;
  final GetDBService _viewedGet;

  bool isLoading = true;
  bool isFollowing = false;
  String errorMessage = '';
  GeneralUserProfile? profile;

  /// loads the viewed user's profile, counters, relation, and past events.
  Future<void> loadProfile() async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    final results = await Future.wait([
      _viewedGet.getFullUserData(),
      _viewedGet.getFollowersCount(),
      _viewedGet.getFollowing(),
      _viewedGet.getExpiredCreatedEvents(),
      _viewedGet.getExpiredParticipatedEvents(),
      _localGet.getFollowing(),
      _localGet.getFollowers(),
    ]);

    final userData = results[0] as Map<String, dynamic>?;
    if (userData == null) {
      errorMessage = StringRes.at('user_not_found');
      isLoading = false;
      notifyListeners();
      return;
    }

    final followersCount = results[1] as int;
    final followingRows = results[2] as List<Map<String, dynamic>>;
    final createdEvents = results[3] as List<Map<String, dynamic>>;
    final participatedEvents = results[4] as List<Map<String, dynamic>>;
    final localFollowing = results[5] as List<Map<String, dynamic>>;
    final localFollowers = results[6] as List<Map<String, dynamic>>;

    final followingIds = localFollowing
        .map((row) => (row['following_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();
    final followerIds = localFollowers
        .map((row) => (row['follower_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();

    final bool localFollowsViewed = followingIds.contains(viewedUserId);
    final bool viewedFollowsLocal = followerIds.contains(viewedUserId);
    final GeneralUserRelation relation =
        localFollowsViewed && viewedFollowsLocal
        ? GeneralUserRelation.friends
        : localFollowsViewed
        ? GeneralUserRelation.following
        : viewedFollowsLocal
        ? GeneralUserRelation.followsMe
        : GeneralUserRelation.notFollowing;

    final String akaName = (userData['city_aka_name'] ?? '').toString().trim();
    profile = GeneralUserProfile(
      userId: viewedUserId,
      profilePhoto: (userData['profile_photo'] ?? '').toString().trim(),
      username: (userData['username'] ?? 'Username').toString(),
      city: (userData['city'] ?? StringRes.at('city')).toString(),
      cityAkaName: akaName.isNotEmpty ? '$akaName • ' : '',
      bio: (userData['bio'] ?? StringRes.at('bio')).toString(),
      showBadge: userData['category_badge'] as bool? ?? true,
      followersCount: followersCount,
      followingCount: followingRows.length,
      participatedEventsCount: participatedEvents.length,
      relation: relation,
      pastEvents: [...createdEvents, ...participatedEvents],
    );

    isLoading = false;
    notifyListeners();
  }

  /// follows the viewed user and refreshes the relation state locally.
  Future<int> followViewedUser() async {
    if (isFollowing || viewedUserId == localUserId) return 400;

    isFollowing = true;
    notifyListeners();

    final int result = await _localSet.followUser(viewedUserId);
    if (result == 200 || result == 201 || result == 204) {
      final current = profile;
      if (current != null) {
        final GeneralUserRelation nextRelation =
            current.relation == GeneralUserRelation.followsMe
            ? GeneralUserRelation.friends
            : GeneralUserRelation.following;
        profile = current.copyWith(
          followersCount: current.followersCount + 1,
          relation: nextRelation,
        );
      }
    }

    isFollowing = false;
    notifyListeners();
    return result;
  }

  /// unfollows the viewed user and refreshes the relation state locally.
  Future<int> unfollowViewedUser() async {
    if (isFollowing || viewedUserId == localUserId) return 400;

    isFollowing = true;
    notifyListeners();

    final int result = await _localSet.unfollowUser(viewedUserId);
    if (result == 200 || result == 204) {
      final current = profile;
      if (current != null) {
        profile = current.copyWith(
          followersCount: current.followersCount > 0
              ? current.followersCount - 1
              : 0,
          relation: current.relation == GeneralUserRelation.friends
              ? GeneralUserRelation.followsMe
              : GeneralUserRelation.notFollowing,
        );
      }
    }

    isFollowing = false;
    notifyListeners();
    return result;
  }
}
