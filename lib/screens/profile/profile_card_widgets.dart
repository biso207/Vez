// Developed and Designed by Outly • © 2026
// profile_card_widgets.dart
//
// contains the primary profile-card visual widgets:
//   _UserCard        : outer glass card with photo, name, city, bio
//   _AvatarWithBadge : circular avatar + optional category badge overlay
//   _StatsPill       : horizontal pill showing followers / events / following
//   _StatItem        : single icon+number column used inside _StatsPill

part of 'profile_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// user card
// ─────────────────────────────────────────────────────────────────────────────

/// displays the primary user identity card (avatar, username, city, bio).
class _UserCard extends StatelessWidget {
  final double s;
  final String profilePhoto;
  final String username;
  final String cityAkaName;
  final String city;
  final String bio;
  final bool showBadge;

  const _UserCard({
    required this.s,
    required this.profilePhoto,
    required this.username,
    required this.cityAkaName,
    required this.city,
    required this.bio,
    required this.showBadge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(50, 0, 0, 0),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: const Color.fromARGB(128, 255, 255, 255),
          width: 2 * s,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // avatar with optional category badge
          _AvatarWithBadge(
            photo: profilePhoto,
            showBadge: showBadge,
            size: 75 * s,
          ),
          SizedBox(width: 16 * s),

          // text info column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // username
                Text(
                  username,
                  style: const TextStyle(
                    fontFamily: 'InstagramSans',
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                SizedBox(height: 4 * s),

                // city aka-name (bold) + city (light)
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: 'InstagramSans',
                      color: Colors.white,
                      fontSize: 14 * s,
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
                SizedBox(height: 4 * s),

                // bio
                Text(
                  bio,
                  style: TextStyle(
                    fontFamily: 'InstagramSans',
                    fontSize: 14 * s,
                    color: Colors.white,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// avatar with badge
// ─────────────────────────────────────────────────────────────────────────────

/// circular profile photo with an optional small category badge at top-right.
class _AvatarWithBadge extends StatelessWidget {
  final String photo;
  final bool showBadge;
  final double size;

  const _AvatarWithBadge({
    required this.photo,
    required this.showBadge,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // main circular avatar
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            image: DecorationImage(
              image: photo.isNotEmpty
                  ? NetworkImage(photo)
                  : const AssetImage(
                          'assets/icons/home_page/profile_photo.png')
                      as ImageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),

        // category badge overlay (blurred glass circle)
        // todo: replace static icon with the user's most-frequent category icon
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

// ─────────────────────────────────────────────────────────────────────────────
// stats pill
// ─────────────────────────────────────────────────────────────────────────────

/// horizontal pill showing followers, participated events, and following counts.
class _StatsPill extends StatelessWidget {
  final double s;
  final int numFollowers;
  final int numEvents;
  final int numFollowing;

  const _StatsPill({
    required this.s,
    required this.numFollowers,
    required this.numEvents,
    required this.numFollowing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(50, 0, 0, 0),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: const Color.fromARGB(128, 255, 255, 255),
          width: 2 * s,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(
            icon: 'assets/icons/profile_page/followers.png',
            value: numFollowers.toString(),
          ),
          _StatItem(
            icon: 'assets/icons/profile_page/participated_events.png',
            value: numEvents.toString(),
          ),
          _StatItem(
            icon: 'assets/icons/profile_page/following_requests.png',
            value: numFollowing.toString(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// stat item
// ─────────────────────────────────────────────────────────────────────────────

/// single icon + number column used inside the stats pill.
class _StatItem extends StatelessWidget {
  final String icon;
  final String value;

  const _StatItem({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(icon, width: 30, height: 30, color: Colors.white),
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
