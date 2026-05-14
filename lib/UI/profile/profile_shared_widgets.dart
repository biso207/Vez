import 'dart:ui';

import 'package:flutter/material.dart';

import '../../models/event_catalog.dart';
import 'profile_event_helpers.dart';

const double profileBlurValue = 5.0;

class ProfileInfoCard extends StatelessWidget {
  const ProfileInfoCard({
    super.key,
    required this.scale,
    required this.profilePhoto,
    required this.username,
    required this.cityAkaName,
    required this.city,
    required this.bio,
    required this.showBadge,
    required this.categoryBadgeIconPath,
    this.showFriendBadge = false,
  });

  final double scale;
  final String profilePhoto;
  final String username;
  final String cityAkaName;
  final String city;
  final String bio;
  final bool showBadge;
  final String categoryBadgeIconPath;
  final bool showFriendBadge;

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
              ProfileAvatarWithBadge(
                photo: profilePhoto,
                size: 75 * scale,
                showBadge: showBadge,
                categoryBadgeIconPath: categoryBadgeIconPath,
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
                        color: Colors.white,
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
                          color: Colors.white,
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
                        color: Colors.white,
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
            child: ProfileFriendBadge(scale: scale),
          ),
      ],
    );
  }
}

class ProfileAvatarWithBadge extends StatelessWidget {
  const ProfileAvatarWithBadge({
    super.key,
    required this.photo,
    required this.size,
    required this.categoryBadgeIconPath,
    this.showBadge = false,
  });

  final String photo;
  final double size;
  final String categoryBadgeIconPath;
  final bool showBadge;

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
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: ClipOval(
            child: photo.isEmpty
                ? Image.asset(
                    'assets/icons/home_page/profile_photo.png',
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
                  sigmaX: profileBlurValue,
                  sigmaY: profileBlurValue,
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
                    categoryBadgeIconPath,
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

class ProfileFriendBadge extends StatelessWidget {
  const ProfileFriendBadge({super.key, required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: profileBlurValue,
          sigmaY: profileBlurValue,
        ),
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
            color: Colors.white,
            height: 30,
            width: 30,
          ),
        ),
      ),
    );
  }
}

class ProfileStatsPill extends StatelessWidget {
  const ProfileStatsPill({
    super.key,
    required this.scale,
    required this.followers,
    required this.events,
    required this.likes,
  });

  final double scale;
  final int followers;
  final int events;
  final int likes;

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
          ProfileStatItem(
            assetIconPath: 'assets/icons/profile_page/followers.png',
            value: followers.toString(),
          ),
          ProfileStatItem(
            assetIconPath: 'assets/icons/profile_page/participated_events.png',
            value: events.toString(),
          ),
          ProfileStatItem(
            iconData: Icons.favorite_rounded,
            value: likes.toString(),
          ),
        ],
      ),
    );
  }
}

class ProfileStatItem extends StatelessWidget {
  const ProfileStatItem({
    super.key,
    required this.value,
    this.assetIconPath,
    this.iconData,
  }) : assert(assetIconPath != null || iconData != null);

  final String value;
  final String? assetIconPath;
  final IconData? iconData;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (assetIconPath != null)
          Image.asset(
            assetIconPath!,
            width: 30,
            height: 30,
            color: Colors.white,
          )
        else
          Icon(iconData, color: Colors.white, size: 30),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'InstagramSans',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class ProfilePastEventsGrid extends StatelessWidget {
  const ProfilePastEventsGrid({
    super.key,
    required this.events,
    required this.scale,
  });

  final List<Map<String, dynamic>> events;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> displayEvents = events.take(12).toList();

    if (displayEvents.isEmpty) return const SizedBox.shrink();

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
        return ProfilePastEventTile(event: displayEvents[index], scale: scale);
      },
    );
  }
}

class ProfilePastEventTile extends StatelessWidget {
  const ProfilePastEventTile({
    super.key,
    required this.event,
    required this.scale,
  });

  final Map<String, dynamic> event;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final String title = (event['title'] ?? '').toString().trim();
    final String photo = (event['bg_photo'] ?? '').toString().trim();
    final bool isNetwork = photo.startsWith('http');
    final String categoryIconPath = EventCatalog.categoryIconForName(
      ProfileEventHelpers.eventCategoryName(event),
    );
    final String typeIconPath = EventCatalog.typeIconForName(
      event['type']?.toString(),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: Stack(
        fit: StackFit.expand,
        children: [
          photo.isEmpty
              ? Image.asset(
                  EventCatalog.defaultBackgroundImage,
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
                ProfileTileIcon(
                  iconPath: categoryIconPath,
                  iconColor: Colors.white,
                  backgroundColor: const Color.fromARGB(51, 6, 0, 92),
                  borderColor: const Color.fromARGB(128, 0, 10, 218),
                  scale: scale,
                ),
                SizedBox(width: 5 * scale),
                ProfileTileIcon(
                  iconPath: typeIconPath,
                  iconColor: Colors.white,
                  backgroundColor: const Color.fromARGB(51, 0, 0, 0),
                  borderColor: const Color.fromARGB(128, 255, 255, 255),
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
                color: Colors.white,
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

class ProfileTileIcon extends StatelessWidget {
  const ProfileTileIcon({
    super.key,
    required this.iconPath,
    required this.scale,
    this.iconColor = Colors.white,
    this.backgroundColor = const Color.fromARGB(128, 0, 10, 218),
    this.borderColor = const Color.fromARGB(128, 255, 255, 255),
  });

  final String iconPath;
  final double scale;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: profileBlurValue,
          sigmaY: profileBlurValue,
        ),
        child: Container(
          width: 22 * scale,
          height: 22 * scale,
          padding: EdgeInsets.all(3 * scale),
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Image.asset(iconPath, color: iconColor),
        ),
      ),
    );
  }
}
