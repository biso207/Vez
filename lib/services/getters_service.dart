import 'dart:convert';

import 'package:http/http.dart'
    as http; // http packet (standard in Dart/Flutter).

import 'api_keys.dart'; // private key to connect to the remote db

class GetDBService {
  static const String _eventSelect =
      'event_id,title,description,date_event,max_participants,type,'
      'creator_user_id,bg_photo,category_id,price,place_id,'
      'place:place_id(name,address,is_precise,latitude,longitude),'
      'event_category(name),'
      'creator:creator_user_id(username,profile_photo),'
      'participation(participation_id,user_id,participation_state,'
      'participation_date,users(username,profile_photo))';

  final String _apiKey = ApiKeys.remoteDbKey;
  final String _baseUrl = ApiKeys.baseUrl;
  final String userID;

  GetDBService({required this.userID});

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_apiKey',
    'apikey': _apiKey,
  };

  String get _nowFilter =>
      Uri.encodeComponent(DateTime.now().toUtc().toIso8601String());

  /// generic method to get any user attribute
  Future<String?> getUserData(String column) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/rest/v1/users?user_id=eq.$userID&select=$column',
      );

      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final dynamic value = data[0][column];
          return value?.toString();
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// counts followers for a specific user ID
  Future<int> getFollowersCount() async {
    try {
      final url = Uri.parse(
        '$_baseUrl/rest/v1/follows?following_id=eq.$userID&select=count',
      );
      final response = await http.get(
        url,
        headers: {..._headers, 'Prefer': 'count=exact'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return data[0]['count'] ?? 0;
        }
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// gets the list of users that a specific user ID is following
  Future<List<Map<String, dynamic>>> getFollowing() async {
    try {
      final url = Uri.parse(
        '$_baseUrl/rest/v1/follows?follower_id=eq.$userID&select=*',
      );
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// gets the list of users that are following the current user
  Future<List<Map<String, dynamic>>> getFollowers() async {
    try {
      final url = Uri.parse(
        '$_baseUrl/rest/v1/follows?following_id=eq.$userID&select=*',
      );
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUsersBasic() async {
    try {
      final url = Uri.parse(
        '$_baseUrl/rest/v1/users'
        '?user_id=neq.$userID'
        '&select=user_id,username,profile_photo'
        '&order=username.asc',
      );
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCreatedEvents() async {
    try {
      final url = Uri.parse(
        '$_baseUrl/rest/v1/events'
        '?creator_user_id=eq.$userID'
        '&date_event=gte.$_nowFilter'
        '&select=$_eventSelect'
        '&order=date_event.asc',
      );

      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return _attachEventInvites(
          data
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(),
        );
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getEventById(String eventId) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/rest/v1/events'
        '?event_id=eq.$eventId'
        '&select=$_eventSelect'
        '&limit=1',
      );

      final response = await http.get(url, headers: _headers);
      if (response.statusCode != 200) return null;

      final List<dynamic> data = jsonDecode(response.body);
      if (data.isEmpty) return null;

      final List<Map<String, dynamic>> enriched = await _attachEventInvites([
        Map<String, dynamic>.from(data.first as Map),
      ]);
      return enriched.first;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getInvitedEvents() async {
    try {
      final Uri inviteUrl = Uri.parse(
        '$_baseUrl/rest/v1/event_invites?user_id=eq.$userID&select=event_id,role',
      );

      final inviteResponse = await http.get(inviteUrl, headers: _headers);

      if (inviteResponse.statusCode != 200) return [];

      final List<dynamic> inviteRows = jsonDecode(inviteResponse.body);
      final List<String> eventIds = inviteRows
          .whereType<Map>()
          .where((row) => !_isCohostRole(row['role']?.toString()))
          .map((row) => row['event_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      if (eventIds.isEmpty) return [];

      final String encodedIds = eventIds.join(',');
      final Uri eventsUrl = Uri.parse(
        '$_baseUrl/rest/v1/events'
        '?event_id=in.($encodedIds)'
        '&date_event=gte.$_nowFilter'
        '&select=$_eventSelect'
        '&order=date_event.asc',
      );

      final eventsResponse = await http.get(eventsUrl, headers: _headers);

      if (eventsResponse.statusCode == 200) {
        final List<dynamic> data = jsonDecode(eventsResponse.body);
        return _attachEventInvites(
          data
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(),
        );
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCohostEvents() async {
    try {
      final Uri inviteUrl = Uri.parse(
        '$_baseUrl/rest/v1/event_invites?user_id=eq.$userID&select=event_id,role',
      );

      final inviteResponse = await http.get(inviteUrl, headers: _headers);

      if (inviteResponse.statusCode != 200) return [];

      final List<dynamic> inviteRows = jsonDecode(inviteResponse.body);
      final List<String> eventIds = inviteRows
          .whereType<Map>()
          .where((row) => _isCohostRole(row['role']?.toString()))
          .map((row) => row['event_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      if (eventIds.isEmpty) return [];

      final String encodedIds = eventIds.join(',');
      final Uri eventsUrl = Uri.parse(
        '$_baseUrl/rest/v1/events'
        '?event_id=in.($encodedIds)'
        '&date_event=gte.$_nowFilter'
        '&select=$_eventSelect'
        '&order=date_event.asc',
      );

      final eventsResponse = await http.get(eventsUrl, headers: _headers);

      if (eventsResponse.statusCode == 200) {
        final List<dynamic> data = jsonDecode(eventsResponse.body);
        return _attachEventInvites(
          data
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(),
        );
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getDiscoverableEvents() async {
    try {
      final url = Uri.parse(
        '$_baseUrl/rest/v1/events'
        '?type=eq.Public'
        '&date_event=gte.$_nowFilter'
        '&select=$_eventSelect'
        '&order=date_event.asc',
      );

      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return _attachEventInvites(
          data
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(),
        );
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getInviteNotifications() async {
    try {
      final Uri url = Uri.parse(
        '$_baseUrl/rest/v1/event_invites'
        '?user_id=eq.$userID'
        '&select=invite_id,response,invited_at,responded_at,role,event_id,'
        'event:event_id('
        'event_id,title,date_event,type,bg_photo,creator_user_id,'
        'place:place_id(name,address,is_precise,latitude,longitude),'
        'creator:creator_user_id(username,profile_photo)'
        ')'
        '&order=invited_at.desc',
      );

      final response = await http.get(url, headers: _headers);
      if (response.statusCode != 200) return [];

      final List<dynamic> data = jsonDecode(response.body);
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getExpiredCreatedEvents() async {
    try {
      final url = Uri.parse(
        '$_baseUrl/rest/v1/events'
        '?creator_user_id=eq.$userID'
        '&date_event=lt.$_nowFilter'
        '&select=$_eventSelect'
        '&order=date_event.desc',
      );
      final response = await http.get(url, headers: _headers);
      if (response.statusCode != 200) return [];
      final List<dynamic> data = jsonDecode(response.body);
      return _attachEventInvites(
        data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(),
      );
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getExpiredParticipatedEvents() async {
    try {
      final ids = <String>{};
      final participationUrl = Uri.parse(
        '$_baseUrl/rest/v1/participation'
        '?user_id=eq.$userID'
        '&participation_state=eq.going'
        '&select=event_id',
      );
      final participationResponse = await http.get(
        participationUrl,
        headers: _headers,
      );
      if (participationResponse.statusCode == 200) {
        for (final row
            in (jsonDecode(participationResponse.body) as List)
                .whereType<Map>()) {
          final id = row['event_id']?.toString() ?? '';
          if (id.isNotEmpty) ids.add(id);
        }
      }

      final inviteUrl = Uri.parse(
        '$_baseUrl/rest/v1/event_invites'
        '?user_id=eq.$userID'
        '&response=in.(going,accepted,yes)'
        '&select=event_id',
      );
      final inviteResponse = await http.get(inviteUrl, headers: _headers);
      if (inviteResponse.statusCode == 200) {
        for (final row
            in (jsonDecode(inviteResponse.body) as List).whereType<Map>()) {
          final id = row['event_id']?.toString() ?? '';
          if (id.isNotEmpty) ids.add(id);
        }
      }

      if (ids.isEmpty) return [];
      final encodedIds = ids.map(Uri.encodeComponent).join(',');
      final eventsUrl = Uri.parse(
        '$_baseUrl/rest/v1/events'
        '?event_id=in.($encodedIds)'
        '&creator_user_id=neq.$userID'
        '&date_event=lt.$_nowFilter'
        '&select=$_eventSelect'
        '&order=date_event.desc',
      );
      final eventsResponse = await http.get(eventsUrl, headers: _headers);
      if (eventsResponse.statusCode != 200) return [];
      final List<dynamic> data = jsonDecode(eventsResponse.body);
      return _attachEventInvites(
        data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(),
      );
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _attachEventInvites(
    List<Map<String, dynamic>> events,
  ) async {
    final Set<String> eventIds = events
        .map((event) => (event['event_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();

    if (eventIds.isEmpty) return events;

    try {
      final String encodedIds = eventIds.map(Uri.encodeComponent).join(',');
      final url = Uri.parse(
        '$_baseUrl/rest/v1/event_invites'
        '?event_id=in.($encodedIds)'
        '&select=invite_id,event_id,user_id,role,response,invited_at,responded_at',
      );
      final response = await http.get(url, headers: _headers);
      if (response.statusCode != 200) return events;

      final List<dynamic> data = jsonDecode(response.body);
      final Map<String, List<Map<String, dynamic>>> invitesByEventId = {};
      for (final row in data.whereType<Map>()) {
        final Map<String, dynamic> invite = Map<String, dynamic>.from(row);
        final String eventId = (invite['event_id'] ?? '').toString();
        if (eventId.isEmpty) continue;
        invitesByEventId.putIfAbsent(eventId, () => []).add(invite);
      }

      for (final event in events) {
        final String eventId = (event['event_id'] ?? '').toString();
        event['event_invites'] = invitesByEventId[eventId] ?? [];
      }
    } catch (_) {}

    return _attachInviteUsers(events);
  }

  Future<List<Map<String, dynamic>>> _attachInviteUsers(
    List<Map<String, dynamic>> events,
  ) async {
    final Set<String> userIds = {};
    for (final event in events) {
      final List<dynamic> inviteRows =
          event['event_invites'] as List<dynamic>? ?? const [];
      for (final row in inviteRows.whereType<Map>()) {
        final String userId = (row['user_id'] ?? '').toString();
        if (userId.isNotEmpty) userIds.add(userId);
      }
    }

    if (userIds.isEmpty) return events;

    try {
      final String encodedIds = userIds.map(Uri.encodeComponent).join(',');
      final url = Uri.parse(
        '$_baseUrl/rest/v1/users'
        '?user_id=in.($encodedIds)'
        '&select=user_id,username,profile_photo',
      );
      final response = await http.get(url, headers: _headers);
      if (response.statusCode != 200) return events;

      final List<dynamic> data = jsonDecode(response.body);
      final Map<String, Map<String, dynamic>> usersById = {
        for (final row in data.whereType<Map>())
          (row['user_id'] ?? '').toString(): Map<String, dynamic>.from(row),
      };

      for (final event in events) {
        final List<dynamic> inviteRows =
            event['event_invites'] as List<dynamic>? ?? const [];
        event['event_invites'] = inviteRows.whereType<Map>().map((row) {
          final Map<String, dynamic> invite = Map<String, dynamic>.from(row);
          invite['users'] = usersById[(invite['user_id'] ?? '').toString()];
          return invite;
        }).toList();
      }
    } catch (_) {}

    return events;
  }

  bool _isCohostRole(String? role) {
    return (role ?? '').trim().toLowerCase().startsWith('cohost');
  }
}
