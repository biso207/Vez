import '../../models/event_catalog.dart';

class ProfileEventHelpers {
  const ProfileEventHelpers._();

  static List<Map<String, dynamic>> mergePastEvents(
    List<Map<String, dynamic>> createdEvents,
    List<Map<String, dynamic>> participatedEvents,
  ) {
    final Map<String, Map<String, dynamic>> eventsById = {};

    for (final event in [...createdEvents, ...participatedEvents]) {
      final String id = (event['event_id'] ?? '').toString();
      if (id.isEmpty) {
        eventsById['fallback_${eventsById.length}'] = event;
      } else {
        eventsById[id] = event;
      }
    }

    final List<Map<String, dynamic>> events = eventsById.values.toList();
    events.sort((a, b) {
      final DateTime? aDate = DateTime.tryParse(
        (a['date_event'] ?? '').toString(),
      );
      final DateTime? bDate = DateTime.tryParse(
        (b['date_event'] ?? '').toString(),
      );
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });

    return events;
  }

  static String eventCategoryName(Map<String, dynamic> event) {
    final dynamic category = event['event_category'];
    if (category is Map) {
      return (category['name'] ?? '').toString().trim();
    }
    return '';
  }

  static String mostParticipatedCategoryIcon(
    List<Map<String, dynamic>> events,
  ) {
    final Map<String, int> categoryCounts = {};

    for (final event in events) {
      final String categoryName = eventCategoryName(event);
      if (categoryName.isEmpty) continue;
      categoryCounts[categoryName] = (categoryCounts[categoryName] ?? 0) + 1;
    }

    if (categoryCounts.isEmpty) {
      return EventCatalog.categoryIconForName(null);
    }

    String topCategory = categoryCounts.keys.first;
    int topCount = categoryCounts[topCategory] ?? 0;

    for (final entry in categoryCounts.entries.skip(1)) {
      if (entry.value > topCount) {
        topCategory = entry.key;
        topCount = entry.value;
      }
    }

    return EventCatalog.categoryIconForName(topCategory);
  }
}
