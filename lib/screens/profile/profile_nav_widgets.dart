// developed and designed by Outly • © 2026
// profile_nav_widgets.dart
//
// contains the bottom navigation pill shown on the profile screen:
//   _BottomNavPill : glass pill with home / create-event / notifications icons

part of 'profile_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// bottom nav pill
// ─────────────────────────────────────────────────────────────────────────────

/// glass pill at screen bottom with three navigation icon buttons.
class _BottomNavPill extends StatelessWidget {
  final double s;
  final int activeIndex;
  final VoidCallback onHomeTap;
  final VoidCallback onCreateEventTap;
  final VoidCallback onNotificationsTap;

  const _BottomNavPill({
    required this.s,
    required this.activeIndex,
    required this.onHomeTap,
    required this.onCreateEventTap,
    required this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    return VezGlass.container(
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 0),
      radius: BorderRadius.circular(40),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // home button
          IconButton(
            icon: ImageIcon(
              const AssetImage('assets/icons/nav_bar/go_to_home_page.png'),
              color: activeIndex == 0 ? Colors.white : Colors.white54,
            ),
            iconSize: 30,
            onPressed: onHomeTap,
          ),
          SizedBox(width: 16 * s),

          // create-event button
          IconButton(
            icon: ImageIcon(
              const AssetImage('assets/icons/nav_bar/create_event.png'),
              color: activeIndex == 1 ? Colors.white : Colors.white54,
            ),
            iconSize: 30,
            onPressed: onCreateEventTap,
          ),
          SizedBox(width: 16 * s),

          // notifications button
          IconButton(
            icon: ImageIcon(
              const AssetImage('assets/icons/nav_bar/notifications.png'),
              color: activeIndex == 2 ? Colors.white : Colors.white54,
            ),
            iconSize: 30,
            onPressed: onNotificationsTap,
          ),
        ],
      ),
    );
  }
}
