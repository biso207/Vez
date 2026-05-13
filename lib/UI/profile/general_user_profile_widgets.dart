// reusable widgets for the general user profile screen.

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../models/general_user_profile.dart';
import '../../services/translation_service.dart';

const double kBlurValue = 5.0;

/// renders the viewed user's identity card.
class GeneralUserInfoCard extends StatelessWidget {
  const GeneralUserInfoCard({
    super.key,
    required this.scale,
    required this.profilePhoto,
    required this.username,
    required this.cityAkaName,
    required this.city,
    required this.bio,
    required this.showBadge,
    required this.showFriendBadge,
  });

  final double scale;
  final String profilePhoto;
  final String username;
  final String cityAkaName;
  final String city;
  final String bio;
  final bool showBadge;
  final bool showFriendBadge;

  /// builds the card body with avatar, texts, and relation badge.
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color.fromARGB(50, 0, 0, 0),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: const Color.fromARGB(128, 255, 255, 255),
              width: 2 * scale,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GeneralProfileAvatar(
                photo: profilePhoto,
                size: 75 * scale,
                showBadge: showBadge,
              ),
              SizedBox(width: 16 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'InstagramSans',
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 255, 255, 255),
                        height: 1.0,
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: TextStyle(
                          fontFamily: 'InstagramSans',
                          color: const Color.fromARGB(255, 255, 255, 255),
                          fontSize: 14 * scale,
                        ),
                        children: [
                          TextSpan(
                            text: cityAkaName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: city,
                            style: const TextStyle(fontWeight: FontWeight.w300),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      bio,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'InstagramSans',
                        fontSize: 14 * scale,
                        color: const Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showFriendBadge)
          Positioned(
            top: -10 * scale,
            right: 0,
            child: GeneralFriendBadge(scale: scale),
          ),
      ],
    );
  }
}

/// renders a circular avatar with a category badge overlay.
class GeneralProfileAvatar extends StatelessWidget {
  const GeneralProfileAvatar({
    super.key,
    required this.photo,
    required this.size,
    this.showBadge = false,
  });

  final String photo;
  final double size;
  final bool showBadge;

  /// builds the avatar and optional category badge.
  @override
  Widget build(BuildContext context) {
    final bool isNetwork = photo.startsWith('http');
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color.fromARGB(255, 255, 255, 255),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: photo.isEmpty
                ? Image.asset(
                    'assets/icons/home_page/profile_photo.png', // TODO: modify the path here
                    fit: BoxFit.cover,
                  )
                : Image(
                    image: isNetwork
                        ? NetworkImage(photo)
                        : AssetImage(photo) as ImageProvider,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        if (showBadge)
          Positioned(
            top: -4,
            right: -4,
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: kBlurValue,
                  sigmaY: kBlurValue,
                ),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(51, 0, 10, 218),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color.fromARGB(128, 0, 10, 218),
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(5),
                  child: Image.asset(
                    'assets/icons/categories/pub.png',
                    color: Colors.white,
                    height: 22,
                    width: 22,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// renders the mutual-friend badge from the mockup.
class GeneralFriendBadge extends StatelessWidget {
  const GeneralFriendBadge({super.key, required this.scale});

  final double scale;

  /// builds the yellow friendship indicator.
  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: kBlurValue, sigmaY: kBlurValue),
        child: Container(
          width: 44 * scale,
          height: 44 * scale,
          padding: EdgeInsets.all(5 * scale),
          decoration: BoxDecoration(
            color: const Color.fromARGB(153, 90, 76, 0),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color.fromARGB(255, 255, 195, 0),
              width: 2,
            ),
          ),
          child: Image.asset(
            'assets/icons/event/friends.png',
            color: const Color.fromARGB(255, 255, 255, 255),
            height: 30,
            width: 30,
          ),
        ),
      ),
    );
  }
}

/// renders the profile statistics pill.
class GeneralStatsPill extends StatelessWidget {
  const GeneralStatsPill({
    super.key,
    required this.scale,
    required this.followers,
    required this.events,
    required this.following,
  });

  final double scale;
  final int followers;
  final int events;
  final int following;

  /// builds the three statistic columns.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(50, 0, 0, 0),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: const Color.fromARGB(128, 255, 255, 255),
          width: 2 * scale,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GeneralStatItem(
            iconPath: 'assets/icons/profile_page/followers.png',
            value: followers.toString(),
          ),
          GeneralStatItem(
            iconPath: 'assets/icons/profile_page/participated_events.png',
            value: events.toString(),
          ),
          GeneralStatItem(
            iconPath: 'assets/icons/profile_page/following_requests.png',
            value: following.toString(),
          ),
        ],
      ),
    );
  }
}

/// renders one icon and number inside the stats pill.
class GeneralStatItem extends StatelessWidget {
  const GeneralStatItem({
    super.key,
    required this.iconPath,
    required this.value,
  });

  final String iconPath;
  final String value;

  /// builds the icon and numeric value.
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          iconPath, // TODO: modify the path here
          width: 30,
          height: 30,
          color: const Color.fromARGB(255, 255, 255, 255),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'InstagramSans',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Color.fromARGB(255, 255, 255, 255),
            height: 1,
          ),
        ),
      ],
    );
  }
}

/// renders the follow or follow-back action.
class GeneralFollowButton extends StatelessWidget {
  const GeneralFollowButton({
    super.key,
    required this.relation,
    required this.isBusy,
    required this.onTap,
  });

  final GeneralUserRelation relation;
  final bool isBusy;
  final VoidCallback onTap;

  /// builds the relation-aware action button.
  @override
  Widget build(BuildContext context) {
    final bool isUnfollow =
        relation == GeneralUserRelation.friends ||
        relation == GeneralUserRelation.following;
    final String label = switch (relation) {
      GeneralUserRelation.followsMe => StringRes.at('follow_back'),
      GeneralUserRelation.friends ||
      GeneralUserRelation.following => StringRes.at('unfollow'),
      GeneralUserRelation.notFollowing => StringRes.at('follow'),
    };
    final Color backgroundColor = isUnfollow
        ? const Color.fromARGB(102, 255, 49, 49)
        : const Color.fromARGB(102, 255, 217, 0);
    final Color borderColor = isUnfollow
        ? const Color.fromARGB(179, 255, 49, 49)
        : const Color.fromARGB(179, 255, 217, 0);

    return GestureDetector(
      onTap: isBusy ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Text(
          isBusy ? '...' : label,
          style: const TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontSize: 21,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// renders a compact grid of past event tiles.
class GeneralPastEventsGrid extends StatelessWidget {
  const GeneralPastEventsGrid({
    super.key,
    required this.events,
    required this.scale,
  });

  final List<Map<String, dynamic>> events;
  final double scale;

  /// builds the responsive three-column grid.
  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> displayEvents = events.isEmpty
        ? const []
        : events.take(12).toList();

    if (displayEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayEvents.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10 * scale,
        mainAxisSpacing: 6 * scale,
        childAspectRatio: 0.66,
      ),
      itemBuilder: (context, index) {
        return GeneralPastEventTile(event: displayEvents[index], scale: scale);
      },
    );
  }
}

/// renders one profile event tile.
class GeneralPastEventTile extends StatelessWidget {
  const GeneralPastEventTile({
    super.key,
    required this.event,
    required this.scale,
  });

  final Map<String, dynamic> event;
  final double scale;

  /// builds a blurred event thumbnail with title and overlay icons.
  @override
  Widget build(BuildContext context) {
    final String title = (event['title'] ?? '').toString().trim();
    final String photo = (event['bg_photo'] ?? '').toString().trim();
    final bool isNetwork = photo.startsWith('http');

    // todo: get the category and type of the event
    // todo: change cat. icon color in blue and typology in white

    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: Stack(
        fit: StackFit.expand,
        children: [
          photo.isEmpty
              ? Image.asset(
                  'assets/images/bg/default_create_event_bg.jpg',
                  fit: BoxFit.cover,
                )
              : Image(
                  image: isNetwork
                      ? NetworkImage(photo)
                      : AssetImage(photo) as ImageProvider,
                  fit: BoxFit.cover,
                ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(26, 0, 0, 0),
                  Color.fromARGB(140, 0, 0, 0),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8 * scale,
            left: 6 * scale,
            child: Row(
              children: [
                GeneralTileIcon(
                  iconPath: 'assets/icons/event/guests.png',
                  scale: scale,
                ),
                SizedBox(width: 5 * scale),
                GeneralTileIcon(
                  iconPath: 'assets/icons/event/friends.png',
                  scale: scale,
                ),
              ],
            ),
          ),
          Positioned(
            left: 8 * scale,
            right: 8 * scale,
            bottom: 22 * scale,
            child: Text(
              title.isEmpty ? 'Event' : title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color.fromARGB(255, 255, 255, 255),
                fontSize: 14 * scale,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// renders a small circular icon overlay for event tiles.
class GeneralTileIcon extends StatelessWidget {
  const GeneralTileIcon({
    super.key,
    required this.iconPath,
    required this.scale,
  });

  final String iconPath;
  final double scale;

  /// builds the tile icon circle.
  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: kBlurValue, sigmaY: kBlurValue),
        child: Container(
          width: 22 * scale,
          height: 22 * scale,
          padding: EdgeInsets.all(4 * scale),
          decoration: BoxDecoration(
            color: const Color.fromARGB(128, 0, 10, 218),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color.fromARGB(128, 255, 255, 255),
              width: 1,
            ),
          ),
          child: Image.asset(
            iconPath, // TODO: modify the path here
            color: const Color.fromARGB(255, 255, 255, 255),
          ),
        ),
      ),
    );
  }
}
