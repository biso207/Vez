class EventCatalog {
  static const String defaultBackgroundImage =
      'assets/images/bg/default_create_event_bg.jpg';

  static const List<Map<String, String>> categories = [
    {'name': 'cinema', 'icon': 'assets/icons/categories/cinema.png'},
    {'name': 'concert', 'icon': 'assets/icons/categories/concert.png'},
    {'name': 'disco', 'icon': 'assets/icons/categories/disco.png'},
    {'name': 'gaming', 'icon': 'assets/icons/categories/gaming.png'},
    {'name': 'hang_out', 'icon': 'assets/icons/categories/hang_out.png'},
    {'name': 'journey', 'icon': 'assets/icons/categories/journey.png'},
    {'name': 'kids_and_family', 'icon': 'assets/icons/categories/kids_and_family.png',},
    {'name': 'museum', 'icon': 'assets/icons/categories/museum.png'},
    {'name': 'outdoor', 'icon': 'assets/icons/categories/outdoor.png'},
    {'name': 'party', 'icon': 'assets/icons/categories/party.png'},
    {'name': 'pub', 'icon': 'assets/icons/categories/pub.png'},
    {'name': 'restaurant', 'icon': 'assets/icons/categories/restaurant.png'},
    {'name': 'shopping', 'icon': 'assets/icons/categories/shopping.png'},
    {'name': 'sport', 'icon': 'assets/icons/categories/sport.png'},
    {'name': 'theatre', 'icon': 'assets/icons/categories/theatre.png'},
    {'name': 'wellness', 'icon': 'assets/icons/categories/wellness.png'},
    {'name': 'workshop', 'icon': 'assets/icons/categories/workshop.png'},
  ];

  static const List<Map<String, String>> eventTypes = [
    {'name': 'Exclusive', 'icon': 'assets/icons/event/exclusive.png'},
    {'name': 'Private', 'icon': 'assets/icons/event/private.png'},
    {'name': 'Public', 'icon': 'assets/icons/event/public.png'},
  ];

  static String normalizeTypeName(String? typeName) {
    final String normalized = (typeName ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'exclusive':
        return 'Exclusive';
      case 'private':
        return 'Private';
      case 'public':
        return 'Public';
      default:
        return 'Public';
    }
  }

  static bool canInviteGuests(String? typeName) {
    return normalizeTypeName(typeName) != 'Public';
  }

  static String categoryIconForName(String? categoryName) {
    final String normalized = (categoryName ?? '').trim().toLowerCase();
    for (final category in categories) {
      if (category['name'] == normalized) {
        return category['icon']!;
      }
    }
    return categories.first['icon']!;
  }

  static String typeIconForName(String? typeName) {
    final String normalized = normalizeTypeName(typeName);
    for (final eventType in eventTypes) {
      if (eventType['name'] == normalized) {
        return eventType['icon']!;
      }
    }
    return eventTypes.last['icon']!;
  }
}
