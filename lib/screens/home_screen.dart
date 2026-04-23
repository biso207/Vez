// developed and designed by outly • © 2026
// home screen — zone-2 content: vertical carousel of event cards.
//
// layout zones used:
//   zone 1 — background  : kBgColor from VezPageLayout
//   zone 2 — body        : PageView.builder (vertical swipe carousel)
//   zone 3 — blur veil   : handled by VezPageLayout
//   zone 4 — navbars     : top search bar + bottom pill nav

import 'package:flutter/material.dart';

import '../models/vez_event_card.dart';
import '../models/vez_glass.dart';
import '../models/vez_page_layout.dart';
import '../services/getters_service.dart';
import '../services/haptic_service.dart';
import '../services/translation_service.dart';
import '../services/user_session.dart';
import 'create_event/create_event_screen.dart';
import 'profile_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// stateful widget wrapper
// ─────────────────────────────────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// ─────────────────────────────────────────────────────────────────────────────
// state
// ─────────────────────────────────────────────────────────────────────────────

class _HomePageState extends State<HomePage> {

  // ── controllers & services ─────────────────────────────────────────────────

  final TextEditingController _searchController = TextEditingController();
  final GetDBService _db = GetDBService(userID: UserSession().userID);

  // ── state variables ────────────────────────────────────────────────────────

  /// currently selected filter group (0 = byYou, 1 = invited, 2 = nearby)
  int _filterIndex = 1;

  /// url (or local asset path) of the logged-in user's profile photo
  String _profilePhoto = '';

  // ── dummy data — replace with real async fetch ─────────────────────────────

  /// placeholder event list; will be replaced by a real API call
  final List<Map<String, dynamic>> _events = [
    {'image': 'assets/images/bg/bg_signup.jpg',  'type': EventType.nearby},
    {'image': 'assets/images/bg/bg_login.jpg',   'type': EventType.invited},
    {'image': 'assets/images/bg/bg_signup.jpg',  'type': EventType.byYou},
  ];

  // ── filter-icon list aligned with EventType order ──────────────────────────
  static const List<Map<String, dynamic>> _filterIcons = [
    {'icon': 'assets/icons/home_page/by_you_events.png',  'type': EventType.byYou},
    {'icon': 'assets/icons/home_page/invited_events.png', 'type': EventType.invited},
    {'icon': 'assets/icons/home_page/nearby_events.png',  'type': EventType.nearby},
  ];

  // ── lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadProfilePhoto();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── data loading ───────────────────────────────────────────────────────────

  /// fetches the user's profile photo url from the remote db on first load
  Future<void> _loadProfilePhoto() async {
    final String? photo = await _db.getUserData('profile_photo');
    if (!mounted) return;
    setState(() => _profilePhoto = photo?.trim() ?? '');
  }

  /// fetches the user's language
  Future<void> _loadUserLanguage() async {
    final String? lan = await _db.getUserData('language');
    if (!mounted) return;
    StringRes.setLocale(lan!);
  }

  // ── navigation helpers ─────────────────────────────────────────────────────

  void _goToProfile() => Navigator.pushReplacement(
    context, MaterialPageRoute(builder: (_) => ProfilePage()),
  );

  void _goToCreateEvent() {
    HapticService.tap();
    Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (_) => const CreateEvent()),
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final double s  = (sw / 390).clamp(0.8, 1.2);

    return VezPageLayout(
      // ── top navbar ──────────────────────────────────────────────────────
      searchController: _searchController,
      searchHint:       StringRes.at('search'),
      profileIconPath:  _profilePhoto,
      isProfileAvatar:  true,
      onProfileTap:     _goToProfile,

      // active filter icon reflects the current selection
      filterIconPath:   _filterIcons[_filterIndex]['icon'] as String,
      onFilterSelected: (index) => setState(() => _filterIndex = index),

      // ── bottom navbar ────────────────────────────────────────────────────
      bottomNavBar: _BottomNavPill(
        s: s,
        activeIndex: 0, // home is active on this screen
        onHomeTap:        () {},           // already on home
        onCreateEventTap: _goToCreateEvent,
        onNotificationsTap: () {},         // todo: notifications screen
      ),

      // ── zone-2 body: vertical event carousel ────────────────────────────
      body: _EventCarousel(events: _events, s: s),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EventCarousel — vertical PageView with peek above/below
// ─────────────────────────────────────────────────────────────────────────────

class _EventCarousel extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final double s;

  const _EventCarousel({required this.events, required this.s});

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      scrollDirection:  Axis.vertical,
      // viewportFraction < 1 reveals the top/bottom edges of adjacent cards
      controller:       PageController(viewportFraction: 0.75),
      itemCount:        events.length,
      itemBuilder:      (context, index) => Padding(
        padding: EdgeInsets.symmetric(vertical: 6 * s),
        child: VezEventCard(
          imagePath: events[index]['image'] as String,
          type:      events[index]['type']  as EventType,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BottomNavPill — shared pill-shaped bottom navigation bar (zone 4b).
//
// extracted as a standalone widget so every screen can import & reuse it
// without duplicating the pill decoration.
// ─────────────────────────────────────────────────────────────────────────────

class _BottomNavPill extends StatelessWidget {
  /// responsive scale factor passed from the parent screen
  final double s;

  /// 0 = home, 1 = create event, 2 = notifications
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
      radius:  BorderRadius.circular(40),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // home
          IconButton(
            icon: ImageIcon(
              const AssetImage('assets/icons/nav_bar/go_to_home_page.png'),
              color: activeIndex == 0 ? Colors.white : Colors.white54,
            ),
            iconSize: 30,
            onPressed: onHomeTap,
          ),

          SizedBox(width: 16 * s),

          // create event
          IconButton(
            icon: ImageIcon(
              const AssetImage('assets/icons/nav_bar/create_event.png'),
              color: activeIndex == 1 ? Colors.white : Colors.white54,
            ),
            iconSize: 30,
            onPressed: onCreateEventTap,
          ),

          SizedBox(width: 16 * s),

          // notifications
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

// ─────────────────────────────────────────────────────────────────────────────
// note: _BottomNavPill is also used by profile_screen.dart and
// create_event_screen.dart — consider moving it to a shared
// vez_bottom_nav.dart file if the project grows.
// ─────────────────────────────────────────────────────────────────────────────
