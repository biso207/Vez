// Developed and Designed by Outly • © 2026
// Screen to manage the manage the signup and login algorithms and the remote db

// libraries
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

  /// Generic method to update any user attribute (column) in the database.
  /// Uses a PATCH request to modify the existing row where userID matches.
  Future<int> updateUserData(String column, dynamic value) async {
    try {
      // Endpoint with filter to target the specific user
      final url = Uri.parse('$_baseUrl/rest/v1/users?user_id=eq.$userID');

      // STEP HASHING PSW //
      if (column == "psw") {
        // password to byte with salt
        var bytes = utf8.encode(value + salt);
        // hash 256
        var digest = sha256.convert(bytes);
        value = digest.toString();
        // --------------- //
      }

      // The body contains the column name and its new value
      final Map<String, dynamic> updateData = {column: value};

      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'apikey': _apiKey,
          'Prefer': 'return=minimal',
        },
        body: jsonEncode(updateData),
      );

      return response.statusCode;
    } catch (e) {
      return 0; // Connection error
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
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'apikey': _apiKey,
          'Prefer':
              'return=representation', // returns the created record with place_id
        },
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

  /// Method to store an event in the db.
  /// Requires a valid [placeId] obtained from [storePlace].
  Future<int> storeEvent(
    Map<String, dynamic> eventData, {
    required String placeId,
  }) async {
    try {
      // 1) recovering categoryID
      print('===== STORE EVENT DEBUG =====');
      print('1) Category name to look up: "${eventData['category']}"');
      final String categoryID = await getCategoryID(eventData['category']);
      print('2) Got categoryID: "$categoryID"');

      // Check if categoryID looks like a valid UUID
      if (categoryID.length < 10) {
        print('ERROR: categoryID is NOT a valid UUID. Category lookup failed!');
        return 400;
      }

      // 2) recovering event title
      String title = eventData['title'];
      print('3) Title: "$title", placeId: "$placeId"');

      // 3) formatting date and time
      // "2026-4-8" -> "2026-04-08"
      String dateEventStr = "";
      try {
        List<String> dParts = eventData['date'].split('-');
        String y = dParts[0];
        String m = dParts[1].padLeft(2, '0');
        String d = dParts[2].padLeft(2, '0');

        List<String> tParts = eventData['time'].split(':');
        String h = tParts[0].padLeft(2, '0');
        String min = tParts[1].padLeft(2, '0');

        // compatible type with the timestamp in the db (ISO 8601)
        dateEventStr = "$y-$m-${d}T$h:$min:00.000Z";
      } catch (e) {
        return 400;
      }

      // 4) getting url of the photo
      String photoUrl = "";
      final dynamic backgroundValue =
          eventData['bg_photo'] ?? eventData['background_image'];
      if (backgroundValue is File) {
        photoUrl =
            await getURLEventBackgroundPhoto(backgroundValue, title) ?? "";
        if (photoUrl.isEmpty) {
          print('ERROR: event background upload failed.');
          return 400;
        }
      }

      // 5) creating the payload to be sent
      final Map<String, dynamic> insertData = {
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

      print('6) storeEvent payload: ${jsonEncode(insertData)}');

      // 6) url to send the request
      final insertUrl = Uri.parse('$_baseUrl/rest/v1/events');

      // 7) sending the request
      final response = await http.post(
        insertUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'apikey': _apiKey,
          'Prefer': 'return=minimal',
        },
        body: jsonEncode(insertData),
      );

      print(
        '7) storeEvent response: ${response.statusCode} - ${response.body}',
      );
      print('===== END STORE EVENT DEBUG =====');

      // 8) returning the status code of the response
      return response.statusCode;
    } catch (e) {
      print('storeEvent error: $e');
      return 0; // error
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
      final fileName =
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
      } else {
        // This will tell you if the file was too large (413 Payload Too Large)
        print('Upload failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Errore upload: $e');
      return null;
    }
  }

  // getting an event's category ID
  Future<String> getCategoryID(String categoryName) async {
    try {
      // url to send the request
      final categoryUrl = Uri.parse(
        '$_baseUrl/rest/v1/event_category?select=category_id&name=eq.$categoryName',
      );
      print('  getCategoryID: querying name="$categoryName"');
      print('  getCategoryID: URL = $categoryUrl');

      // sending the request
      final categoryResponse = await http.get(
        categoryUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'apikey': _apiKey,
        },
      );

      print(
        '  getCategoryID: response ${categoryResponse.statusCode} body=${categoryResponse.body}',
      );

      // recovering the category id
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
      return categoryResponse.statusCode.toString(); // error code
    } catch (e) {
      print('  getCategoryID EXCEPTION: $e');
      return "0";
    }
  }
}
