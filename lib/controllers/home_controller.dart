// Developed and Designed by Outly • © 2026
// Logic controller for the home screen.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../models/event_catalog.dart';
import '../models/home_event.dart';
import '../services/getters_service.dart';
import '../services/setters_service.dart';
import '../services/translation_service.dart';

// ── home controller ──────────────────────────────────────────────────────────
//
//   used for: managing data fetching and state for the home screen.
//   design: extends ChangeNotifier to provide reactive updates to the UI.
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
  bool isLoadingNearby = false;
  String nearbyError = '';
  double nearbyRadiusKm = 25;
  Position? _currentPosition;
  List<Map<String, dynamic>> _discoverableEvents = const [];
  List<Map<String, dynamic>> allUsers = const [];
  Set<String> followingIds = const {};
  Set<String> followerIds = const {};
  Map<EventType, List<HomeEventCardData>> eventsByType = {
    EventType.byYou: const [],
    EventType.cohost: const [],
    EventType.invited: const [],
    EventType.nearby: const [],
  };

  // ── load page data ─────────────────────────────────────────────────────────
  //
  //   used for: loading initial data required for the home screen.
  Future<void> loadPageData() async {
    await _loadUserLanguage();
    await Future.wait([loadProfilePhoto(), loadEvents()]);
  }

  // ── load profile photo ─────────────────────────────────────────────────────
  //
  //   used for: fetching and setting the user's profile photo.
  Future<void> loadProfilePhoto() async {
    final String? photo = await _db.getUserData('profile_photo');
    profilePhoto = photo?.trim() ?? '';
    _notify();
  }

  // ── load user language ─────────────────────────────────────────────────────
  //
  //   used for: fetching and setting the app's locale from user settings.
  Future<void> _loadUserLanguage() async {
    final String? lan = await _db.getUserData('language');
    if (lan != null && lan.isNotEmpty) {
      StringRes.setLocale(lan);
    }
  }

  // ── load events ────────────────────────────────────────────────────────────
  //
  //   used for: fetching all event types (Created, Invited, Discoverable).
  Future<void> loadEvents() async {
    isLoadingEvents = true;
    _notify();

    final List<Map<String, dynamic>> createdEvents = await _db.getCreatedEvents();
    final List<Map<String, dynamic>> cohostEvents = await _db.getCohostEvents();
    final List<Map<String, dynamic>> invitedEvents = await _db.getInvitedEvents();
    _discoverableEvents = await _db.getDiscoverableEvents();

    // mapping the events
    final List<HomeEventCardData> byYou = _mapEvents(createdEvents, EventType.byYou);
    final List<HomeEventCardData> invited = _mapEvents(invitedEvents, EventType.invited);

    final List<HomeEventCardData> cohostsAsInvites = _mapEvents(cohostEvents, EventType.invited);

    // CoHost and standard Guest invites all together
    final List<HomeEventCardData> combinedInvited = [...invited, ...cohostsAsInvites]
      ..sort((a, b) => a.rawDateEvent.compareTo(b.rawDateEvent));

    eventsByType = {
      // in "By You" only events in which the user is the host
      EventType.byYou: byYou.where((e) => e.creatorUserId == _db.userID).toList(),
      EventType.cohost: const [], // empty to save the enum
      EventType.invited: combinedInvited,
      EventType.nearby: _buildNearbyEvents(),
    };

    isLoadingEvents = false;
    _notify();
  }

  // ── load nearby events ─────────────────────────────────────────────────────
  //
  //   used for: fetching events based on the user's geographic location.
  Future<void> loadNearbyEvents({bool refreshPosition = false}) async {
    isLoadingNearby = true;
    nearbyError = '';
    _notify();

    try {
      if (refreshPosition || _currentPosition == null) {
        _currentPosition = await _getCurrentPosition();
      }
      if (_discoverableEvents.isEmpty) {
        _discoverableEvents = await _db.getDiscoverableEvents();
      }
      eventsByType = {...eventsByType, EventType.nearby: _buildNearbyEvents()};
    } catch (e) {
      nearbyError = e.toString().replaceAll('Exception: ', '');
      eventsByType = {...eventsByType, EventType.nearby: const []};
    } finally {
      isLoadingNearby = false;
      _notify();
    }
  }

  // ── update nearby radius ───────────────────────────────────────────────────
  //
  //   used for: changing the search radius for discoverable events.
  void updateNearbyRadius(double radiusKm) {
    nearbyRadiusKm = radiusKm.clamp(1, 100).toDouble();
    eventsByType = {...eventsByType, EventType.nearby: _buildNearbyEvents()};
    _notify();
  }

  // ── ensure user directory loaded ───────────────────────────────────────────
  //
  //   used for: pre-loading user information and social connections.
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

  // ── refresh by you event ───────────────────────────────────────────────────
  //
  //   used for: fetching the latest data for a specific event created by the user.
  Future<HomeEventCardData?> refreshByYouEvent(String eventId) async {
    final Map<String, dynamic>? rawEvent = await _db.getEventById(eventId);
    if (rawEvent == null) return null;
    return _mapEvent(rawEvent, EventType.byYou);
  }

  Future<HomeEventCardData?> refreshEventForType(
    String eventId,
    EventType type,
  ) async {
    final Map<String, dynamic>? rawEvent = await _db.getEventById(eventId);
    if (rawEvent == null) return null;
    return _mapEvent(rawEvent, type);
  }

  // ── upsert by you event ────────────────────────────────────────────────────
  //
  //   used for: updating or inserting an event in the local list.
  void upsertByYouEvent(HomeEventCardData event) {
    upsertEvent(event);
  }

  void upsertEvent(HomeEventCardData event) {
    final List<HomeEventCardData> updatedEvents = [
      ...(eventsByType[event.type] ?? const []),
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
    eventsByType = {...eventsByType, event.type: updatedEvents};
    _notify();
  }

  // ── add or update event invite ─────────────────────────────────────────────
  //
  //   used for: sending or modifying invitations for a specific event.
  Future<int> addOrUpdateEventInvite({
    required String eventId,
    required String invitedUserId,
    String role = 'guest',
  }) {
    return _dbSet.addOrUpdateEventInvite(
      eventId: eventId,
      invitedUserId: invitedUserId,
      role: role,
    );
  }

  Future<int> updateEventInviteRole({
    required String eventId,
    required String invitedUserId,
    required String role,
  }) {
    return _dbSet.updateEventInviteRole(
      eventId: eventId,
      invitedUserId: invitedUserId,
      role: role,
    );
  }

  // ── remove event invite ────────────────────────────────────────────────────
  //
  //   used for: canceling or removing an invitation from an event.
  Future<int> removeEventInvite({
    required String eventId,
    required String invitedUserId,
  }) {
    return _dbSet.removeEventInvite(
      eventId: eventId,
      invitedUserId: invitedUserId,
    );
  }

  // update current user's visible response for invited or nearby cards
  Future<int> updateEventResponse({
    required HomeEventCardData event,
    required String responseState,
  }) async {
    final int result = event.type == EventType.invited
        ? await _dbSet.updateEventInviteResponse(
            eventId: event.eventId,
            responseState: responseState,
          )
        : await _dbSet.upsertEventParticipation(
            eventId: event.eventId,
            participationState: responseState,
          );

    if (result == 200 || result == 204) {
      final HomeEventCardData? refreshed = await _refreshEventForType(event);
      if (refreshed != null) {
        _replaceEvent(refreshed);
      }
    }

    return result;
  }

  // ── relation label ─────────────────────────────────────────────────────────
  //
  //   used for: determining the social relationship label for a given user.
  String relationLabel(String userId) {
    if (followingIds.contains(userId) && followerIds.contains(userId)) {
      return StringRes.at('friends');
    }
    if (followingIds.contains(userId)) {
      return StringRes.at('following');
    }
    return StringRes.at('anyone');
  }

  // ── dispose ────────────────────────────────────────────────────────────────
  //
  //   used for: cleaning up controller resources.
  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // ── notify ─────────────────────────────────────────────────────────────────
  //
  //   used for: triggering UI updates if the controller is still active.
  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  // refresh a single card after a status change
  Future<HomeEventCardData?> _refreshEventForType(
    HomeEventCardData event,
  ) async {
    final Map<String, dynamic>? rawEvent = await _db.getEventById(
      event.eventId,
    );
    if (rawEvent == null) return null;
    return _mapEvent(rawEvent, event.type, distanceKm: event.distanceKm);
  }

  // replace the changed card without rebuilding unrelated lists
  void _replaceEvent(HomeEventCardData event) {
    final List<HomeEventCardData> updatedEvents = [
      ...(eventsByType[event.type] ?? const []),
    ];
    final int index = updatedEvents.indexWhere(
      (item) => item.eventId == event.eventId,
    );

    if (index < 0) return;

    updatedEvents[index] = event;
    eventsByType = {...eventsByType, event.type: updatedEvents};
    _notify();
  }

  // ── map events ─────────────────────────────────────────────────────────────
  //
  //   used for: converting a list of raw database maps into HomeEventCardData objects.
  List<HomeEventCardData> _mapEvents(
    List<Map<String, dynamic>> rawEvents,
    EventType type,
  ) {
    return rawEvents.map((event) => _mapEvent(event, type)).toList();
  }

  // ── map event ──────────────────────────────────────────────────────────────
  //
  //   used for: converting a single database map into a HomeEventCardData object.
  HomeEventCardData _mapEvent(
    Map<String, dynamic> rawEvent,
    EventType type, {
    double? distanceKm,
  }) {
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
      locationPrecise: _asBool(place['is_precise']),
      latitude: _asDouble(place['latitude']),
      longitude: _asDouble(place['longitude']),
      maxGuests: (rawEvent['max_participants'] as num?)?.toInt(),
      price: (rawEvent['price'] as num?)?.toInt(),
      guestCounts: guestCounts,
      guests: guests,
      distanceKm: distanceKm,
      currentUserRole: _currentUserRole(guests),
    );
  }

  HomeEventRole _currentUserRole(List<HomeEventGuestData> guests) {
    for (final guest in guests) {
      if (guest.userId == _db.userID) return guest.eventRole;
    }
    return HomeEventRole.guest;
  }

  // ── build nearby events ────────────────────────────────────────────────────
  //
  //   used for: filtering discoverable events based on location and radius.
  List<HomeEventCardData> _buildNearbyEvents() {
    final Position? position = _currentPosition;
    if (position == null) return const [];

    final List<HomeEventCardData> nearbyEvents = [];
    for (final rawEvent in _discoverableEvents) {
      if (!_isPublicEvent(rawEvent)) continue;
      if ((rawEvent['creator_user_id'] ?? '').toString() == _db.userID) {
        continue;
      }

      final Map<String, dynamic> place = rawEvent['place'] is Map
          ? Map<String, dynamic>.from(rawEvent['place'] as Map)
          : <String, dynamic>{};
      final latitude = _asDouble(place['latitude']);
      final longitude = _asDouble(place['longitude']);
      final bool isPrecise = _asBool(place['is_precise']);

      if (!isPrecise || latitude == null || longitude == null) continue;
      if (latitude == 0.0 && longitude == 0.0) continue;

      final distanceKm = _distanceKm(
        position.latitude,
        position.longitude,
        latitude,
        longitude,
      );
      if (distanceKm > nearbyRadiusKm) continue;

      nearbyEvents.add(
        _mapEvent(rawEvent, EventType.nearby, distanceKm: distanceKm),
      );
    }

    nearbyEvents.sort(
      (a, b) => (a.distanceKm ?? double.infinity).compareTo(
        b.distanceKm ?? double.infinity,
      ),
    );
    return nearbyEvents;
  }

  // ── get current position ───────────────────────────────────────────────────
  //
  //   used for: requesting and obtaining the device's GPS coordinates.
  Future<Position> _getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception(StringRes.at('enable_location_services'));
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception(StringRes.at('location_permissions_denied'));
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(StringRes.at('location_permissions_permanently_denied'));
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  // ── distance km ────────────────────────────────────────────────────────────
  //
  //   used for: calculating the spherical distance between two sets of coordinates.
  double _distanceKm(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(endLat - startLat);
    final dLng = _degreesToRadians(endLng - startLng);
    final lat1 = _degreesToRadians(startLat);
    final lat2 = _degreesToRadians(endLat);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLng / 2) *
            math.sin(dLng / 2) *
            math.cos(lat1) *
            math.cos(lat2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  // ── degrees to radians ─────────────────────────────────────────────────────
  //
  //   used for: converting angle degrees to radians for trigonometric calculations.
  double _degreesToRadians(double degrees) => degrees * math.pi / 180;

  bool _isPublicEvent(Map<String, dynamic> rawEvent) {
    return EventCatalog.normalizeTypeName(rawEvent['type']?.toString()) ==
        'Public';
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  // ── map guests ─────────────────────────────────────────────────────────────
  //
  //   used for: determining whether to process invites or participation rows.
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

  // ── map invite guest ───────────────────────────────────────────────────────
  //
  //   used for: converting a raw invite database map into HomeEventGuestData.
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

  // ── map participation guest ────────────────────────────────────────────────
  //
  //   used for: converting a raw participation database map into HomeEventGuestData.
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

  // ── count guests ───────────────────────────────────────────────────────────
  //
  //   used for: calculating RSVP totals from a list of guests.
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

  // ── normalize invite state ─────────────────────────────────────────────────
  //
  //   used for: converting raw invite strings into standard state values.
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

  // ── normalize participation state ──────────────────────────────────────────
  //
  //   used for: converting raw participation strings into standard state values.
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

  // ── is invite expired ──────────────────────────────────────────────────────
  //
  //   used for: determining if a pending invitation has timed out.
  bool _isInviteExpired(String? rawTimestamp) {
    if (rawTimestamp == null || rawTimestamp.isEmpty) return false;

    final DateTime? timestamp = DateTime.tryParse(rawTimestamp);
    if (timestamp == null) return false;

    return DateTime.now().toUtc().difference(timestamp.toUtc()) >
        _inviteMaybeTimeout;
  }

  // ── build subtitle ─────────────────────────────────────────────────────────
  //
  //   used for: concatenating formatted date and place name for the UI.
  String _buildSubtitle(String rawDate, String placeName) {
    final String date = _formatEventDate(rawDate);
    if (date.isEmpty) return placeName;
    if (placeName.isEmpty) return date;
    return '$date - $placeName';
  }

  // ── format card date ───────────────────────────────────────────────────────
  //
  //   used for: formatting the event date for display on a card.
  String _formatCardDate(String rawDate) {
    if (rawDate.isEmpty) return '';
    try {
      final DateTime parsed = DateTime.parse(rawDate).toLocal();
      return DateFormat('dd/MM/yyyy - HH:mm', StringRes.locale).format(parsed);
    } catch (_) {
      return '';
    }
  }

  // ── format event date ──────────────────────────────────────────────────────
  //
  //   used for: formatting the event date for subtitle display.
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
