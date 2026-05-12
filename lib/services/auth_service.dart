// Developed and Designed by Outly • © 2026
// Screen to manage the manage the signup and login algorithms and the remote db

// libraries
import 'dart:convert';
import 'dart:io'; // library to manage files
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart'
    as http; // http packet (standard in Dart/Flutter).
import 'package:crypto/crypto.dart'; // library for the hashing of the psw
import 'package:vez/services/notification_service.dart';
import 'package:vez/services/translation_service.dart';
import 'package:vez/services/user_session.dart';
import 'api_keys.dart'; // private key to connect to the remote db

class RemoteDbService {
  final String _apiKey = ApiKeys.remoteDbKey;
  final String _baseUrl = ApiKeys.baseUrl;
  String? errorMessage;
  final salt = "biso207_and_lasagnezio_the_best";

  /// requests a new signup otp in the remote otp table.
  Future<int> requestSignupOtp({
    required String phone,
    required String accountType,
  }) async {
    try {
      final String otpCode = (Random.secure().nextInt(900000) + 100000)
          .toString();
      final DateTime expiresAt = DateTime.now().toUtc().add(
        const Duration(minutes: 10),
      );
      final Uri url = Uri.parse('$_baseUrl/rest/v1/venue_otp_verifications');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'apikey': _apiKey,
          'Prefer': 'return=representation',
        },
        body: jsonEncode({
          'otp_code': otpCode,
          'expires_at': expiresAt.toIso8601String(),
        }),
      );

      debugPrint(
        'Signup OTP requested for $accountType phone $phone: $otpCode',
      );
      return response.statusCode;
    } catch (e) {
      debugPrint('Signup OTP request error: $e');
      return 0;
    }
  }

  /// verifies a signup otp and marks it as consumed.
  Future<int> verifySignupOtp(String code) async {
    try {
      final String otpCode = code.trim();
      final String encodedCode = Uri.encodeComponent(otpCode);
      final Uri queryUrl = Uri.parse(
        '$_baseUrl/rest/v1/venue_otp_verifications'
        '?otp_code=eq.$encodedCode'
        '&verified_at=is.null'
        '&select=expires_at'
        '&order=created_at.desc'
        '&limit=1',
      );

      final queryResponse = await http.get(
        queryUrl,
        headers: {'Authorization': 'Bearer $_apiKey', 'apikey': _apiKey},
      );
      if (queryResponse.statusCode != 200) return queryResponse.statusCode;

      final List<dynamic> rows = jsonDecode(queryResponse.body);
      if (rows.isEmpty) return 401;

      final DateTime? expiresAt = DateTime.tryParse(
        (rows.first['expires_at'] ?? '').toString(),
      );
      if (expiresAt == null || expiresAt.isBefore(DateTime.now().toUtc())) {
        return 410;
      }

      final Uri patchUrl = Uri.parse(
        '$_baseUrl/rest/v1/venue_otp_verifications'
        '?otp_code=eq.$encodedCode'
        '&verified_at=is.null',
      );
      final patchResponse = await http.patch(
        patchUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'apikey': _apiKey,
        },
        body: jsonEncode({
          'verified_at': DateTime.now().toUtc().toIso8601String(),
        }),
      );

      return patchResponse.statusCode == 204 ? 200 : patchResponse.statusCode;
    } catch (e) {
      debugPrint('Signup OTP verification error: $e');
      return 0;
    }
  }

  /// registers a user or venue account from the restored signup flow.
  Future<int> signupAuthFlow({
    required String accountType,
    required String displayName,
    required String phone,
    required String password,
    required String city,
    File? profileImage,
  }) async {
    try {
      String photoUrl = "";
      if (profileImage != null) {
        photoUrl = await uploadProfilePhoto(profileImage, displayName) ?? "";
      }

      final String hashedPassword = sha256
          .convert(utf8.encode(password + salt))
          .toString();
      final Uri userUrl = Uri.parse('$_baseUrl/rest/v1/users');
      final Map<String, dynamic> userData = {
        'username': displayName,
        'phone': phone,
        'hash_psw': hashedPassword,
        'date_of_birth': '1900-01-01',
        'city': city,
        'profile_photo': photoUrl,
        'bio': '',
        'account_state': 'active',
        'account_type': accountType,
        'num_created_events': 0,
        'num_participated_events': 0,
        'language': StringRes.locale,
      };

      final userResponse = await http.post(
        userUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'apikey': _apiKey,
          'Prefer': 'return=representation',
        },
        body: jsonEncode(userData),
      );
      if (userResponse.statusCode != 200 && userResponse.statusCode != 201) {
        return userResponse.statusCode;
      }

      final List<dynamic> data = jsonDecode(userResponse.body);
      final String userId = data.isNotEmpty
          ? (data[0]['user_id'] ?? '').toString()
          : '';
      if (userId.isEmpty) return 0;

      if (accountType == 'venue') {
        final int venueResult = await _createVenueProfile(
          ownerId: userId,
          name: displayName,
          phone: phone,
          city: city,
          profilePhoto: photoUrl,
          hashPsw: hashedPassword,
        );
        if (venueResult != 200 && venueResult != 201) return venueResult;
      }

      await UserSession().startSession(
        userID: userId,
        locale: StringRes.locale,
        accountType: accountType,
        accountState: 'active',
      );
      await NotificationService().syncTokenForCurrentUser();
      return userResponse.statusCode;
    } catch (e) {
      debugPrint('Signup auth flow error: $e');
      return 0;
    }
  }

  /// creates the venue profile row linked to the auth user row.
  Future<int> _createVenueProfile({
    required String ownerId,
    required String name,
    required String phone,
    required String city,
    required String profilePhoto,
    required String hashPsw,
  }) async {
    final Uri venueUrl = Uri.parse('$_baseUrl/rest/v1/venues');
    final response = await http.post(
      venueUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
        'apikey': _apiKey,
        'Prefer': 'return=representation',
      },
      body: jsonEncode({
        'owner_id': ownerId,
        'name': name,
        'description': '',
        'phone': phone,
        'address': '',
        'city': city,
        'website_url': '',
        'instagram_url': '',
        'is_verified': true,
        'profile_photo': profilePhoto,
        'hash_psw': hashPsw,
      }),
    );
    return response.statusCode;
  }

  /// Registers a new user in the remote database
  Future<int> signup({
    required String phone,
    required String password,
    required String username,
    required DateTime dateOfBirth,
    required String city,
    File? profileImage,
  }) async {
    try {
      String photoUrl = "";
      if (profileImage != null) {
        photoUrl = await uploadProfilePhoto(profileImage, username) ?? "";
      }

      // STEP HASHING PSW //
      // password to byte with salt
      var bytes = utf8.encode(password + salt);
      // hash 256
      var digest = sha256.convert(bytes);
      String hashedPassword = digest.toString();
      // --------------- //

      // connection to the db
      debugPrint('Connecting to $_baseUrl to register user: $username');

      // 1. define the endpoint (table 'users' in 'Vez' DB)
      final url = Uri.parse('$_baseUrl/rest/v1/users');

      // 2. body of the request => the name on the right are the fields in the table
      final Map<String, dynamic> userData = {
        'username': username,
        'phone': phone,
        'hash_psw': hashedPassword, // hashed psw
        'date_of_birth':
            '${dateOfBirth.year.toString().padLeft(4, '0')}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}', // Date only (YYYY-MM-DD)
        'city': city,
        'profile_photo': photoUrl,
        'bio': "",
        'account_state': 'active',
        'account_type': 'user',
        'num_created_events': 0,
        'num_participated_events': 0,
        'language': StringRes.locale,
      };

      // 3. POST request
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey', // access token
          'apikey': _apiKey, // Supabase wants thi header
          'Prefer': 'return=representation', // return the created record
        },
        body: jsonEncode(userData),
      );

      // DEBUG: log the full response for diagnosis
      debugPrint('Signup response status: ${response.statusCode}');
      debugPrint('Signup response body: ${response.body}');
      debugPrint('Signup request payload: ${jsonEncode(userData)}');

      // success
      if (response.statusCode == 201 || response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          await UserSession().startSession(
            userID: data[0]['user_id']!.toString(),
            locale: StringRes.locale,
            accountType: (data[0]['account_type'] ?? 'user').toString(),
            accountState: (data[0]['account_state'] ?? 'active').toString(),
          );
          await NotificationService().syncTokenForCurrentUser();
        }
        return response.statusCode;
      }

      // any error
      return response.statusCode;
    } catch (e) {
      debugPrint('Signup error: $e');
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
      final url = Uri.parse(
        '$_baseUrl/rest/v1/users?username=eq.$username&hash_psw=eq.$hashedPassword&select=*',
      );

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_apiKey', 'apikey': _apiKey},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (data.isNotEmpty) {
          // Success

          String lan = data[0]['language']!.toString();
          await UserSession().startSession(
            userID: data[0]['user_id']!.toString(),
            locale: lan,
            accountType: (data[0]['account_type'] ?? 'user').toString(),
            accountState: (data[0]['account_state'] ?? 'active').toString(),
          );
          StringRes.setLocale(lan);
          await NotificationService().syncTokenForCurrentUser();

          return 200;
        } else {
          return 401;
        } // Unauthorized
      } else {
        return response.statusCode;
      }
    } catch (e) {
      return 0;
    }
  }

  Future<int> signupVenue({
    required String username,
    required String email,
    required String password,
    required String venueName,
    required String legalName,
    required String vatNumber,
    required String address,
    required String city,
    required String country,
    required String publicEmail,
    required String publicPhone,
    required String websiteUrl,
    required String instagramUrl,
  }) async {
    try {
      // 1. define the endpoint (table 'venues' in 'Vez' DB)
      final url = Uri.parse('$_baseUrl/functions/v1/venues');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'apikey': _apiKey,
        },
        // todo: change all the fields
        body: jsonEncode({
          'username': username,
          'phone': email,
          'password': password,
          'language': StringRes.locale,
          'venue_name': venueName,
          'legal_name': legalName,
          'vat_number': vatNumber,
          'address': address,
          'city': city,
          'country': country,
          'public_email': publicEmail,
          'public_phone': publicPhone,
          'website_url': websiteUrl,
          'instagram_url': instagramUrl,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        await UserSession().startSession(
          userID: (data['user_id'] ?? '').toString(),
          locale: StringRes.locale,
          accountType: 'venue',
          accountState: 'pending_verification',
        );
        await NotificationService().syncTokenForCurrentUser();
      }

      return response.statusCode;
    } catch (_) {
      return 0;
    }
  }

  Future<int> verifyVenueCode(String code) async {
    try {
      final url = Uri.parse('$_baseUrl/functions/v1/verify-venue-code');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'apikey': _apiKey,
        },
        body: jsonEncode({
          'user_id': UserSession().userID,
          'verification_code': code.trim().toUpperCase(),
        }),
      );

      if (response.statusCode == 200) {
        await UserSession().updateAccountStatus(
          accountType: 'venue',
          accountState: 'pending_verification',
        );
      }

      return response.statusCode;
    } catch (_) {
      return 0;
    }
  }

  Future<void> refreshCurrentAccountStatus() async {
    final String userId = UserSession().userID;
    if (userId.isEmpty) return;

    try {
      final url = Uri.parse(
        '$_baseUrl/rest/v1/users'
        '?user_id=eq.$userId'
        '&select=account_type,account_state'
        '&limit=1',
      );
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_apiKey', 'apikey': _apiKey},
      );
      if (response.statusCode != 200) return;
      final List<dynamic> data = jsonDecode(response.body);
      if (data.isEmpty) return;
      await UserSession().updateAccountStatus(
        accountType: (data[0]['account_type'] ?? 'user').toString(),
        accountState: (data[0]['account_state'] ?? 'active').toString(),
      );
    } catch (_) {}
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
      } else {
        // This will tell you if the file was too large (413 Payload Too Large)
        debugPrint('Upload failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Errore upload: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await UserSession().clearSession();
  }
}
