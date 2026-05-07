// Developed and Designed by Outly • © 2026
// data models for events shown on the home screen.

import 'event_catalog.dart';

// ── event type ───────────────────────────────────────────────────────────────
//
//   used for: categorizing events into feed tabs.
enum EventType { byYou, cohost, invited, nearby }

class HomeEventRole {
  const HomeEventRole({
    required this.raw,
    required this.isCohost,
    required this.canInvite,
    required this.canRemove,
    required this.canViewGuests,
  });

  final String raw;
  final bool isCohost;
  final bool canInvite;
  final bool canRemove;
  final bool canViewGuests;

  static const HomeEventRole guest = HomeEventRole(
    raw: 'guest',
    isCohost: false,
    canInvite: false,
    canRemove: false,
    canViewGuests: true,
  );

  static const HomeEventRole fullCohost = HomeEventRole(
    raw: 'cohost:i,r,v',
    isCohost: true,
    canInvite: true,
    canRemove: true,
    canViewGuests: true,
  );

  factory HomeEventRole.fromRaw(String? rawRole) {
    final String raw = (rawRole ?? '').trim().toLowerCase();
    if (!raw.startsWith('cohost')) return guest;

    final Set<String> permissions = raw.contains(':')
        ? raw
              .split(':')
              .skip(1)
              .join(':')
              .split(',')
              .map((item) => item.trim())
              .map(_normalizePermission)
              .where((item) => item.isNotEmpty)
              .toSet()
        : {'invite', 'remove', 'view'};

    return HomeEventRole(
      raw: raw,
      isCohost: true,
      canInvite: permissions.contains('invite'),
      canRemove: permissions.contains('remove'),
      canViewGuests: permissions.contains('view'),
    );
  }

  String encode() {
    if (!isCohost) return 'guest';
    final permissions = <String>[
      if (canInvite) 'i',
      if (canRemove) 'r',
      if (canViewGuests) 'v',
    ];
    return permissions.isEmpty ? 'cohost:' : 'cohost:${permissions.join(',')}';
  }

  static String _normalizePermission(String permission) {
    switch (permission) {
      case 'i':
      case 'invite':
        return 'invite';
      case 'r':
      case 'remove':
        return 'remove';
      case 'v':
      case 'view':
        return 'view';
      default:
        return permission;
    }
  }

  HomeEventRole copyWith({
    bool? canInvite,
    bool? canRemove,
    bool? canViewGuests,
  }) {
    return HomeEventRole(
      raw: raw,
      isCohost: isCohost,
      canInvite: canInvite ?? this.canInvite,
      canRemove: canRemove ?? this.canRemove,
      canViewGuests: canViewGuests ?? this.canViewGuests,
    );
  }
}

// ── home event guest counts ──────────────────────────────────────────────────
//
//   used for: storing aggregated RSVP totals for an event.
class HomeEventGuestCounts {
  const HomeEventGuestCounts({
    this.going = 0,
    this.notGoing = 0,
    this.maybe = 0,
  });

  final int going;
  final int notGoing;
  final int maybe;
}

// ── home event guest data ────────────────────────────────────────────────────
//
//   used for: representing a single user invited to or participating in an event.
class HomeEventGuestData {
  const HomeEventGuestData({
    required this.userId,
    required this.username,
    required this.profilePhoto,
    required this.state,
    this.role = 'guest',
  });

  final String userId;
  final String username;
  final String profilePhoto;
  final String state;
  final String role;

  HomeEventRole get eventRole => HomeEventRole.fromRaw(role);
  bool get isCohost => eventRole.isCohost;
}

// ── home event card data ─────────────────────────────────────────────────────
//
//   used for: providing all necessary data to render an event card.
class HomeEventCardData {
  const HomeEventCardData({
    required this.eventId,
    required this.imagePath,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.typeLabel,
    required this.categoryName,
    required this.categoryIconPath,
    required this.typeIconPath,
    required this.dateLabel,
    required this.locationLabel,
    required this.rawDateEvent,
    required this.creatorUserId,
    required this.creatorUsername,
    required this.creatorProfilePhoto,
    this.description = '',
    this.placeId = '',
    this.placeAddress = '',
    this.locationPrecise = false,
    this.latitude,
    this.longitude,
    this.maxGuests,
    this.price,
    this.guestCounts = const HomeEventGuestCounts(),
    this.guests = const [],
    this.distanceKm,
    this.currentUserRole = HomeEventRole.guest,
  });

  final String eventId;
  final String imagePath;
  final EventType type;
  final String title;
  final String subtitle;
  final String typeLabel;
  final String categoryName;
  final String categoryIconPath;
  final String typeIconPath;
  final String dateLabel;
  final String locationLabel;
  final String rawDateEvent;
  final String creatorUserId;
  final String creatorUsername;
  final String creatorProfilePhoto;
  final String description;
  final String placeId;
  final String placeAddress;
  final bool locationPrecise;
  final double? latitude;
  final double? longitude;
  final int? maxGuests;
  final int? price;
  final HomeEventGuestCounts guestCounts;
  final List<HomeEventGuestData> guests;
  final double? distanceKm;
  final HomeEventRole currentUserRole;

  // ── is by you ──────────────────────────────────────────────────────────────
  //
  //   used for: checking if the event was created by the current user.
  bool get isByYou => type == EventType.byYou;
  bool get isCohostView => type == EventType.cohost;

  // ── can invite guests ──────────────────────────────────────────────────────
  //
  //   used for: checking if the event type allows manual guest invitations.
  bool get canInviteGuests {
    if (isByYou) return EventCatalog.canInviteGuests(typeLabel);
    return isCohostView &&
        currentUserRole.isCohost &&
        currentUserRole.canInvite;
  }

  bool get canRemoveGuests {
    if (isByYou) return EventCatalog.canInviteGuests(typeLabel);
    return isCohostView &&
        currentUserRole.isCohost &&
        currentUserRole.canRemove;
  }

  bool get canViewGuests {
    if (isByYou) return true;
    if (isCohostView) return currentUserRole.canViewGuests;
    return true;
  }

  bool get canManageCohosts {
    return isByYou && EventCatalog.normalizeTypeName(typeLabel) == 'Exclusive';
  }

  bool get canEditEvent => isByYou;

  List<HomeEventGuestData> get cohosts =>
      guests.where((guest) => guest.isCohost).toList();

  // ── resolved image path ────────────────────────────────────────────────────
  //
  //   used for: returning the custom image path or a default fallback.
  String get resolvedImagePath {
    final String trimmed = imagePath.trim();
    return trimmed.isEmpty ? EventCatalog.defaultBackgroundImage : trimmed;
  }
}
