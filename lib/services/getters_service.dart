// Developed and Designed by Outly • © 2026
// Screen to manage the manage the signup and login algorithms and the remote db

// libraries
import 'dart:convert';
import 'package:http/http.dart' as http; // http packet (standard in Dart/Flutter).
import 'api_keys.dart'; // private key to connect to the remote db

class GetDBService {
  final String _apiKey = ApiKeys.remoteDbKey;
  final String _baseUrl = ApiKeys.baseUrl;
  final String userID;

  GetDBService({required this.userID});

  /// generic method to get any user attribute
  Future<String?> getUserData(String column) async {
    try {
      final url = Uri.parse(
          '$_baseUrl/rest/v1/users?user_id=eq.$userID&select=$column');

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
          return data[0][column].toString();
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
      // Using Supabase/PostgREST syntax for counting
      final url = Uri.parse('$_baseUrl/rest/v1/follows?following_id=eq.$userID&select=count');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'apikey': _apiKey,
          'Prefer': 'count=exact',
        },
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
  Future<List<dynamic>> getFollowing() async {
    try {
      final url = Uri.parse('$_baseUrl/rest/v1/follows?follower_id=eq.$userID&select=*');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'apikey': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}