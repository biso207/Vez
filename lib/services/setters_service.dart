import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart'
    as http; // http packet (standard in Dart/Flutter).

import 'api_keys.dart'; // private key to connect to the remote db

class SetDBService {
  static const int _maxEventBackgroundSizeBytes = 1024 * 1024;

  final String _apiKey = ApiKeys.remoteDbKey;
  final String _baseUrl = ApiKeys.baseUrl;
  final String userID;
  final salt = "biso207_and_lasagnezio_the_best";

  SetDBService({required this.userID});

  Map<String, String> get _jsonHeaders => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_apiKey',
    'apikey': _apiKey,
  };

  /// Generic method to update any user attribute (column) in the database.
  /// Uses a PATCH request to modify the existing row where userID matches.
  Future<int> updateUserData(String column, dynamic value) async {
    try {
      final url = Uri.parse('$_baseUrl/rest/v1/users?user_id=eq.$userID');

      if (column == "psw") {
        final bytes = utf8.encode(value + salt);
        final digest = sha256.convert(bytes);
        value = digest.toString();
      }

      final Map<String, dynamic> updateData = {column: value};

      final response = await http.patch(
        url,
        headers: {..._jsonHeaders, 'Prefer': 'return=minimal'},
        body: jsonEncode(updateData),
      );

      return response.statusCode;
    } catch (e) {
      return 0;
    }
  }

  /// Creates a place in the database and returns the generated place_id.
  /// Returns null if the creation fails.
  Future<String?> storePlace({
    required String name,
    String? address,
    required bool isPrecise,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/rest/v1/place');

      final Map<String, dynamic> placeData = {
        'name': name,
        'is_precise': isPrecise,
        'address': (address != null && address.isNotEmpty) ? address : '',
        'latitude': latitude ?? 0.0,
        'longitude': longitude ?? 0.0,
      };

      final response = await http.post(
        url,
        headers: {..._jsonHeaders, 'Prefer': 'return=representation'},
        body: jsonEncode(placeData),
      );

      print('storePlace response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return data[0]['place_id'].toString();
        }
      }
      return null;
    } catch (e) {
      print('storePlace error: $e');
      return null;
    }
  }

  Future<int> updatePlace({
    required String placeId,
    required String name,
    String? address,
    required bool isPrecise,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/rest/v1/place?place_id=eq.$placeId');
      final Map<String, dynamic> placeData = {
        'name': name,
        'is_precise': isPrecise,
        'address': (address != null && address.isNotEmpty) ? address : '',
        'latitude': latitude ?? 0.0,
        'longitude': longitude ?? 0.0,
      };

      final response = await http.patch(
        url,
        headers: {..._jsonHeaders, 'Prefer': 'return=minimal'},
        body: jsonEncode(placeData),
      );

      return response.statusCode;
    } catch (e) {
      print('updatePlace error: $e');
      return 0;
    }
  }

  /// Method to store an event in the db.
  /// Requires a valid [placeId] obtained from [storePlace].
  Future<int> storeEvent(
    Map<String, dynamic> eventData, {
    required String placeId,
  }) async {
    try {
      final Map<String, dynamic>? insertData = await _buildEventPayload(
        eventData,
        placeId: placeId,
      );
      if (insertData == null) return 400;

      final insertUrl = Uri.parse('$_baseUrl/rest/v1/events');

      final response = await http.post(
        insertUrl,
        headers: {..._jsonHeaders, 'Prefer': 'return=minimal'},
        body: jsonEncode(insertData),
      );

      print('storeEvent response: ${response.statusCode} - ${response.body}');
      return response.statusCode;
    } catch (e) {
      print('storeEvent error: $e');
      return 0;
    }
  }

  Future<String?> storeEventAndGetId(
    Map<String, dynamic> eventData, {
    required String placeId,
  }) async {
    try {
      final Map<String, dynamic>? insertData = await _buildEventPayload(
        eventData,
        placeId: placeId,
      );
      if (insertData == null) return null;

      final insertUrl = Uri.parse('$_baseUrl/rest/v1/events');

      final response = await http.post(
        insertUrl,
        headers: {..._jsonHeaders, 'Prefer': 'return=representation'},
        body: jsonEncode(insertData),
      );

      print(
        'storeEventAndGetId response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return data.first['event_id']?.toString();
        }
      }

      return null;
    } catch (e) {
      print('storeEventAndGetId error: $e');
      return null;
    }
  }

  Future<int> updateEvent(
    String eventId,
    Map<String, dynamic> eventData, {
    required String placeId,
    String? currentBackgroundUrl,
  }) async {
    try {
      final Map<String, dynamic>? updateData = await _buildEventPayload(
        eventData,
        placeId: placeId,
        currentBackgroundUrl: currentBackgroundUrl,
      );
      if (updateData == null) return 400;

      final url = Uri.parse('$_baseUrl/rest/v1/events?event_id=eq.$eventId');
      final response = await http.patch(
        url,
        headers: {..._jsonHeaders, 'Prefer': 'return=minimal'},
        body: jsonEncode(updateData),
      );

      print('updateEvent response: ${response.statusCode} - ${response.body}');
      return response.statusCode;
    } catch (e) {
      print('updateEvent error: $e');
      return 0;
    }
  }

  Future<int> deleteEvent(String eventId, {String? placeId}) async {
    try {
      await _deleteRows(table: 'event_invites', filter: 'event_id=eq.$eventId');
      await _deleteRows(table: 'participation', filter: 'event_id=eq.$eventId');

      final eventResponse = await _deleteRows(
        table: 'events',
        filter: 'event_id=eq.$eventId',
      );

      if ((eventResponse == 200 || eventResponse == 204) &&
          placeId != null &&
          placeId.isNotEmpty) {
        await _deleteRows(table: 'place', filter: 'place_id=eq.$placeId');
      }

      return eventResponse == 204 ? 200 : eventResponse;
    } catch (e) {
      print('deleteEvent error: $e');
      return 0;
    }
  }

  Future<int> addOrUpdateEventInvite({
    required String eventId,
    required String invitedUserId,
    String role = 'guest',
  }) async {
    try {
      final existingInviteId = await _getExistingInviteId(
        eventId: eventId,
        invitedUserId: invitedUserId,
      );
      final String now = DateTime.now().toUtc().toIso8601String();

      if (existingInviteId != null) {
        final url = Uri.parse(
          '$_baseUrl/rest/v1/event_invites'
          '?event_id=eq.$eventId&user_id=eq.$invitedUserId',
        );
        final response = await http.patch(
          url,
          headers: {..._jsonHeaders, 'Prefer': 'return=minimal'},
          body: jsonEncode({
            'role': role,
            'response': 'maybe',
            'invited_at': now,
            'responded_at': null,
          }),
        );
        if (response.statusCode == 200 || response.statusCode == 204) {
          await _sendEventInviteNotification(
            eventId: eventId,
            invitedUserId: invitedUserId,
          );
        }
        return response.statusCode;
      }

      final url = Uri.parse('$_baseUrl/rest/v1/event_invites');
      final response = await http.post(
        url,
        headers: {..._jsonHeaders, 'Prefer': 'return=minimal'},
        body: jsonEncode({
          'event_id': eventId,
          'user_id': invitedUserId,
          'role': role,
          'response': 'maybe',
          'invited_at': now,
          'responded_at': null,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _sendEventInviteNotification(
          eventId: eventId,
          invitedUserId: invitedUserId,
        );
      }

      return response.statusCode;
    } catch (e) {
      print('addOrUpdateEventInvite error: $e');
      return 0;
    }
  }

  Future<int> updateEventInviteRole({
    required String eventId,
    required String invitedUserId,
    required String role,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/rest/v1/event_invites'
        '?event_id=eq.$eventId&user_id=eq.$invitedUserId',
      );
      final response = await http.patch(
        url,
        headers: {..._jsonHeaders, 'Prefer': 'return=minimal'},
        body: jsonEncode({'role': role}),
      );
      return response.statusCode == 204 ? 200 : response.statusCode;
    } catch (e) {
      print('updateEventInviteRole error: $e');
      return 0;
    }
  }

  Future<void> _sendEventInviteNotification({
    required String eventId,
    required String invitedUserId,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/functions/v1/send-event-invite-notification',
      );
      final response = await http.post(
        url,
        headers: _jsonHeaders,
        body: jsonEncode({
          'event_id': eventId,
          'invited_user_id': invitedUserId,
          'inviter_user_id': userID,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        print(
          'sendEventInviteNotification failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('sendEventInviteNotification error: $e');
    }
  }

  Future<int> removeEventInvite({
    required String eventId,
    required String invitedUserId,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/rest/v1/event_invites'
        '?event_id=eq.$eventId&user_id=eq.$invitedUserId',
      );
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'apikey': _apiKey,
          'Prefer': 'return=minimal',
        },
      );
      return response.statusCode == 204 ? 200 : response.statusCode;
    } catch (e) {
      print('removeEventInvite error: $e');
      return 0;
    }
  }

  Future<int> updateEventInviteResponse({
    required String eventId,
    required String responseState,
  }) async {
    try {
      final normalizedState = _normalizeInviteResponse(responseState);
      final url = Uri.parse(
        '$_baseUrl/rest/v1/event_invites'
        '?event_id=eq.$eventId&user_id=eq.$userID',
      );
      final response = await http.patch(
        url,
        headers: {..._jsonHeaders, 'Prefer': 'return=minimal'},
        body: jsonEncode({
          'response': normalizedState,
          'responded_at': DateTime.now().toUtc().toIso8601String(),
        }),
      );
      return response.statusCode == 204 ? 200 : response.statusCode;
    } catch (e) {
      print('updateEventInviteResponse error: $e');
      return 0;
    }
  }

  Future<int> upsertEventParticipation({
    required String eventId,
    required String participationState,
  }) async {
    try {
      final String normalizedState = _normalizeInviteResponse(
        participationState,
      );
      final int? existingParticipationId = await _getExistingParticipationId(
        eventId: eventId,
      );

      if (existingParticipationId != null) {
        final url = Uri.parse(
          '$_baseUrl/rest/v1/participation'
          '?participation_id=eq.$existingParticipationId',
        );
        final response = await http.patch(
          url,
          headers: {..._jsonHeaders, 'Prefer': 'return=minimal'},
          body: jsonEncode({
            'participation_state': normalizedState,
            'participation_date': DateTime.now().toUtc().toIso8601String(),
          }),
        );
        return response.statusCode == 204 ? 200 : response.statusCode;
      }

      final url = Uri.parse('$_baseUrl/rest/v1/participation');
      final response = await http.post(
        url,
        headers: {..._jsonHeaders, 'Prefer': 'return=minimal'},
        body: jsonEncode({
          'event_id': eventId,
          'user_id': userID,
          'participation_state': normalizedState,
          'participation_date': DateTime.now().toUtc().toIso8601String(),
        }),
      );
      return response.statusCode == 201 ? 200 : response.statusCode;
    } catch (e) {
      print('upsertEventParticipation error: $e');
      return 0;
    }
  }

  String _normalizeInviteResponse(String rawState) {
    final normalized = rawState.trim().toLowerCase().replaceAll(' ', '_');
    if (normalized == 'going' ||
        normalized == 'accepted' ||
        normalized == 'yes') {
      return 'going';
    }
    if (normalized == 'not_going' ||
        normalized == 'notgoing' ||
        normalized == 'declined' ||
        normalized == 'no') {
      return 'not_going';
    }
    return 'maybe';
  }

  Future<Map<String, dynamic>?> _buildEventPayload(
    Map<String, dynamic> eventData, {
    required String placeId,
    String? currentBackgroundUrl,
  }) async {
    print('===== EVENT PAYLOAD DEBUG =====');
    print('Category name to look up: "${eventData['category']}"');
    final String categoryID = await getCategoryID(eventData['category']);
    print('Got categoryID: "$categoryID"');

    if (categoryID.length < 10) {
      print('ERROR: categoryID is NOT a valid UUID. Category lookup failed.');
      return null;
    }

    final String? dateEventStr = _formatEventDateTime(
      eventData['date']?.toString(),
      eventData['time']?.toString(),
    );
    if (dateEventStr == null) return null;

    final String title = (eventData['title'] ?? '').toString().trim();
    final String? photoUrl = await _resolveEventBackgroundUrl(
      backgroundValue: eventData['bg_photo'] ?? eventData['background_image'],
      title: title,
      currentBackgroundUrl: currentBackgroundUrl,
    );
    if (photoUrl == null) return null;

    final Map<String, dynamic> payload = {
      "title": title,
      "description": eventData['description'],
      "date_event": dateEventStr,
      "max_participants": eventData['max_guests'] != null
          ? int.tryParse(eventData['max_guests'].toString())
          : null,
      "type": eventData['type'],
      "creator_user_id": userID,
      "bg_photo": photoUrl,
      "category_id": categoryID,
      "price": eventData['price'] != null
          ? int.tryParse(eventData['price'].toString())
          : null,
      "place_id": placeId,
    };

    print('Event payload: ${jsonEncode(payload)}');
    print('===== END EVENT PAYLOAD DEBUG =====');
    return payload;
  }

  String? _formatEventDateTime(String? rawDate, String? rawTime) {
    try {
      if (rawDate == null || rawTime == null) return null;

      final List<String> dParts = rawDate.split('-');
      final String y = dParts[0];
      final String m = dParts[1].padLeft(2, '0');
      final String d = dParts[2].padLeft(2, '0');

      final List<String> tParts = rawTime.split(':');
      final String h = tParts[0].padLeft(2, '0');
      final String min = tParts[1].padLeft(2, '0');

      return "$y-$m-${d}T$h:$min:00.000Z";
    } catch (e) {
      print('formatEventDateTime error: $e');
      return null;
    }
  }

  Future<String?> _resolveEventBackgroundUrl({
    required dynamic backgroundValue,
    required String title,
    String? currentBackgroundUrl,
  }) async {
    if (backgroundValue is File) {
      final String? uploadedUrl = await getURLEventBackgroundPhoto(
        backgroundValue,
        title,
      );
      if (uploadedUrl == null || uploadedUrl.isEmpty) {
        print('ERROR: event background upload failed.');
        return null;
      }
      return uploadedUrl;
    }

    if (backgroundValue is String) {
      return backgroundValue.trim();
    }

    return currentBackgroundUrl?.trim() ?? '';
  }

  Future<int> _deleteRows({
    required String table,
    required String filter,
  }) async {
    final url = Uri.parse('$_baseUrl/rest/v1/$table?$filter');
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'apikey': _apiKey,
        'Prefer': 'return=minimal',
      },
    );
    return response.statusCode;
  }

  Future<int?> _getExistingInviteId({
    required String eventId,
    required String invitedUserId,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/rest/v1/event_invites'
        '?event_id=eq.$eventId&user_id=eq.$invitedUserId&select=invite_id'
        '&limit=1',
      );
      final response = await http.get(url, headers: _jsonHeaders);
      if (response.statusCode != 200) return null;

      final List<dynamic> data = jsonDecode(response.body);
      if (data.isEmpty) return null;
      return data.first['invite_id'] as int?;
    } catch (e) {
      print('getExistingInviteId error: $e');
      return null;
    }
  }

  Future<int?> _getExistingParticipationId({required String eventId}) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/rest/v1/participation'
        '?event_id=eq.$eventId&user_id=eq.$userID&select=participation_id'
        '&limit=1',
      );
      final response = await http.get(url, headers: _jsonHeaders);
      if (response.statusCode != 200) return null;

      final List<dynamic> data = jsonDecode(response.body);
      if (data.isEmpty) return null;
      return data.first['participation_id'] as int?;
    } catch (e) {
      print('getExistingParticipationId error: $e');
      return null;
    }
  }

  // method get the url of a stored background photo of an event
  Future<String?> getURLEventBackgroundPhoto(
    File imageFile,
    String title,
  ) async {
    try {
      if (!await imageFile.exists()) {
        print('Upload failed: background image file not found.');
        return null;
      }

      final int fileSize = await imageFile.length();
      if (fileSize > _maxEventBackgroundSizeBytes) {
        print('Upload failed: background image exceeds 1 MB.');
        return null;
      }

      final String safeTitle = title
          .trim()
          .replaceAll(RegExp(r'\s+'), '_')
          .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '')
          .toLowerCase();
      final String normalizedTitle = safeTitle.isEmpty ? 'event' : safeTitle;
      final String fileName =
          '$normalizedTitle-${DateTime.now().millisecondsSinceEpoch}.jpg';
      final url = Uri.parse(
        '$_baseUrl/storage/v1/object/backgrounds_events/$fileName',
      );

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'apikey': _apiKey,
          'Content-Type': 'image/jpeg',
        },
        body: await imageFile.readAsBytes(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return '$_baseUrl/storage/v1/object/public/backgrounds_events/$fileName';
      }

      print('Upload failed: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('Errore upload: $e');
      return null;
    }
  }

  // getting an event's category ID
  Future<String> getCategoryID(String categoryName) async {
    try {
      final categoryUrl = Uri.parse(
        '$_baseUrl/rest/v1/event_category?select=category_id&name=eq.$categoryName',
      );
      print('  getCategoryID: querying name="$categoryName"');
      print('  getCategoryID: URL = $categoryUrl');

      final categoryResponse = await http.get(
        categoryUrl,
        headers: _jsonHeaders,
      );

      print(
        '  getCategoryID: response ${categoryResponse.statusCode} body=${categoryResponse.body}',
      );

      if (categoryResponse.statusCode == 200) {
        final List<dynamic> categories = jsonDecode(categoryResponse.body);
        if (categories.isNotEmpty) {
          print('  getCategoryID: FOUND ID = ${categories[0]['category_id']}');
          return categories[0]['category_id'];
        }
        print(
          '  getCategoryID: WARNING empty result! No category named "$categoryName" in DB.',
        );
      }
      return categoryResponse.statusCode.toString();
    } catch (e) {
      print('  getCategoryID EXCEPTION: $e');
      return "0";
    }
  }
}
