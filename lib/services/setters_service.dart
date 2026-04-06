// Developed and Designed by Outly • © 2026
// Screen to manage the manage the signup and login algorithms and the remote db

// libraries
import 'dart:convert';
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
  Future<int> updateUserData(String column, dynamic value) 
  async {
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
      print('Update error: $e');
      return 0; // Connection error
    }
  }
}