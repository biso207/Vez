import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/event_catalog.dart';
import '../models/vez_event_card.dart';
import '../models/vez_glass.dart';
import '../models/vez_page_layout.dart';
import '../models/vez_popup.dart';
import '../services/getters_service.dart';
import '../services/haptic_service.dart';
import '../services/setters_service.dart';
import '../services/translation_service.dart';
import '../services/user_session.dart';
import 'create_event/create_event_screen.dart';
import 'profile_screen.dart';

enum _GuestAudienceFilter { friends, following, anyone }

enum _GuestStateFilter { all, going, notGoing, maybe }

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.initialFilterIndex = 0});

  final int initialFilterIndex;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Duration _inviteMaybeTimeout = Duration(hours: 24);
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
  final SetDBService _dbSet = SetDBService(userID: UserSession().userID);

  late int _filterIndex;
  String _profilePhoto = '';
  bool _isLoadingEvents = true;
  List<Map<String, dynamic>> _allUsers = const [];
  Set<String> _followingIds = const {};
  Set<String> _followerIds = const {};
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
    final List<Map<String, dynamic>> createdEvents = await _db.getCreatedEvents();
    final List<Map<String, dynamic>> invitedEvents = await _db.getInvitedEvents();

    if (!mounted) return;

    setState(() {
      _eventsByType = {
        EventType.byYou: _mapEvents(createdEvents, EventType.byYou),
        EventType.invited: _mapEvents(invitedEvents, EventType.invited),
        EventType.nearby: const [],
      };
      _isLoadingEvents = false;
    });
  }

  Future<void> _ensureUserDirectoryLoaded() async {
    if (_allUsers.isNotEmpty) return;

    final results = await Future.wait([
      _db.getUsersBasic(),
      _db.getFollowing(),
      _db.getFollowers(),
    ]);

    final List<Map<String, dynamic>> users =
    results[0] as List<Map<String, dynamic>>;
    final List<Map<String, dynamic>> following =
    results[1] as List<Map<String, dynamic>>;
    final List<Map<String, dynamic>> followers =
    results[2] as List<Map<String, dynamic>>;

    _allUsers = users;
    _followingIds = following
        .map((row) => (row['following_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();
    _followerIds = followers
        .map((row) => (row['follower_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<HomeEventCardData?> _refreshByYouEvent(String eventId) async {
    final Map<String, dynamic>? rawEvent = await _db.getEventById(eventId);
    if (rawEvent == null) return null;
    return _mapEvent(rawEvent, EventType.byYou);
  }

  void _upsertByYouEvent(HomeEventCardData event) {
    final List<HomeEventCardData> updatedEvents = [
      ...(_eventsByType[EventType.byYou] ?? const []),
    ];
    final int index = updatedEvents.indexWhere(
          (item) => item.eventId == event.eventId,
    );

    if (index >= 0) {
      updatedEvents[index] = event;
    } else {
      updatedEvents.add(event);
    }

    updatedEvents.sort((a, b) => a.rawDateEvent.compareTo(b.rawDateEvent));

    if (!mounted) return;
    setState(() {
      _eventsByType = {
        ..._eventsByType,
        EventType.byYou: updatedEvents,
      };
    });
  }

  List<HomeEventCardData> _mapEvents(
      List<Map<String, dynamic>> rawEvents,
      EventType type,
      ) {
    return rawEvents.map((event) => _mapEvent(event, type)).toList();
  }

  HomeEventCardData _mapEvent(
      Map<String, dynamic> rawEvent,
      EventType type,
      ) {
    final Map<String, dynamic> place =
    rawEvent['place'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(rawEvent['place'] as Map<String, dynamic>)
        : rawEvent['place'] is Map
        ? Map<String, dynamic>.from(rawEvent['place'] as Map)
        : <String, dynamic>{};
    final Map<String, dynamic> category =
    rawEvent['event_category'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(
      rawEvent['event_category'] as Map<String, dynamic>,
    )
        : rawEvent['event_category'] is Map
        ? Map<String, dynamic>.from(rawEvent['event_category'] as Map)
        : <String, dynamic>{};
    final Map<String, dynamic> creator =
    rawEvent['creator'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(rawEvent['creator'] as Map<String, dynamic>)
        : rawEvent['creator'] is Map
        ? Map<String, dynamic>.from(rawEvent['creator'] as Map)
        : <String, dynamic>{};

    final String visibility =
    EventCatalog.normalizeTypeName(rawEvent['type']?.toString());
    final String categoryName =
    (category['name'] ?? '').toString().trim().isNotEmpty
        ? (category['name'] ?? '').toString().trim()
        : 'cinema';
    final String rawImage = (rawEvent['bg_photo'] ?? '').toString().trim();
    final List<HomeEventGuestData> guests = _mapGuests(rawEvent, visibility);
    final HomeEventGuestCounts guestCounts = _countGuests(guests);
    final String placeName = (place['name'] ?? '').toString().trim();
    final String rawDate = (rawEvent['date_event'] ?? '').toString();

    return HomeEventCardData(
      eventId: (rawEvent['event_id'] ?? '').toString(),
      imagePath: rawImage,
      type: type,
      title: (rawEvent['title'] ?? '').toString().trim(),
      subtitle: _buildSubtitle(rawDate, placeName),
      typeLabel: visibility,
      categoryName: categoryName,
      categoryIconPath: EventCatalog.categoryIconForName(categoryName),
      typeIconPath: EventCatalog.typeIconForName(visibility),
      dateLabel: _formatCardDate(rawDate),
      locationLabel: placeName,
      rawDateEvent: rawDate,
      creatorUserId: (rawEvent['creator_user_id'] ?? '').toString(),
      creatorUsername: (creator['username'] ?? '').toString().trim(),
      creatorProfilePhoto: (creator['profile_photo'] ?? '').toString().trim(),
      description: (rawEvent['description'] ?? '').toString().trim(),
      placeId: (rawEvent['place_id'] ?? '').toString(),
      placeAddress: (place['address'] ?? '').toString().trim(),
      locationPrecise: place['is_precise'] == true,
      latitude: (place['latitude'] as num?)?.toDouble(),
      longitude: (place['longitude'] as num?)?.toDouble(),
      maxGuests: (rawEvent['max_participants'] as num?)?.toInt(),
      price: (rawEvent['price'] as num?)?.toInt(),
      guestCounts: guestCounts,
      guests: guests,
    );
  }

  List<HomeEventGuestData> _mapGuests(
      Map<String, dynamic> rawEvent,
      String visibility,
      ) {
    if (EventCatalog.canInviteGuests(visibility)) {
      final List<dynamic> inviteRows =
          (rawEvent['event_invites'] as List<dynamic>?) ?? const [];
      return inviteRows
          .whereType<Map>()
          .map((row) => _mapInviteGuest(Map<String, dynamic>.from(row)))
          .toList();
    }

    final List<dynamic> participationRows =
        (rawEvent['participation'] as List<dynamic>?) ?? const [];
    return participationRows
        .whereType<Map>()
        .map(
          (row) => _mapParticipationGuest(Map<String, dynamic>.from(row)),
    )
        .toList();
  }

  HomeEventGuestData _mapInviteGuest(Map<String, dynamic> row) {
    final Map<String, dynamic> user =
    row['users'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(row['users'] as Map<String, dynamic>)
        : row['users'] is Map
        ? Map<String, dynamic>.from(row['users'] as Map)
        : <String, dynamic>{};

    return HomeEventGuestData(
      userId: (row['user_id'] ?? '').toString(),
      username: (user['username'] ?? '').toString().trim(),
      profilePhoto: (user['profile_photo'] ?? '').toString().trim(),
      state: _normalizeInviteState(
        row['response']?.toString(),
        referenceTimestamp:
        (row['responded_at'] ?? row['invited_at'])?.toString(),
      ),
      role: (row['role'] ?? 'guest').toString(),
    );
  }

  HomeEventGuestData _mapParticipationGuest(Map<String, dynamic> row) {
    final Map<String, dynamic> user =
    row['users'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(row['users'] as Map<String, dynamic>)
        : row['users'] is Map
        ? Map<String, dynamic>.from(row['users'] as Map)
        : <String, dynamic>{};

    return HomeEventGuestData(
      userId: (row['user_id'] ?? '').toString(),
      username: (user['username'] ?? '').toString().trim(),
      profilePhoto: (user['profile_photo'] ?? '').toString().trim(),
      state: _normalizeParticipationState(
        row['participation_state']?.toString(),
      ),
    );
  }

  HomeEventGuestCounts _countGuests(List<HomeEventGuestData> guests) {
    int going = 0;
    int notGoing = 0;
    int maybe = 0;

    for (final guest in guests) {
      switch (guest.state) {
        case 'going':
          going++;
          break;
        case 'not_going':
          notGoing++;
          break;
        default:
          maybe++;
      }
    }

    return HomeEventGuestCounts(
      going: going,
      notGoing: notGoing,
      maybe: maybe,
    );
  }

  String _normalizeInviteState(
      String? rawState, {
        String? referenceTimestamp,
      }) {
    final String normalized = (rawState ?? '')
        .trim()
        .toLowerCase()
        .replaceAll(' ', '_');

    if (normalized.isEmpty ||
        normalized == 'maybe' ||
        normalized == 'pending' ||
        normalized == 'invited') {
      return _isInviteExpired(referenceTimestamp) ? 'not_going' : 'maybe';
    }

    if (normalized == 'accepted' || normalized == 'yes' || normalized == 'going') {
      return 'going';
    }

    if (normalized == 'declined' ||
        normalized == 'no' ||
        normalized == 'notgoing' ||
        normalized == 'not_going') {
      return 'not_going';
    }

    if (normalized.contains('not')) return 'not_going';
    if (normalized.contains('go')) return 'going';
    return _isInviteExpired(referenceTimestamp) ? 'not_going' : 'maybe';
  }

  String _normalizeParticipationState(String? rawState) {
    final String normalized = (rawState ?? '')
        .trim()
        .toLowerCase()
        .replaceAll(' ', '_');

    if (normalized == 'going' || normalized == 'accepted' || normalized == 'yes') {
      return 'going';
    }
    if (normalized == 'notgoing' ||
        normalized == 'not_going' ||
        normalized == 'declined' ||
        normalized == 'no') {
      return 'not_going';
    }
    return 'maybe';
  }

  bool _isInviteExpired(String? rawTimestamp) {
    if (rawTimestamp == null || rawTimestamp.isEmpty) return false;

    final DateTime? timestamp = DateTime.tryParse(rawTimestamp);
    if (timestamp == null) return false;

    return DateTime.now().toUtc().difference(timestamp.toUtc()) >
        _inviteMaybeTimeout;
  }

  String _buildSubtitle(String rawDate, String placeName) {
    final String date = _formatEventDate(rawDate);
    if (date.isEmpty) return placeName;
    if (placeName.isEmpty) return date;
    return '$date • $placeName';
  }

  String _formatCardDate(String rawDate) {
    if (rawDate.isEmpty) return '';
    try {
      final DateTime parsed = DateTime.parse(rawDate).toLocal();
      return DateFormat('dd/MM/yyyy • HH:mm', StringRes.locale).format(parsed);
    } catch (_) {
      return '';
    }
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

  EventType get _selectedType => _filterIcons[_filterIndex]['type'] as EventType;

  List<HomeEventCardData> get _visibleEvents => _eventsByType[_selectedType] ?? const [];

  void _goToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    ).then((_) async {
      if (!mounted) return;
      await Future.wait([_loadProfilePhoto(), _loadEvents()]);
    });
  }

  void _goToCreateEvent() {
    HapticService.tap();
    Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateEvent()),
    ).then((changed) async {
      if (changed == true && mounted) {
        await _loadEvents();
      }
    });
  }

  void _editEvent(HomeEventCardData event) {
    HapticService.tap();
    Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CreateEvent(editingEvent: event)),
    ).then((changed) async {
      if (changed == true && mounted) {
        await _loadEvents();
      }
    });
  }

  void _showGuestListPopup(HomeEventCardData event) {
    final TextEditingController searchController = TextEditingController();
    HomeEventCardData currentEvent = event;
    _GuestStateFilter statusFilter = _GuestStateFilter.all;
    bool isBusy = false;
    final double popupWidth = MediaQuery.of(context).size.width * 0.82;
    final double popupHeight = MediaQuery.of(context).size.height * 0.62;

    VezPopup.show(
      context: context,
      width: popupWidth,
      height: popupHeight,
      child: StatefulBuilder(
        builder: (context, setPopupState) {
          final List<HomeEventGuestData> visibleGuests = currentEvent.guests
              .where((guest) => _matchesGuestStateFilter(guest, statusFilter))
              .where(
                (guest) => guest.username.toLowerCase().contains(
              searchController.text.trim().toLowerCase(),
            ),
          )
              .toList();

          Future<void> refreshCurrentEvent() async {
            final HomeEventCardData? refreshed =
            await _refreshByYouEvent(currentEvent.eventId);
            if (refreshed == null) return;
            currentEvent = refreshed;
            _upsertByYouEvent(refreshed);
            setPopupState(() {});
          }

          Future<void> removeGuest(String userId) async {
            setPopupState(() => isBusy = true);
            final int res = await _dbSet.removeEventInvite(
              eventId: currentEvent.eventId,
              invitedUserId: userId,
            );
            if (res == 200 || res == 204) {
              await refreshCurrentEvent();
            } else {
              _showSnackBar(StringRes.at('guest_remove_failed'), isError: true);
            }
            setPopupState(() => isBusy = false);
          }

          return Column(
            children: [
              _PopupHeaderBar(
                title: StringRes.at('guest_list'),
                onClose: () => Navigator.pop(context),
                action: currentEvent.canInviteGuests
                    ? IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showAddGuestPopup(currentEvent);
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                )
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _PopupSearchField(
                  controller: searchController,
                  hint: StringRes.at('search_guest'),
                  onChanged: (_) => setPopupState(() {}),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PopupFilterChip(
                      label: StringRes.at('all'),
                      isActive: statusFilter == _GuestStateFilter.all,
                      onTap: () => setPopupState(
                            () => statusFilter = _GuestStateFilter.all,
                      ),
                    ),
                    _PopupFilterChip(
                      label: StringRes.at('going'),
                      isActive: statusFilter == _GuestStateFilter.going,
                      onTap: () => setPopupState(
                            () => statusFilter = _GuestStateFilter.going,
                      ),
                    ),
                    _PopupFilterChip(
                      label: StringRes.at('not_going'),
                      isActive: statusFilter == _GuestStateFilter.notGoing,
                      onTap: () => setPopupState(
                            () => statusFilter = _GuestStateFilter.notGoing,
                      ),
                    ),
                    _PopupFilterChip(
                      label: StringRes.at('maybe'),
                      isActive: statusFilter == _GuestStateFilter.maybe,
                      onTap: () => setPopupState(
                            () => statusFilter = _GuestStateFilter.maybe,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _PopupGuestRow(
                      username: currentEvent.creatorUsername.isNotEmpty
                          ? currentEvent.creatorUsername
                          : StringRes.at('host'),
                      profilePhoto: currentEvent.creatorProfilePhoto,
                      state: 'going',
                      trailing: _RoleBadge(label: StringRes.at('host')),
                    ),
                    const SizedBox(height: 10),
                    if (visibleGuests.isEmpty)
                      _PopupEmptyState(title: StringRes.at('no_guests_yet'))
                    else
                      ...visibleGuests.map(
                            (guest) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PopupGuestRow(
                            username: guest.username,
                            profilePhoto: guest.profilePhoto,
                            state: guest.state,
                            trailing: currentEvent.canInviteGuests
                                ? IconButton(
                              onPressed: isBusy
                                  ? null
                                  : () => removeGuest(guest.userId),
                              icon: const Icon(
                                Icons.remove_circle_rounded,
                                color: Color(0xFFFF3131),
                              ),
                            )
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _PopupCountsFooter(counts: currentEvent.guestCounts),
              ),
            ],
          );
        },
      ),
    ).whenComplete(searchController.dispose);
  }

  Future<void> _showAddGuestPopup(HomeEventCardData event) async {
    await _ensureUserDirectoryLoaded();
    if (!mounted) return;

    final TextEditingController searchController = TextEditingController();
    HomeEventCardData currentEvent = event;
    _GuestAudienceFilter audienceFilter = _GuestAudienceFilter.friends;
    bool isBusy = false;
    final double popupWidth = MediaQuery.of(context).size.width * 0.82;
    final double popupHeight = MediaQuery.of(context).size.height * 0.62;

    VezPopup.show(
      context: context,
      width: popupWidth,
      height: popupHeight,
      child: StatefulBuilder(
        builder: (context, setPopupState) {
          final Set<String> excludedIds = {
            currentEvent.creatorUserId,
            ...currentEvent.guests.map((guest) => guest.userId),
          };

          final Set<String> friendIds = _followingIds.intersection(_followerIds);

          final List<Map<String, dynamic>> candidates = _allUsers.where((user) {
            final String userId = (user['user_id'] ?? '').toString();
            final String username = (user['username'] ?? '').toString();
            if (userId.isEmpty || excludedIds.contains(userId)) return false;

            final String query = searchController.text.trim().toLowerCase();
            if (query.isNotEmpty && !username.toLowerCase().contains(query)) {
              return false;
            }

            switch (audienceFilter) {
              case _GuestAudienceFilter.friends:
                return friendIds.contains(userId);
              case _GuestAudienceFilter.following:
                return _followingIds.contains(userId);
              case _GuestAudienceFilter.anyone:
                return true;
            }
          }).toList();

          Future<void> addGuest(String userId) async {
            setPopupState(() => isBusy = true);
            final int res = await _dbSet.addOrUpdateEventInvite(
              eventId: currentEvent.eventId,
              invitedUserId: userId,
            );
            if (res == 200 || res == 201 || res == 204) {
              final HomeEventCardData? refreshed =
              await _refreshByYouEvent(currentEvent.eventId);
              if (refreshed != null) {
                currentEvent = refreshed;
                _upsertByYouEvent(refreshed);
                setPopupState(() {});
              }
            } else {
              _showSnackBar(StringRes.at('guest_add_failed'), isError: true);
            }
            setPopupState(() => isBusy = false);
          }

          return Column(
            children: [
              _PopupHeaderBar(
                title: StringRes.at('add_guest'),
                onClose: () => Navigator.pop(context),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _PopupSearchField(
                  controller: searchController,
                  hint: StringRes.at('search_guest'),
                  onChanged: (_) => setPopupState(() {}),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PopupFilterChip(
                      label: StringRes.at('friends'),
                      isActive: audienceFilter == _GuestAudienceFilter.friends,
                      onTap: () => setPopupState(
                            () => audienceFilter = _GuestAudienceFilter.friends,
                      ),
                    ),
                    _PopupFilterChip(
                      label: StringRes.at('following'),
                      isActive: audienceFilter == _GuestAudienceFilter.following,
                      onTap: () => setPopupState(
                            () => audienceFilter = _GuestAudienceFilter.following,
                      ),
                    ),
                    _PopupFilterChip(
                      label: StringRes.at('anyone'),
                      isActive: audienceFilter == _GuestAudienceFilter.anyone,
                      onTap: () => setPopupState(
                            () => audienceFilter = _GuestAudienceFilter.anyone,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: candidates.isEmpty
                    ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _PopupEmptyState(
                    title: StringRes.at('no_users_found'),
                  ),
                )
                    : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: candidates.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final Map<String, dynamic> user = candidates[index];
                    final String userId =
                    (user['user_id'] ?? '').toString();
                    return _PopupUserActionRow(
                      username: (user['username'] ?? '').toString(),
                      profilePhoto:
                      (user['profile_photo'] ?? '').toString(),
                      label: _relationLabel(userId),
                      icon: Icons.person_add_alt_1_rounded,
                      iconColor: const Color(0xFF089D0D),
                      onTap: isBusy ? null : () => addGuest(userId),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _PopupCountsFooter(counts: currentEvent.guestCounts),
              ),
            ],
          );
        },
      ),
    ).whenComplete(searchController.dispose);
  }

  bool _matchesGuestStateFilter(
      HomeEventGuestData guest,
      _GuestStateFilter filter,
      ) {
    switch (filter) {
      case _GuestStateFilter.all:
        return true;
      case _GuestStateFilter.going:
        return guest.state == 'going';
      case _GuestStateFilter.notGoing:
        return guest.state == 'not_going';
      case _GuestStateFilter.maybe:
        return guest.state == 'maybe';
    }
  }

  String _relationLabel(String userId) {
    if (_followingIds.contains(userId) && _followerIds.contains(userId)) {
      return StringRes.at('friends');
    }
    if (_followingIds.contains(userId)) {
      return StringRes.at('following');
    }
    return StringRes.at('anyone');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color.fromARGB(200, 255, 49, 49)
            : const Color.fromARGB(200, 8, 157, 13),
      ),
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
        onAddGuestsTap: _showAddGuestPopup,
        onGuestListTap: _showGuestListPopup,
        onEditTap: _editEvent,
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
    required this.onAddGuestsTap,
    required this.onGuestListTap,
    required this.onEditTap,
  });

  final List<HomeEventCardData> events;
  final double s;
  final bool isLoading;
  final String emptyStateTitle;
  final String emptyStateIconPath;
  final ValueChanged<HomeEventCardData> onAddGuestsTap;
  final ValueChanged<HomeEventCardData> onGuestListTap;
  final ValueChanged<HomeEventCardData> onEditTap;

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
      itemBuilder: (context, index) {
        final HomeEventCardData event = events[index];
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 6 * s),
          child: VezEventCard(
            event: event,
            onAddGuestsTap: event.canInviteGuests
                ? () => onAddGuestsTap(event)
                : null,
            onGuestListTap: event.isByYou ? () => onGuestListTap(event) : null,
            onEditTap: event.isByYou ? () => onEditTap(event) : null,
          ),
        );
      },
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

class _PopupHeaderBar extends StatelessWidget {
  const _PopupHeaderBar({
    required this.title,
    required this.onClose,
    this.action,
  });

  final String title;
  final VoidCallback onClose;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
      child: Row(
        children: [
          const SizedBox(width: 36),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 36, child: action ?? const SizedBox.shrink()),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _PopupSearchField extends StatelessWidget {
  const _PopupSearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return VezGlass.textField(
      controller: controller,
      hint: hint,
      prefixIcon: const Icon(Icons.search, color: Colors.white),
      color: Colors.white,
      onChanged: onChanged,
    );
  }
}

class _PopupFilterChip extends StatelessWidget {
  const _PopupFilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isActive
              ? const Color.fromARGB(100, 255, 255, 255)
              : const Color.fromARGB(45, 255, 255, 255),
          border: Border.all(
            color: isActive ? Colors.white : Colors.white30,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PopupGuestRow extends StatelessWidget {
  const _PopupGuestRow({
    required this.username,
    required this.profilePhoto,
    required this.state,
    this.trailing,
  });

  final String username;
  final String profilePhoto;
  final String state;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color.fromARGB(45, 255, 255, 255),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: Row(
        children: [
          _PopupUserAvatar(photo: profilePhoto),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              username.isNotEmpty ? username : 'User',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...[
            trailing!,
            const SizedBox(width: 4),
          ],
          _PopupStateIcon(state: state),
        ],
      ),
    );
  }
}

class _PopupUserActionRow extends StatelessWidget {
  const _PopupUserActionRow({
    required this.username,
    required this.profilePhoto,
    required this.label,
    required this.icon,
    required this.iconColor,
    this.onTap,
  });

  final String username;
  final String profilePhoto;
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color.fromARGB(45, 255, 255, 255),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: Row(
        children: [
          _PopupUserAvatar(photo: profilePhoto),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  username.isNotEmpty ? username : 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onTap,
            icon: Icon(icon, color: iconColor),
          ),
        ],
      ),
    );
  }
}

class _PopupUserAvatar extends StatelessWidget {
  const _PopupUserAvatar({required this.photo});

  final String photo;

  @override
  Widget build(BuildContext context) {
    final bool isNetworkImage = photo.startsWith('http');

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white30, width: 1.5),
      ),
      child: ClipOval(
        child: photo.isEmpty
            ? const Icon(Icons.person, color: Colors.white70, size: 18)
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

class _PopupStateIcon extends StatelessWidget {
  const _PopupStateIcon({required this.state});

  final String state;

  @override
  Widget build(BuildContext context) {
    final String iconPath = switch (state) {
      'going' => 'assets/icons/event/participation_state/going.png',
      'not_going' => 'assets/icons/event/participation_state/not_going.png',
      _ => 'assets/icons/event/participation_state/maybe.png',
    };

    return ImageIcon(AssetImage(iconPath), color: Colors.white, size: 18);
  }
}

class _PopupCountsFooter extends StatelessWidget {
  const _PopupCountsFooter({required this.counts});

  final HomeEventGuestCounts counts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color.fromARGB(45, 255, 255, 255),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PopupCountItem(
              iconPath: 'assets/icons/event/participation_state/going.png',
              label: StringRes.at('going'),
              value: counts.going,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _PopupCountItem(
              iconPath:
              'assets/icons/event/participation_state/not_going.png',
              label: StringRes.at('not_going'),
              value: counts.notGoing,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _PopupCountItem(
              iconPath: 'assets/icons/event/participation_state/maybe.png',
              label: StringRes.at('maybe'),
              value: counts.maybe,
            ),
          ),
        ],
      ),
    );
  }
}

class _PopupCountItem extends StatelessWidget {
  const _PopupCountItem({
    required this.iconPath,
    required this.label,
    required this.value,
  });

  final String iconPath;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ImageIcon(AssetImage(iconPath), size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _PopupEmptyState extends StatelessWidget {
  const _PopupEmptyState({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color.fromARGB(30, 255, 255, 255),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color.fromARGB(140, 255, 195, 0),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}