import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/vez_event_card.dart';
import '../models/vez_glass.dart';
import '../models/vez_page_layout.dart';
import '../services/getters_service.dart';
import '../services/haptic_service.dart';
import '../services/translation_service.dart';
import '../services/user_session.dart';
import 'create_event/create_event_screen.dart';
import 'profile_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.initialFilterIndex = 0});

  final int initialFilterIndex;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _defaultEventBackground =
      'assets/images/bg/default_create_event_bg.jpg';
  static const String _emptyStateIcon =
      'assets/icons/home_page/no_event_found.png';

  static const List<Map<String, dynamic>> _filterIcons = [
    {
      'icon': 'assets/icons/home_page/by_you_events.png',
      'type': EventType.byYou,
    },
    {
      'icon': 'assets/icons/home_page/invited_events.png',
      'type': EventType.invited,
    },
    {
      'icon': 'assets/icons/home_page/nearby_events.png',
      'type': EventType.nearby,
    },
  ];

  final TextEditingController _searchController = TextEditingController();
  final GetDBService _db = GetDBService(userID: UserSession().userID);

  late int _filterIndex;
  String _profilePhoto = '';
  bool _isLoadingEvents = true;
  Map<EventType, List<HomeEventCardData>> _eventsByType = {
    EventType.byYou: const [],
    EventType.invited: const [],
    EventType.nearby: const [],
  };

  @override
  void initState() {
    super.initState();
    _filterIndex = widget.initialFilterIndex.clamp(0, _filterIcons.length - 1);
    _loadPageData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPageData() async {
    await _loadUserLanguage();
    await Future.wait([_loadProfilePhoto(), _loadEvents()]);
  }

  Future<void> _loadProfilePhoto() async {
    final String? photo = await _db.getUserData('profile_photo');
    if (!mounted) return;
    setState(() => _profilePhoto = photo?.trim() ?? '');
  }

  Future<void> _loadUserLanguage() async {
    final String? lan = await _db.getUserData('language');
    if (lan != null && lan.isNotEmpty) {
      StringRes.setLocale(lan);
    }
  }

  Future<void> _loadEvents() async {
    final List<Map<String, dynamic>> createdEvents = await _db
        .getCreatedEvents();
    final List<Map<String, dynamic>> invitedEvents = await _db
        .getInvitedEvents();

    if (!mounted) return;

    setState(() {
      _eventsByType = {
        EventType.byYou: _mapEvents(
          createdEvents.where(_isCreatedByCurrentUser).toList(),
          EventType.byYou,
        ),
        EventType.invited: _mapEvents(invitedEvents, EventType.invited),
        EventType.nearby: const [],
      };
      _isLoadingEvents = false;
    });
  }

  bool _isCreatedByCurrentUser(Map<String, dynamic> event) {
    return (event['creator_user_id']?.toString() ?? '') == UserSession().userID;
  }

  List<HomeEventCardData> _mapEvents(
    List<Map<String, dynamic>> rawEvents,
    EventType type,
  ) {
    return rawEvents.map((event) {
      final String rawImage = (event['bg_photo'] ?? '').toString().trim();
      return HomeEventCardData(
        imagePath: rawImage.isNotEmpty ? rawImage : _defaultEventBackground,
        type: type,
        title: (event['title'] ?? '').toString().trim(),
        subtitle: _formatEventDate(event['date_event']?.toString()),
      );
    }).toList();
  }

  String _formatEventDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '';

    try {
      final DateTime parsed = DateTime.parse(rawDate).toLocal();
      return DateFormat('dd MMM, HH:mm', StringRes.locale).format(parsed);
    } catch (_) {
      return '';
    }
  }

  EventType get _selectedType =>
      _filterIcons[_filterIndex]['type'] as EventType;

  List<HomeEventCardData> get _visibleEvents =>
      _eventsByType[_selectedType] ?? const [];

  void _goToProfile() => Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => const ProfilePage()),
  );

  void _goToCreateEvent() {
    HapticService.tap();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CreateEvent()),
    );
  }

  String _emptyStateTitle() {
    switch (_selectedType) {
      case EventType.byYou:
        return StringRes.at('no_events_by_you');
      case EventType.invited:
        return StringRes.at('no_events_invited');
      case EventType.nearby:
        return StringRes.at('no_events_nearby');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final double s = (sw / 390).clamp(0.8, 1.2);

    return VezPageLayout(
      searchController: _searchController,
      searchHint: StringRes.at('search'),
      profileIconPath: _profilePhoto,
      isProfileAvatar: true,
      onProfileTap: _goToProfile,
      filterIconPath: _filterIcons[_filterIndex]['icon'] as String,
      onFilterSelected: (index) => setState(() => _filterIndex = index),
      bottomNavBar: _BottomNavPill(
        s: s,
        activeIndex: 0,
        onHomeTap: () {},
        onCreateEventTap: _goToCreateEvent,
        onNotificationsTap: () {},
      ),
      body: _EventCarousel(
        events: _visibleEvents,
        s: s,
        isLoading: _isLoadingEvents,
        emptyStateTitle: _emptyStateTitle(),
        emptyStateIconPath: _emptyStateIcon,
      ),
    );
  }
}

class _EventCarousel extends StatelessWidget {
  const _EventCarousel({
    required this.events,
    required this.s,
    required this.isLoading,
    required this.emptyStateTitle,
    required this.emptyStateIconPath,
  });

  final List<HomeEventCardData> events;
  final double s;
  final bool isLoading;
  final String emptyStateTitle;
  final String emptyStateIconPath;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (events.isEmpty) {
      return _EmptyEventsState(
        s: s,
        title: emptyStateTitle,
        iconPath: emptyStateIconPath,
      );
    }

    return PageView.builder(
      scrollDirection: Axis.vertical,
      controller: PageController(viewportFraction: 0.75),
      itemCount: events.length,
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.symmetric(vertical: 6 * s),
        child: VezEventCard(
          imagePath: events[index].imagePath,
          type: events[index].type,
          title: events[index].title,
          subtitle: events[index].subtitle,
        ),
      ),
    );
  }
}

class _EmptyEventsState extends StatelessWidget {
  const _EmptyEventsState({
    required this.s,
    required this.title,
    required this.iconPath,
  });

  final double s;
  final String title;
  final String iconPath;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28 * s),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              iconPath,
              width: 90 * s,
              height: 90 * s,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 18 * s),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20 * s,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavPill extends StatelessWidget {
  const _BottomNavPill({
    required this.s,
    required this.activeIndex,
    required this.onHomeTap,
    required this.onCreateEventTap,
    required this.onNotificationsTap,
  });

  final double s;
  final int activeIndex;
  final VoidCallback onHomeTap;
  final VoidCallback onCreateEventTap;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return VezGlass.container(
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 0),
      radius: BorderRadius.circular(40),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: ImageIcon(
              const AssetImage('assets/icons/nav_bar/go_to_home_page.png'),
              color: activeIndex == 0 ? Colors.white : Colors.white54,
            ),
            iconSize: 30,
            onPressed: onHomeTap,
          ),
          SizedBox(width: 16 * s),
          IconButton(
            icon: ImageIcon(
              const AssetImage('assets/icons/nav_bar/create_event.png'),
              color: activeIndex == 1 ? Colors.white : Colors.white54,
            ),
            iconSize: 30,
            onPressed: onCreateEventTap,
          ),
          SizedBox(width: 16 * s),
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
