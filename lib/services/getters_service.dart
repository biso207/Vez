// Developed and Designed by Outly • © 2026
// Screen to manage the manage the signup and login algorithms and the remote db

// libraries
import 'dart:convert';
import 'package:http/http.dart' as http; // http packet (standard in Dart/Flutter).
import 'api_keys.dart'; // private key to connect to the remote db

class RemoteDbService {
  final String _apiKey = ApiKeys.remoteDbKey;
  final String _baseUrl = ApiKeys.baseUrl;

  /// getting the profile photo of a logged user
  Future<String> getProfilePhoto(String username)
  async {
    try {
      // PostgresSQL REST syntax for filtering: ?column=eq.value
      // We only select the profile_photo column
      final url = Uri.parse(
          '$_baseUrl/rest/v1/user?username=eq.$username&select=profile_photo');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'apikey': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (data.isNotEmpty) {
          // Return the profile_photo link from the first matching user
          return data[0]['profile_photo'];
        } else {
          return "404"; // User not found
        }
      } else {
        return response.statusCode.toString();
      }
    } catch (e) {
      return "";
    }
  }
}