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
      'event_invites(id_invite,user_id,role,response,invited_at,responded_at,'
      'users(username,profile_photo)),'
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
        '&select=$_eventSelect'
        '&order=date_event.asc',
      );

      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
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

      return Map<String, dynamic>.from(data.first as Map);
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getInvitedEvents() async {
    try {
      final Uri inviteUrl = Uri.parse(
        '$_baseUrl/rest/v1/event_invites?user_id=eq.$userID&select=event_id',
      );

      final inviteResponse = await http.get(inviteUrl, headers: _headers);

      if (inviteResponse.statusCode != 200) return [];

      final List<dynamic> inviteRows = jsonDecode(inviteResponse.body);
      final List<String> eventIds = inviteRows
          .map((row) => row['event_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      if (eventIds.isEmpty) return [];

      final String encodedIds = eventIds.join(',');
      final Uri eventsUrl = Uri.parse(
        '$_baseUrl/rest/v1/events'
        '?event_id=in.($encodedIds)'
        '&select=$_eventSelect'
        '&order=date_event.asc',
      );

      final eventsResponse = await http.get(eventsUrl, headers: _headers);

      if (eventsResponse.statusCode == 200) {
        final List<dynamic> data = jsonDecode(eventsResponse.body);
        return data
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
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
        '?type=in.(Public,Exclusive)'
        '&select=$_eventSelect'
        '&order=date_event.asc',
      );

      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
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
        '&select=id_invite,response,invited_at,responded_at,role,event_id,'
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
}
