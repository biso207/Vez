import 'dart:convert';
import 'dart:io'; // library to manage files
import 'package:http/http.dart' as http; // http packet (standard in Dart/Flutter).
import 'package:crypto/crypto.dart'; // library for the hashing of the psw
import 'api_keys.dart'; // private key to connect to the remote db

class RemoteDbService {
  final String _apiKey = ApiKeys.remoteDbKey;
  final String _baseUrl = ApiKeys.baseUrl;
  String? errorMessage;

  /// Registers a new user in the remote database
  Future<int> signup({
    required String email,
    required String password,
    required String username,
    required String name,
    required String surname,
    required DateTime dateOfBirth,
    required String city,
    File? profileImage,

  }) async {
    try {
      String photoUrl = "";
      if (profileImage != null) photoUrl = await uploadProfilePhoto(profileImage, username) ?? "";

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

      // 2. body of the request => the name on the right are the fields in the table
      final Map<String, dynamic> userData = {
        'username': username,
        'email': email,
        'hash_psw': hashedPassword, // hashed psw
        'name': name,
        'surname': surname,
        'date_of_birth': dateOfBirth.toIso8601String(), // DateTime to String
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
          'Prefer': 'return=minimal',
        },
        body: jsonEncode(userData),
      );

      // 4. return of the response
      return response.statusCode;
    } catch (e) {
      print('Signup error: $e');
      return 0;
    }
  }

  // todo: check this method 'cause the profile photo is not sent and set as EMPTY on the db
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

      if (response.statusCode == 200) {
        // Costruisci l'URL pubblico (controlla le impostazioni del tuo bucket)
        return '$_baseUrl/storage/v1/object/public/avatars/$fileName';
      }
      return null;
    } catch (e) {
      print('Errore upload: $e');
      return null;
    }
  }

  void setState(String Function() param0) {}
}
