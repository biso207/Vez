import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/getters_service.dart';
import '../services/translation_service.dart';
import '../services/user_session.dart';
import '../views/widgets/vez_glass.dart';
import '../views/widgets/vez_page_layout.dart';
import 'create_event/create_event_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final TextEditingController _searchController = TextEditingController();
  final GetDBService _db = GetDBService(userID: UserSession().userID);

  bool _isLoading = true;
  String _profilePhoto = '';
  List<Map<String, dynamic>> _notifications = const [];

  @override
  void initState() {
    super.initState();
    _loadPageData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPageData() async {
    final results = await Future.wait([
      _db.getUserData('profile_photo'),
      _db.getInviteNotifications(),
    ]);

    if (!mounted) return;

    setState(() {
      _profilePhoto = (results[0] as String?)?.trim() ?? '';
      _notifications = results[1] as List<Map<String, dynamic>>;
      _isLoading = false;
    });
  }

  void _goToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomePage(initialFilterIndex: 1)),
      (route) => false,
    );
  }

  void _openNotificationEvent(String? eventId) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            HomePage(initialFilterIndex: 1, initialEventId: eventId),
      ),
      (route) => false,
    );
  }

  void _goToCreateEvent() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateEvent()),
    ).then((_) => _loadPageData());
  }

  void _goToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    ).then((_) => _loadPageData());
  }

  List<Map<String, dynamic>> get _visibleNotifications {
    final String query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _notifications;

    return _notifications.where((row) {
      final Map<String, dynamic> event = row['event'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(row['event'] as Map<String, dynamic>)
          : row['event'] is Map
          ? Map<String, dynamic>.from(row['event'] as Map)
          : <String, dynamic>{};
      final Map<String, dynamic> creator =
          event['creator'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(event['creator'] as Map<String, dynamic>)
          : event['creator'] is Map
          ? Map<String, dynamic>.from(event['creator'] as Map)
          : <String, dynamic>{};
      final Map<String, dynamic> place = event['place'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(event['place'] as Map<String, dynamic>)
          : event['place'] is Map
          ? Map<String, dynamic>.from(event['place'] as Map)
          : <String, dynamic>{};

      final String title = (event['title'] ?? '').toString().toLowerCase();
      final String host = (creator['username'] ?? '').toString().toLowerCase();
      final String location = (place['name'] ?? '').toString().toLowerCase();

      return title.contains(query) ||
          host.contains(query) ||
          location.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final double s = (sw / 390).clamp(0.8, 1.2);
    final double topInset = MediaQuery.of(context).padding.top + 108 * s;

    return VezPageLayout(
      searchController: _searchController,
      searchHint: StringRes.at('search'),
      profileIconPath: _profilePhoto,
      isProfileAvatar: true,
      onProfileTap: _goToProfile,
      filterIconPath: 'assets/icons/nav_bar/notifications.png',
      onFilterSelected: (_) {},
      bottomNavBar: _BottomNavPill(
        s: s,
        activeIndex: 2,
        onHomeTap: _goToHome,
        onCreateEventTap: _goToCreateEvent,
        onNotificationsTap: () {},
      ),
      body: Padding(
        padding: EdgeInsets.only(top: topInset),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _visibleNotifications.isEmpty
            ? _EmptyNotificationsState(
                s: s,
                title: StringRes.at('no_events_invited'),
              )
            : ListView.separated(
                padding: EdgeInsets.fromLTRB(20 * s, 0, 20 * s, 140 * s),
                itemCount: _visibleNotifications.length,
                separatorBuilder: (_, _) => SizedBox(height: 14 * s),
                itemBuilder: (_, index) => _NotificationCard(
                  row: _visibleNotifications[index],
                  s: s,
                  onTap: _openNotificationEvent,
                ),
              ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.row,
    required this.s,
    required this.onTap,
  });

  final Map<String, dynamic> row;
  final double s;
  final ValueChanged<String?> onTap;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> event = row['event'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(row['event'] as Map<String, dynamic>)
        : row['event'] is Map
        ? Map<String, dynamic>.from(row['event'] as Map)
        : <String, dynamic>{};
    final Map<String, dynamic> creator =
        event['creator'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(event['creator'] as Map<String, dynamic>)
        : event['creator'] is Map
        ? Map<String, dynamic>.from(event['creator'] as Map)
        : <String, dynamic>{};
    final Map<String, dynamic> place = event['place'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(event['place'] as Map<String, dynamic>)
        : event['place'] is Map
        ? Map<String, dynamic>.from(event['place'] as Map)
        : <String, dynamic>{};

    final String response = (row['response'] ?? '').toString();
    final String state = _normalizeState(response);
    final String title = (event['title'] ?? '').toString().trim();
    final String eventId = (event['event_id'] ?? row['event_id'] ?? '')
        .toString()
        .trim();
    final String host = (creator['username'] ?? '').toString().trim();
    final String photo = (creator['profile_photo'] ?? '').toString().trim();
    final String placeName = (place['name'] ?? '').toString().trim();
    final String dateLabel = _formatDate(
      (event['date_event'] ?? row['invited_at'])?.toString(),
    );
    final String invitedAt = _formatDate(row['invited_at']?.toString());

    return GestureDetector(
      onTap: () => onTap(eventId.isNotEmpty ? eventId : null),
      child: VezGlass.container(
        padding: EdgeInsets.all(14 * s),
        radius: BorderRadius.circular(26),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NotificationAvatar(photo: photo),
            SizedBox(width: 12 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title.isNotEmpty ? title : 'Untitled Event',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18 * s,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 10 * s),
                      _NotificationStatePill(state: state),
                    ],
                  ),
                  SizedBox(height: 6 * s),
                  Text(
                    host.isNotEmpty ? host : StringRes.at('host'),
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14 * s,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (dateLabel.isNotEmpty) ...[
                    SizedBox(height: 4 * s),
                    Text(
                      dateLabel,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13 * s,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (placeName.isNotEmpty) ...[
                    SizedBox(height: 2 * s),
                    Text(
                      placeName,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13 * s,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (invitedAt.isNotEmpty) ...[
                    SizedBox(height: 10 * s),
                    Text(
                      invitedAt,
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12 * s,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _normalizeState(String rawState) {
    final String normalized = rawState.trim().toLowerCase().replaceAll(
      ' ',
      '_',
    );
    if (normalized == 'going' ||
        normalized == 'accepted' ||
        normalized == 'yes') {
      return 'going';
    }
    if (normalized == 'not_going' ||
        normalized == 'notgoing' ||
        normalized == 'declined' ||
        normalized == 'no') {
      return 'not_going';
    }
    return 'maybe';
  }

  static String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '';
    try {
      final DateTime parsed = DateTime.parse(rawDate).toLocal();
      return DateFormat('dd/MM/yyyy • HH:mm', StringRes.locale).format(parsed);
    } catch (_) {
      return '';
    }
  }
}

class _NotificationAvatar extends StatelessWidget {
  const _NotificationAvatar({required this.photo});

  final String photo;

  @override
  Widget build(BuildContext context) {
    final bool isNetworkImage = photo.startsWith('http');

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1.6),
      ),
      child: ClipOval(
        child: photo.isEmpty
            ? const Icon(Icons.person, color: Colors.white70)
            : Image(
                image: isNetworkImage
                    ? NetworkImage(photo)
                    : AssetImage(photo) as ImageProvider,
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}

class _NotificationStatePill extends StatelessWidget {
  const _NotificationStatePill({required this.state});

  final String state;

  @override
  Widget build(BuildContext context) {
    final String label = switch (state) {
      'going' => StringRes.at('going'),
      'not_going' => StringRes.at('not_going'),
      _ => StringRes.at('maybe'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color.fromARGB(60, 255, 255, 255),
        border: Border.all(color: Colors.white24, width: 1.3),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyNotificationsState extends StatelessWidget {
  const _EmptyNotificationsState({required this.s, required this.title});

  final double s;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28 * s),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icons/nav_bar/notifications.png',
              width: 84 * s,
              height: 84 * s,
              color: Colors.white70,
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
