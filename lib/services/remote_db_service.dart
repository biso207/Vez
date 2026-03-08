import 'dart:convert';
import 'package:http/http.dart' as http; // http packet (standard in Dart/Flutter).
import 'package:crypto/crypto.dart'; // library for the hashing of the psw

import 'api_keys.dart'; // private key to connect to the remote db

class RemoteDbService {
  final String _apiKey = ApiKeys.remoteDbKey;
  final String _baseUrl = ApiKeys.baseUrl;

  /// Registers a new user in the remote database
  Future<bool> signup({
    required String email,
    required String password,
    required String username,
    required String name,
    required String surname,
    required DateTime dateOfBirth,
    required String city,
  }) async {
    try {
      // STEP HASHING PSW //
      // password to byte with salt
      var salt = "biso207_and_lasagnezio_the_best";
      var bytes = utf8.encode(password+salt);
      // hash 256
      var digest = sha256.convert(bytes);
      String hashedPassword = digest.toString();
      // --------------- //


      // connection to the db
      print('Connecting to $_baseUrl to register user: $username');

      // 1. define the endpoint (table 'user' in 'Vez' DB)
      final url = Uri.parse('$_baseUrl/rest/v1/user');

      // 2. body of the request
      final Map<String, dynamic> userData = {
        'email': email,
        'password': hashedPassword, // hashed psw
        'username': username,
        'name': name,
        'surname': surname,
        'dateOfBirth': dateOfBirth.toIso8601String(), // Converte DateTime in Stringa
        'city': city,
      };

      // 3. POST request
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey', // access token
          'apikey': _apiKey,                 // Supabase wants thi header
          'Prefer': 'return=minimal',
        },
        body: jsonEncode(userData),
      );

      // 4. verification (status can be 200 and 201)
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Registrazione completata con successo!');
        return true; // success
      } else {
        print('Errore del server: ${response.statusCode} - ${response.body}');
        return false; // fail
      }

    } catch (e) {
      print('Signup error: $e');
      return false;
    }
  }
}
