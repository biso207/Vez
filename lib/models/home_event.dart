// Developed and Designed by Outly • © 2026
// data models for events shown on the home screen.

import 'event_catalog.dart';

// ── event type ───────────────────────────────────────────────────────────────
//
//   used for: categorizing events into feed tabs.
enum EventType { byYou, invited, nearby }

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

  // ── is by you ──────────────────────────────────────────────────────────────
  //
  //   used for: checking if the event was created by the current user.
  bool get isByYou => type == EventType.byYou;

  // ── can invite guests ──────────────────────────────────────────────────────
  //
  //   used for: checking if the event type allows manual guest invitations.
  bool get canInviteGuests {
    return isByYou && EventCatalog.canInviteGuests(typeLabel);
  }

  // ── resolved image path ────────────────────────────────────────────────────
  //
  //   used for: returning the custom image path or a default fallback.
  String get resolvedImagePath {
    final String trimmed = imagePath.trim();
    return trimmed.isEmpty ? EventCatalog.defaultBackgroundImage : trimmed;
  }
}
