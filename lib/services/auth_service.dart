// Developed and Designed by Outly • © 2026
// Screen to manage the manage the signup and login algorithms and the remote db

// libraries
import 'dart:convert';
import 'dart:io'; // library to manage files
import 'package:http/http.dart' as http; // http packet (standard in Dart/Flutter).
import 'package:crypto/crypto.dart'; // library for the hashing of the psw
import 'package:vez/services/user_session.dart';
import 'api_keys.dart'; // private key to connect to the remote db

class RemoteDbService {
  final String _apiKey = ApiKeys.remoteDbKey;
  final String _baseUrl = ApiKeys.baseUrl;
  String? errorMessage;
  final salt = "biso207_and_lasagnezio_the_best";

  /// Registers a new user in the remote database
  Future<int> signup({
    required String email,
    required String password,
    required String username,
    required DateTime dateOfBirth,
    required String city,
    File? profileImage,
  }) async {
    try {
      String photoUrl = "";
      if (profileImage != null) photoUrl = await uploadProfilePhoto(profileImage, username) ?? "";

      // STEP HASHING PSW //
      // password to byte with salt
      var bytes = utf8.encode(password+salt);
      // hash 256
      var digest = sha256.convert(bytes);
      String hashedPassword = digest.toString();
      // --------------- //


      // connection to the db
      print('Connecting to $_baseUrl to register user: $username');

      // 1. define the endpoint (table 'users' in 'Vez' DB)
      final url = Uri.parse('$_baseUrl/rest/v1/users');

      // 2. body of the request => the name on the right are the fields in the table
      final Map<String, dynamic> userData = {
        'username': username,
        'email': email,
        'hash_psw': hashedPassword, // hashed psw
        'date_of_birth': '${dateOfBirth.year.toString().padLeft(4, '0')}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}', // Date only (YYYY-MM-DD)
        'city': city,
        'profile_photo': photoUrl,
        'bio': "",
        'account_state': 'active',
        'num_created_events': 0,
        'num_participated_events': 0,
      };

      // 3. POST request
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey', // access token
          'apikey': _apiKey,                 // Supabase wants thi header
          'Prefer': 'return=representation', // return the created record
        },
        body: jsonEncode(userData),
      );

      // DEBUG: log the full response for diagnosis
      print('Signup response status: ${response.statusCode}');
      print('Signup response body: ${response.body}');
      print('Signup request payload: ${jsonEncode(userData)}');

      // success
      if (response.statusCode == 201 || response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // setting the userID
        if (data.isNotEmpty) UserSession().userID = data[0]['user_id']!.toString();
        return response.statusCode;
      }

      // any error
      return response.statusCode;
    } catch (e) {
      print('Signup error: $e');
      return 0;
    }
  }
  
  /// Login a user in the remote database
  Future<int> login({
    required String username,
    required String password,
  }) async {
    try {
      // 1. Hashing the password (must match the salt used in signup)
      var bytes = utf8.encode(password + salt);
      var digest = sha256.convert(bytes);
      String hashedPassword = digest.toString();

      // 2. Querying the user with matching username and hashed password
      // PostgresSQL REST syntax for filtering: ?column=eq.value
      final url = Uri.parse('$_baseUrl/rest/v1/users?username=eq.$username&hash_psw=eq.$hashedPassword&select=*');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'apikey': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        if (data.isNotEmpty) { // Success

          // reading from the db the userID
          UserSession().userID = data[0]['user_id']!.toString();
          return 200;
        }
        else { return 401; } // Unauthorized
      }
      else { return response.statusCode; }
    } catch (e) {
      return 0;
    }
  }

  // method to upload a file (profile photo)
  Future<String?> uploadProfilePhoto(File imageFile, String username) async {
    try {
      final fileName = '$username-${DateTime.now().millisecondsSinceEpoch}.jpg';
      final url = Uri.parse('$_baseUrl/storage/v1/object/avatars/$fileName');

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
        return '$_baseUrl/storage/v1/object/public/avatars/$fileName';
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
}
