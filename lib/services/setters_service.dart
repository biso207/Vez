// Developed and Designed by Outly • © 2026
// Screen to manage the manage the signup and login algorithms and the remote db

// libraries
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http; // http packet (standard in Dart/Flutter).
import 'api_keys.dart'; // private key to connect to the remote db


class SetDBService {
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
      final Map<String, dynamic> updateData = {
        column: value,
      };

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

  /// Method to store an event in the db
  Future<int> storeEvent(Map<String, dynamic> eventData) async {
    try {
      // 1) recovering categoryID
      final String categoryID = await getCategoryID(eventData['category']);
      // 2) recovering event title
      String title = eventData['title'];

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
      String photoUrl = eventData['background_image'];
      photoUrl = await getURLEventBackgroundPhoto(photoUrl as File, title) ?? "";

      // 5) creating the payload to be sent
      final Map<String, dynamic> insertData = {
        "title": title,
        "description": eventData['description'],
        "date_event": dateEventStr,
        "max_participants": eventData['max_guests'] != null ? int.tryParse(eventData['max_guests'].toString()) : null,
        "type": eventData['type'],
        "creator_user_id": userID,
        "bg_photo": photoUrl,
        "category_id": categoryID,
        "price": eventData['price'],
        // "place_id": null, // todo: get the id of the place
      };

      // 6) url to send the request
      final insertUrl = Uri.parse('$_baseUrl/rest/v1/events');

      // 7) sending the request
      final response = await http.post(
        insertUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'apikey': _apiKey,
          'Prefer': 'return=minimal', // Ritorna un payload leggero
        },
        body: jsonEncode(insertData),
      );

      // 8) returning the status code of the response
      return response.statusCode;

    } catch (e) {
      return 0; // error
    }
  }

  // method get the url of a stored background photo of an event
  Future<String?> getURLEventBackgroundPhoto(File imageFile, String title) async {
    try {
      final fileName = '$title-${DateTime.now().millisecondsSinceEpoch}.jpg';
      final url = Uri.parse('$_baseUrl/storage/v1/object/backgrounds_events/$fileName');

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
      else {
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
      final categoryUrl = Uri.parse('$_baseUrl/rest/v1/event_category?select=category_id&name=eq.$categoryName');

      // sending the request
      final categoryResponse = await http.get(
        categoryUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'apikey': _apiKey,
        },
      );

      // recovering the category id
      if (categoryResponse.statusCode == 200) {
        final List<dynamic> categories = jsonDecode(categoryResponse.body);
        if (categories.isNotEmpty) {
          return categories[0]['id'];
        }
      }
      return categoryResponse.statusCode.toString(); // error code
    }
    catch (e) {
      return "0";
    }
  }
}