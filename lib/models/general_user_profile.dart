// model objects used by the general user profile screen.

/// describes the social relation between the local user and the viewed user.
enum GeneralUserRelation { notFollowing, following, followsMe, friends }

/// stores the profile data needed to render another user's profile.
class GeneralUserProfile {
  const GeneralUserProfile({
    required this.userId,
    required this.profilePhoto,
    required this.username,
    required this.city,
    required this.cityAkaName,
    required this.bio,
    required this.showBadge,
    required this.categoryBadgeIconPath,
    required this.followersCount,
    required this.participatedEventsCount,
    required this.eventLikesReceivedCount,
    required this.relation,
    required this.pastEvents,
  });

  final String userId;
  final String profilePhoto;
  final String username;
  final String city;
  final String cityAkaName;
  final String bio;
  final bool showBadge;
  final String categoryBadgeIconPath;
  final int followersCount;
  final int participatedEventsCount;
  final int eventLikesReceivedCount;
  final GeneralUserRelation relation;
  final List<Map<String, dynamic>> pastEvents;

  /// returns a copy with updated social relation and follower count.
  GeneralUserProfile copyWith({
    int? followersCount,
    GeneralUserRelation? relation,
  }) {
    return GeneralUserProfile(
      userId: userId,
      profilePhoto: profilePhoto,
      username: username,
      city: city,
      cityAkaName: cityAkaName,
      bio: bio,
      showBadge: showBadge,
      categoryBadgeIconPath: categoryBadgeIconPath,
      followersCount: followersCount ?? this.followersCount,
      participatedEventsCount: participatedEventsCount,
      eventLikesReceivedCount: eventLikesReceivedCount,
      relation: relation ?? this.relation,
      pastEvents: pastEvents,
    );
  }
}
