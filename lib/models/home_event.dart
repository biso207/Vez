import 'event_catalog.dart';

enum EventType { byYou, invited, nearby }

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

  bool get isByYou => type == EventType.byYou;

  bool get canInviteGuests {
    return isByYou && EventCatalog.canInviteGuests(typeLabel);
  }

  String get resolvedImagePath {
    final String trimmed = imagePath.trim();
    return trimmed.isEmpty ? EventCatalog.defaultBackgroundImage : trimmed;
  }
}
