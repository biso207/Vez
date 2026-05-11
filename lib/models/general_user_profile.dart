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
    required this.followersCount,
    required this.followingCount,
    required this.participatedEventsCount,
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
  final int followersCount;
  final int followingCount;
  final int participatedEventsCount;
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
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount,
      participatedEventsCount: participatedEventsCount,
      relation: relation ?? this.relation,
      pastEvents: pastEvents,
    );
  }
}
