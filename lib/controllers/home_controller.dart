import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/event_catalog.dart';
import '../models/home_event.dart';
import '../services/getters_service.dart';
import '../services/setters_service.dart';
import '../services/translation_service.dart';

class HomeController extends ChangeNotifier {
  HomeController({required String userId})
    : _db = GetDBService(userID: userId),
      _dbSet = SetDBService(userID: userId);

  static const Duration _inviteMaybeTimeout = Duration(hours: 24);

  final GetDBService _db;
  final SetDBService _dbSet;
  bool _isDisposed = false;

  String profilePhoto = '';
  bool isLoadingEvents = true;
  List<Map<String, dynamic>> allUsers = const [];
  Set<String> followingIds = const {};
  Set<String> followerIds = const {};
  Map<EventType, List<HomeEventCardData>> eventsByType = {
    EventType.byYou: const [],
    EventType.invited: const [],
    EventType.nearby: const [],
  };

  Future<void> loadPageData() async {
    await _loadUserLanguage();
    await Future.wait([loadProfilePhoto(), loadEvents()]);
  }

  Future<void> loadProfilePhoto() async {
    final String? photo = await _db.getUserData('profile_photo');
    profilePhoto = photo?.trim() ?? '';
    _notify();
  }

  Future<void> _loadUserLanguage() async {
    final String? lan = await _db.getUserData('language');
    if (lan != null && lan.isNotEmpty) {
      StringRes.setLocale(lan);
    }
  }

  Future<void> loadEvents() async {
    isLoadingEvents = true;
    _notify();

    final List<Map<String, dynamic>> createdEvents = await _db
        .getCreatedEvents();
    final List<Map<String, dynamic>> invitedEvents = await _db
        .getInvitedEvents();

    eventsByType = {
      EventType.byYou: _mapEvents(createdEvents, EventType.byYou),
      EventType.invited: _mapEvents(invitedEvents, EventType.invited),
      EventType.nearby: const [],
    };
    isLoadingEvents = false;
    _notify();
  }

  Future<void> ensureUserDirectoryLoaded() async {
    if (allUsers.isNotEmpty) return;

    final results = await Future.wait([
      _db.getUsersBasic(),
      _db.getFollowing(),
      _db.getFollowers(),
    ]);

    allUsers = results[0];
    followingIds = results[1]
        .map((row) => (row['following_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();
    followerIds = results[2]
        .map((row) => (row['follower_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();
    _notify();
  }

  Future<HomeEventCardData?> refreshByYouEvent(String eventId) async {
    final Map<String, dynamic>? rawEvent = await _db.getEventById(eventId);
    if (rawEvent == null) return null;
    return _mapEvent(rawEvent, EventType.byYou);
  }

  void upsertByYouEvent(HomeEventCardData event) {
    final List<HomeEventCardData> updatedEvents = [
      ...(eventsByType[EventType.byYou] ?? const []),
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
    eventsByType = {...eventsByType, EventType.byYou: updatedEvents};
    _notify();
  }

  Future<int> addOrUpdateEventInvite({
    required String eventId,
    required String invitedUserId,
  }) {
    return _dbSet.addOrUpdateEventInvite(
      eventId: eventId,
      invitedUserId: invitedUserId,
    );
  }

  Future<int> removeEventInvite({
    required String eventId,
    required String invitedUserId,
  }) {
    return _dbSet.removeEventInvite(
      eventId: eventId,
      invitedUserId: invitedUserId,
    );
  }

  String relationLabel(String userId) {
    if (followingIds.contains(userId) && followerIds.contains(userId)) {
      return StringRes.at('friends');
    }
    if (followingIds.contains(userId)) {
      return StringRes.at('following');
    }
    return StringRes.at('anyone');
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  List<HomeEventCardData> _mapEvents(
    List<Map<String, dynamic>> rawEvents,
    EventType type,
  ) {
    return rawEvents.map((event) => _mapEvent(event, type)).toList();
  }

  HomeEventCardData _mapEvent(Map<String, dynamic> rawEvent, EventType type) {
    final Map<String, dynamic> place = rawEvent['place'] is Map<String, dynamic>
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

    final String visibility = EventCatalog.normalizeTypeName(
      rawEvent['type']?.toString(),
    );
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
        .map((row) => _mapParticipationGuest(Map<String, dynamic>.from(row)))
        .toList();
  }

  HomeEventGuestData _mapInviteGuest(Map<String, dynamic> row) {
    final Map<String, dynamic> user = row['users'] is Map<String, dynamic>
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
        referenceTimestamp: (row['responded_at'] ?? row['invited_at'])
            ?.toString(),
      ),
      role: (row['role'] ?? 'guest').toString(),
    );
  }

  HomeEventGuestData _mapParticipationGuest(Map<String, dynamic> row) {
    final Map<String, dynamic> user = row['users'] is Map<String, dynamic>
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

    return HomeEventGuestCounts(going: going, notGoing: notGoing, maybe: maybe);
  }

  String _normalizeInviteState(String? rawState, {String? referenceTimestamp}) {
    final String normalized = (rawState ?? '').trim().toLowerCase().replaceAll(
      ' ',
      '_',
    );

    if (normalized.isEmpty ||
        normalized == 'maybe' ||
        normalized == 'pending' ||
        normalized == 'invited') {
      return _isInviteExpired(referenceTimestamp) ? 'not_going' : 'maybe';
    }

    if (normalized == 'accepted' ||
        normalized == 'yes' ||
        normalized == 'going') {
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
    final String normalized = (rawState ?? '').trim().toLowerCase().replaceAll(
      ' ',
      '_',
    );

    if (normalized == 'going' ||
        normalized == 'accepted' ||
        normalized == 'yes') {
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
    return '$date - $placeName';
  }

  String _formatCardDate(String rawDate) {
    if (rawDate.isEmpty) return '';
    try {
      final DateTime parsed = DateTime.parse(rawDate).toLocal();
      return DateFormat('dd/MM/yyyy - HH:mm', StringRes.locale).format(parsed);
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
}
