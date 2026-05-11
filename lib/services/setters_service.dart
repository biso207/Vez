// Developed and Designed by Outly • © 2026
// This file is responsible for sending and updating data operations with the database.
// It centralizes logic to keep the rest of the app clean and maintainable.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart'
    as http; // http packet (standard in Dart/Flutter).
import 'package:image/image.dart' as img;

import 'api_keys.dart'; // private key to connect to the remote db

// ── SetDBService ─────────────────────────────────────────────
//
// used for: handling a specific group of database operations.
// design: keeps related methods grouped and reusable across the app.

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

  /// generic method to update any user attribute (column) in the database
  /// uses a PATCH request to modify the existing row where userID matches
  Future<int> updateUserData(String column, dynamic value) async {
    // error handling block, ensures app stability.
    try {
      final url = Uri.parse('$_baseUrl/rest/v1/users?user_id=eq.$userID');

      final Map<String, dynamic> updateData = {column: value};

      // async call to database, handle errors and loading states carefully.
      final response = await http.patch(
        url,
        headers: {..._jsonHeaders, 'Prefer': 'return=minimal'},
        body: jsonEncode(updateData),
      );

      return response.statusCode;
      // catches exceptions from database or network.
    } catch (e) {
      return 0;
    }
  }

  /// creates a follow row from the current user to the selected user.
  Future<int> followUser(String followingUserId) async {
    try {
      final String targetId = followingUserId.trim();
      if (targetId.isEmpty || targetId == userID) return 400;

      final existingUrl = Uri.parse(
        '$_baseUrl/rest/v1/follows'
        '?follower_id=eq.$userID'
        '&following_id=eq.$targetId'
        '&select=follow_id'
        '&limit=1',
      );
      final existingResponse = await http.get(
        existingUrl,
        headers: _jsonHeaders,
      );
      if (existingResponse.statusCode == 200) {
        final List<dynamic> rows = jsonDecode(existingResponse.body);
        if (rows.isNotEmpty) return 200;
      }

      final url = Uri.parse('$_baseUrl/rest/v1/follows');
      final response = await http.post(
        url,
        headers: {..._jsonHeaders, 'Prefer': 'return=minimal'},
        body: jsonEncode({
          'follower_id': userID,
          'following_id': targetId,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        }),
      );

      return response.statusCode == 201 ? 200 : response.statusCode;
    } catch (_) {
      return 0;
    }
  }

  /// removes the follow row from the current user to the selected user.
  Future<int> unfollowUser(String followingUserId) async {
    try {
      final String targetId = followingUserId.trim();
      if (targetId.isEmpty || targetId == userID) return 400;

      final url = Uri.parse(
        '$_baseUrl/rest/v1/follows'
        '?follower_id=eq.$userID'
        '&following_id=eq.$targetId',
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
    } catch (_) {
      return 0;
    }
  }

  /// return an hashed password
  String _hashPassword(String password) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// update the password in the 'users' table
  Future<int> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    // error handling block, ensures app stability.
    try {
      final String currentHash = _hashPassword(currentPassword);
      final verifyUrl = Uri.parse(
        '$_baseUrl/rest/v1/users'
        '?user_id=eq.$userID'
        '&hash_psw=eq.$currentHash'
        '&select=user_id'
        '&limit=1',
      );

      // async call to database, handle errors and loading states carefully.
      final verifyResponse = await http.get(verifyUrl, headers: _jsonHeaders);
      if (verifyResponse.statusCode != 200) return verifyResponse.statusCode;

      final List<dynamic> rows = jsonDecode(verifyResponse.body);
      if (rows.isEmpty) return 401;

      final updateUrl = Uri.parse('$_baseUrl/rest/v1/users?user_id=eq.$userID');

      // async call to database, handle errors and loading states carefully.
      final updateResponse = await http.patch(
        updateUrl,
        headers: {..._jsonHeaders, 'Prefer': 'return=minimal'},
        body: jsonEncode({'hash_psw': _hashPassword(newPassword)}),
      );

      return updateResponse.statusCode == 204 ? 200 : updateResponse.statusCode;
      // catches exceptions from database or network.
    } catch (e) {
      return 0;
    }
  }

  /// delete permanently an user from the DB
  Future<int> deleteCurrentUserAccount({String? profilePhotoUrl}) async {
    // error handling block, ensures app stability.
    try {
      // async call to database, handle errors and loading states carefully.
      final List<Map<String, dynamic>> createdEvents =
          await _getCreatedEvents();

      // async call to database, handle errors and loading states carefully.
      await _deleteRows(table: 'event_invites', filter: 'user_id=eq.$userID');
      // async call to database, handle errors and loading states carefully.
      await _deleteRows(table: 'participation', filter: 'user_id=eq.$userID');
      // async call to database, handle errors and loading states carefully.
      await _deleteRows(table: 'follows', filter: 'follower_id=eq.$userID');
      // async call to database, handle errors and loading states carefully.
      await _deleteRows(table: 'follows', filter: 'following_id=eq.$userID');

      for (final event in createdEvents) {
        final eventId = event['event_id']?.toString() ?? '';
        final placeId = event['place_id']?.toString();
        if (eventId.isEmpty) continue;

        // async call to database, handle errors and loading states carefully.
        await deleteEvent(eventId, placeId: placeId);
      }

      // async call to database, handle errors and loading states carefully.
      final userResponse = await _deleteRows(
        table: 'users',
        filter: 'user_id=eq.$userID',
      );

      if (userResponse == 200 || userResponse == 204) {
        // async call to database, handle errors and loading states carefully.
        await _deleteProfilePhoto(profilePhotoUrl);
        return 200;
      }

      return userResponse;
      // catches exceptions from database or network.
    } catch (_) {
      return 0;
    }
  }

  /// creates a place in the DB and returns the generated place_id
  /// returns null if the creation fails
  Future<String?> storePlace({
    required String name,
    String? address,
    required bool isPrecise,
    double? latitude,
    double? longitude,
  }) async {
    // error handling block, ensures app stability.
    try {
      final url = Uri.parse('$_baseUrl/rest/v1/place');

      final Map<String, dynamic> placeData = {
        'name': name,
        'is_precise': isPrecise,
        'address': (address != null && address.isNotEmpty) ? address : '',
        'latitude': latitude ?? 0.0,
        'longitude': longitude ?? 0.0,
      };

      // async call to database, handle errors and loading states carefully.
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
      // catches exceptions from database or network.
    } catch (e) {
      print('storePlace error: $e');
      return null;
    }
  }

  /// update the place infos in the 'place' table
  Future<int> updatePlace({
    required String placeId,
    required String name,
    String? address,
    required bool isPrecise,
    double? latitude,
    double? longitude,
  }) async {
    // error handling block, ensures app stability.
    try {
      final url = Uri.parse('$_baseUrl/rest/v1/place?place_id=eq.$placeId');
      final Map<String, dynamic> placeData = {
        'name': name,
        'is_precise': isPrecise,
        'address': (address != null && address.isNotEmpty) ? address : '',
        'latitude': latitude ?? 0.0,
        'longitude': longitude ?? 0.0,
      };

      // async call to database, handle errors and loading states carefully.
      final response = await http.patch(
        url,
        headers: {..._jsonHeaders, 'Prefer': 'return=minimal'},
        body: jsonEncode(placeData),
      );

      return response.statusCode;
      // catches exceptions from database or network.
    } catch (e) {
      print('updatePlace error: $e');
      return 0;
    }
  }

  /// method to store an event in the db
  /// requires a valid [placeId] obtained from [storePlace]
  Future<int> storeEvent(
    Map<String, dynamic> eventData, {
    required String placeId,
  }) async {
    // error handling block, ensures app stability.
    try {
      // async call to database, handle errors and loading states carefully.
      final Map<String, dynamic>? insertData = await _buildEventPayload(
        eventData,
        placeId: placeId,
      );
      if (insertData == null) return 400;

      final insertUrl = Uri.parse('$_baseUrl/rest/v1/events');

      // async call to database, handle errors and loading states carefully.
      final response = await http.post(
        insertUrl,
        headers: {..._jsonHeaders, 'Prefer': 'return=minimal'},
        body: jsonEncode(insertData),
      );

      print('storeEvent response: ${response.statusCode} - ${response.body}');
      return response.statusCode;
      // catches exceptions from database or network.
    } catch (e) {
      print('storeEvent error: $e');
      return 0;
    }
  }

  /// stores an event in the DB and returns the generated event_id
  Future<String?> storeEventAndGetId(
    Map<String, dynamic> eventData, {
    required String placeId,
  }) async {
    // error handling block, ensures app stability.
    try {
      // async call to database, handle errors and loading states carefully.
      final Map<String, dynamic>? insertData = await _buildEventPayload(
        eventData,
        placeId: placeId,
      );
      if (insertData == null) return null;

      final insertUrl = Uri.parse('$_baseUrl/rest/v1/events');

      // async call to database, handle errors and loading states carefully.
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
      // catches exceptions from database or network.
    } catch (e) {
      print('storeEventAndGetId error: $e');
      return null;
    }
  }

  /// updates data about an event in the 'events' table
  Future<int> updateEvent(
    String eventId,
    Map<String, dynamic> eventData, {
    required String placeId,
    String? currentBackgroundUrl,
  }) async {
    // error handling block, ensures app stability.
    try {
      // async call to database, handle errors and loading states carefully.
      final Map<String, dynamic>? updateData = await _buildEventPayload(
        eventData,
        placeId: placeId,
        currentBackgroundUrl: currentBackgroundUrl,
      );
      if (updateData == null) return 400;

      final url = Uri.parse('$_baseUrl/rest/v1/events?event_id=eq.$eventId');

      // async call to database, handle errors and loading states carefully.
      final response = await http.patch(
        url,
        headers: {..._jsonHeaders, 'Prefer': 'return=minimal'},
        body: jsonEncode(updateData),
      );

      print('updateEvent response: ${response.statusCode} - ${response.body}');
      return response.statusCode;
      // catches exceptions from database or network.
    } catch (e) {
      print('updateEvent error: $e');
      return 0;
    }
  }

  /// permanently deletes and event from the DB
  Future<int> deleteEvent(String eventId, {String? placeId}) async {
    // error handling block, ensures app stability.
    try {
      // async call to database, handle errors and loading states carefully.
      await _deleteRows(table: 'event_invites', filter: 'event_id=eq.$eventId');
      // async call to database, handle errors and loading states carefully.
      await _deleteRows(table: 'participation', filter: 'event_id=eq.$eventId');

      // async call to database, handle errors and loading states carefully.
      final eventResponse = await _deleteRows(
        table: 'events',
        filter: 'event_id=eq.$eventId',
      );

      if ((eventResponse == 200 || eventResponse == 204) &&
          placeId != null &&
          placeId.isNotEmpty) {
        // async call to database, handle errors and loading states carefully.
        await _deleteRows(table: 'place', filter: 'place_id=eq.$placeId');
      }

      return eventResponse == 204 ? 200 : eventResponse;
      // catches exceptions from database or network.
    } catch (e) {
      print('deleteEvent error: $e');
      return 0;
    }
  }

  /// method to add or update invited users to an event in the 'event_invite
  Future<int> addOrUpdateEventInvite({
    required String eventId,
    required String invitedUserId,
    String role = 'guest',
  }) async {
    // error handling block, ensures app stability.
    try {
      // async call to database, handle errors and loading states carefully.
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
        // async call to database, handle errors and loading states carefully.
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
          // async call to database, handle errors and loading states carefully.
          await _sendEventInviteNotification(
            eventId: eventId,
            invitedUserId: invitedUserId,
          );
        }
        return response.statusCode;
      }

      final url = Uri.parse('$_baseUrl/rest/v1/event_invites');
      // async call to database, handle errors and loading states carefully.
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
        // async call to database, handle errors and loading states carefully.
        await _sendEventInviteNotification(
          eventId: eventId,
          invitedUserId: invitedUserId,
        );
      }

      return response.statusCode;
      // catches exceptions from database or network.
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
    // error handling block, ensures app stability.
    try {
      final url = Uri.parse(
        '$_baseUrl/functions/v1/send-event-invite-notification',
      );
      // async call to database, handle errors and loading states carefully.
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
      // catches exceptions from database or network.
    } catch (e) {
      print('sendEventInviteNotification error: $e');
    }
  }

  Future<int> removeEventInvite({
    required String eventId,
    required String invitedUserId,
  }) async {
    // error handling block, ensures app stability.
    try {
      final url = Uri.parse(
        '$_baseUrl/rest/v1/event_invites'
        '?event_id=eq.$eventId&user_id=eq.$invitedUserId',
      );
      // async call to database, handle errors and loading states carefully.
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'apikey': _apiKey,
          'Prefer': 'return=minimal',
        },
      );
      return response.statusCode == 204 ? 200 : response.statusCode;
      // catches exceptions from database or network.
    } catch (e) {
      print('removeEventInvite error: $e');
      return 0;
    }
  }

  Future<int> updateEventInviteResponse({
    required String eventId,
    required String responseState,
  }) async {
    // error handling block, ensures app stability.
    try {
      final normalizedState = _normalizeInviteResponse(responseState);
      final url = Uri.parse(
        '$_baseUrl/rest/v1/event_invites'
        '?event_id=eq.$eventId&user_id=eq.$userID',
      );
      // async call to database, handle errors and loading states carefully.
      final response = await http.patch(
        url,
        headers: {..._jsonHeaders, 'Prefer': 'return=minimal'},
        body: jsonEncode({
          'response': normalizedState,
          'responded_at': DateTime.now().toUtc().toIso8601String(),
        }),
      );
      return response.statusCode == 204 ? 200 : response.statusCode;
      // catches exceptions from database or network.
    } catch (e) {
      print('updateEventInviteResponse error: $e');
      return 0;
    }
  }

  Future<int> upsertEventParticipation({
    required String eventId,
    required String participationState,
  }) async {
    // error handling block, ensures app stability.
    try {
      final String normalizedState = _normalizeInviteResponse(
        participationState,
      );
      // async call to database, handle errors and loading states carefully.
      final int? existingParticipationId = await _getExistingParticipationId(
        eventId: eventId,
      );

      if (existingParticipationId != null) {
        final url = Uri.parse(
          '$_baseUrl/rest/v1/participation'
          '?participation_id=eq.$existingParticipationId',
        );
        // async call to database, handle errors and loading states carefully.
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
      // async call to database, handle errors and loading states carefully.
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
      // catches exceptions from database or network.
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

    // async call to database, handle errors and loading states carefully.
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

    // async call to database, handle errors and loading states carefully.
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
    // error handling block, ensures app stability.
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
      // catches exceptions from database or network.
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
      // async call to database, handle errors and loading states carefully.
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
    // async call to database, handle errors and loading states carefully.
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

  Future<List<Map<String, dynamic>>> _getCreatedEvents() async {
    // error handling block, ensures app stability.
    try {
      final url = Uri.parse(
        '$_baseUrl/rest/v1/events'
        '?creator_user_id=eq.$userID'
        '&select=event_id,place_id',
      );
      // async call to database, handle errors and loading states carefully.
      final response = await http.get(url, headers: _jsonHeaders);
      if (response.statusCode != 200) return [];

      final List<dynamic> data = jsonDecode(response.body);
      return data
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      // catches exceptions from database or network.
    } catch (_) {
      return [];
    }
  }

  Future<void> _deleteProfilePhoto(String? profilePhotoUrl) async {
    final String url = profilePhotoUrl?.trim() ?? '';
    if (url.isEmpty || !url.contains('/avatars/')) return;

    final String objectName = Uri.decodeComponent(url.split('/avatars/').last);
    if (objectName.isEmpty) return;

    // error handling block, ensures app stability.
    try {
      final deleteUrl = Uri.parse(
        '$_baseUrl/storage/v1/object/avatars/$objectName',
      );
      // async call to database, handle errors and loading states carefully.
      await http.delete(
        deleteUrl,
        headers: {'Authorization': 'Bearer $_apiKey', 'apikey': _apiKey},
      );
      // catches exceptions from database or network.
    } catch (_) {}
  }

  Future<int?> _getExistingInviteId({
    required String eventId,
    required String invitedUserId,
  }) async {
    // error handling block, ensures app stability.
    try {
      final url = Uri.parse(
        '$_baseUrl/rest/v1/event_invites'
        '?event_id=eq.$eventId&user_id=eq.$invitedUserId&select=invite_id'
        '&limit=1',
      );
      // async call to database, handle errors and loading states carefully.
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
    // error handling block, ensures app stability.
    try {
      final url = Uri.parse(
        '$_baseUrl/rest/v1/participation'
        '?event_id=eq.$eventId&user_id=eq.$userID&select=participation_id'
        '&limit=1',
      );
      // async call to database, handle errors and loading states carefully.
      final response = await http.get(url, headers: _jsonHeaders);
      if (response.statusCode != 200) return null;

      final List<dynamic> data = jsonDecode(response.body);
      if (data.isEmpty) return null;
      return data.first['participation_id'] as int?;
      // catches exceptions from database or network.
    } catch (e) {
      print('getExistingParticipationId error: $e');
      return null;
    }
  }

  Future<String?> getURLEventBackgroundPhoto(
    File imageFile,
    String title,
  ) async {
    // error handling block, ensures app stability.
    try {
      // async call to database, handle errors and loading states carefully.
      if (!await imageFile.exists()) {
        print('Upload failed: background image file not found.');
        return null;
      }

      final List<int>? uploadBytes = await _compressedEventBackgroundBytes(
        imageFile,
      );
      if (uploadBytes == null) return null;

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

      // async call to database, handle errors and loading states carefully.
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'apikey': _apiKey,
          'Content-Type': 'image/jpeg',
        },
        // async call to database, handle errors and loading states carefully.
        body: uploadBytes,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return '$_baseUrl/storage/v1/object/public/backgrounds_events/$fileName';
      }

      print('Upload failed: ${response.statusCode} - ${response.body}');
      return null;
      // catches exceptions from database or network.
    } catch (e) {
      print('Errore upload: $e');
      return null;
    }
  }

  Future<List<int>?> _compressedEventBackgroundBytes(File imageFile) async {
    final originalBytes = await imageFile.readAsBytes();
    if (originalBytes.length <= _maxEventBackgroundSizeBytes) {
      return originalBytes;
    }

    // Supabase rejects large event backgrounds; compress locally so the user
    // can still upload normal gallery photos without seeing a hard failure.
    final decoded = img.decodeImage(originalBytes);
    if (decoded == null) {
      print('Upload failed: background image cannot be decoded.');
      return null;
    }

    img.Image image = decoded;
    if (image.width > 1600) {
      image = img.copyResize(image, width: 1600);
    }

    // Try quality steps before resizing again, preserving detail when possible.
    for (final quality in [85, 75, 65, 55, 45, 35]) {
      final bytes = img.encodeJpg(image, quality: quality);
      if (bytes.length <= _maxEventBackgroundSizeBytes) {
        return bytes;
      }
    }

    final small = img.copyResize(image, width: 1000);
    final bytes = img.encodeJpg(small, quality: 35);
    if (bytes.length <= _maxEventBackgroundSizeBytes) {
      return bytes;
    }

    print('Upload failed: compressed background image still exceeds 1 MB.');
    return null;
  }

  Future<String> getCategoryID(String categoryName) async {
    // error handling block, ensures app stability.
    try {
      final categoryUrl = Uri.parse(
        '$_baseUrl/rest/v1/event_category?select=category_id&name=eq.$categoryName',
      );
      print('  getCategoryID: querying name="$categoryName"');
      print('  getCategoryID: URL = $categoryUrl');

      // async call to database, handle errors and loading states carefully.
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
      // catches exceptions from database or network.
    } catch (e) {
      print('  getCategoryID EXCEPTION: $e');
      return "0";
    }
  }
}
