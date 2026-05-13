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
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vez/services/notification_service.dart';
import 'package:vez/services/translation_service.dart';
import 'package:vez/services/user_session.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/account_type.dart';
import 'api_keys.dart'; // private key to connect to the remote db

class RemoteDbService {
  static const bool _useSupabaseAuthUserId = false;

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
          String lan = data[0]['language']!.toString();

          await UserSession().startSession(
            userID: data[0]['user_id']!.toString(),
            locale: lan,
            accountType: accountTypeFromString(
              (data[0]['type'] ?? 'user').toString(),
            ),
            accountState: (data[0]['state'] ?? 'active').toString(),
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

  /// Logout a user from the local device
  Future<void> logout() async {
    final notificationService = NotificationService();

    try {
      // ======================================
      // 1. 🔥 RIMUOVI TOKEN DAL BACKEND
      // ======================================
      // Se non lo fai → il server continuerà a mandare notifiche
      await notificationService.removeTokenForCurrentUser();

      // ======================================
      // 2. 🔥 ELIMINA TOKEN DAL DISPOSITIVO
      // ======================================
      // Questo invalida completamente Firebase per questo device
      await FirebaseMessaging.instance.deleteToken();

      // ======================================
      // 3. 🔥 STOP LISTENER NOTIFICHE
      // ======================================
      // Evita che il token venga ri-salvato automaticamente
      await notificationService.dispose();

      // ======================================
      // 4. 🔥 CLEAR SESSION LOCALE
      // ======================================
      // Cancella SharedPreferences + memoria singleton
      await UserSession().clearSession();
    } catch (e) {
      debugPrint('Logout error: $e');
    }

    // ======================================
    // ⚠️ NOTA IMPORTANTE
    // ======================================
    // NON gestisco la navigazione qui.
    // Questo service NON deve conoscere la UI.
    //
    // 👉 La UI deve fare:
    // await RemoteDbService().logout();
    // Navigator.pushAndRemoveUntil(...);
  }

  /// Registers a new user in the remote database
  Future<int> signup({
    File? profileImage,
    required String username,
    required String phone,
    required String password,
    required String city,
  }) async {
    try {
      String photoUrl = "";
      if (profileImage != null) {
        photoUrl =
            await uploadProfilePhoto("avatars", profileImage, username) ?? "";
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
        'profile_photo': photoUrl,
        'username': username,
        'phone': phone,
        'hash_psw': hashedPassword, // hashed psw
        'city': city,
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
            accountType: accountTypeFromString(
              (data[0]['type'] ?? 'user').toString(),
            ),
            accountState: (data[0]['state'] ?? 'active').toString(),
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

  /// Registers a new venue in the remote database
  Future<int> signupVenue({
    File? profileImage,
    required String name,
    required String phone,
    required String password,
    required String city,
    required String websiteUrl,
    required String instagramUrl,
  }) async {
    try {
      String photoUrl = "";
      if (profileImage != null) {
        photoUrl =
            await uploadProfilePhoto("avatars_venues", profileImage, name) ??
            "";
      }

      // STEP HASHING PSW //
      // password to byte with salt
      var bytes = utf8.encode(password + salt);
      // hash 256
      var digest = sha256.convert(bytes);
      String hashedPassword = digest.toString();
      // --------------- //

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
          'profile_photo': photoUrl,
          'name': name,
          'phone': phone,
          'password': hashedPassword, // hashed psw
          'language': StringRes.locale,
          'city': city,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        await UserSession().startSession(
          userID: (data['user_id'] ?? '').toString(),
          locale: StringRes.locale,
          accountType: AccountType.venue,
          accountState: 'pending_verification',
        );
        await NotificationService().syncTokenForCurrentUser();
      }

      return response.statusCode;
    } catch (_) {
      return 0;
    }
  }

  /// Verify the identity of a venue -> if it fails the account is suspended
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
          accountType: AccountType.venue,
          accountState: 'pending_verification',
        );
      }

      return response.statusCode;
    } catch (_) {
      return 0;
    }
  }

  Future<int> completeSignup({
    required AccountType accountType,
    required String username,
    required String phone,
    required String password,
    required String city,
    File? profileImage,
  }) async {
    try {
      final type = accountType.name;

      final state = accountType == AccountType.venue
          ? 'pending_verification'
          : 'active';

      String? authUserId;
      if (_useSupabaseAuthUserId) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) return 500;
        authUserId = user.id;
      }

      // 🔐 hash password
      final bytes = utf8.encode(password + salt);
      final hashedPassword = sha256.convert(bytes).toString();

      // 📸 upload immagine
      String photoUrl = '';
      if (profileImage != null) {
        photoUrl =
            await uploadProfilePhoto("avatars", profileImage, username) ?? '';
      }

      // 🧱 CREA USER BASE
      final userData = {
        'username': username,
        'phone': phone,
        'hash_psw': hashedPassword,
        'city': city,
        'language': StringRes.locale,
        'profile_photo': photoUrl,
        'type': type,
        'state': state,
      };
      if (authUserId != null) {
        userData['user_id'] = authUserId;
      }

      final userRes = await http.post(
        Uri.parse('$_baseUrl/rest/v1/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'apikey': _apiKey,
          'Prefer': 'return=representation',
        },
        body: jsonEncode(userData),
      );

      if (userRes.statusCode != 201 && userRes.statusCode != 200) {
        return userRes.statusCode;
      }

      final data = jsonDecode(userRes.body);
      if (data is! List || data.isEmpty) return 500;
      final String userId = (data.first['user_id'] ?? '').toString();
      if (userId.isEmpty) return 500;

      // 🏢 CREA VENUE EXTRA
      if (accountType == AccountType.venue) {
        await http.post(
          Uri.parse('$_baseUrl/rest/v1/venues'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
            'apikey': _apiKey,
          },
          body: jsonEncode({'venue_id': userId, 'owner_id': userId}),
        );
      }

      // 💾 SESSION
      await UserSession().startSession(
        userID: userId,
        locale: StringRes.locale,
        accountType: accountType == AccountType.venue
            ? AccountType.venue
            : AccountType.user,
        accountState: userData['state'] as String,
      );

      await NotificationService().syncTokenForCurrentUser();

      return 201;
    } catch (e) {
      debugPrint('Complete signup error: $e');
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
        '&select=type,state'
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
        accountType: accountTypeFromString(
          (data[0]['type'] ?? 'user').toString(),
        ),
        accountState: (data[0]['state'] ?? 'active').toString(),
      );
    } catch (_) {}
  }

  // method to upload a file (profile photo)
  Future<String?> uploadProfilePhoto(
    String bucketName,
    File imageFile,
    String username,
  ) async {
    try {
      final fileName = '$username-${DateTime.now().millisecondsSinceEpoch}.jpg';
      final url = Uri.parse(
        '$_baseUrl/storage/v1/object/$bucketName/$fileName',
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

  AccountType accountTypeFromString(String type) {
    switch (type) {
      case 'venue':
        return AccountType.venue;
      case 'user':
      default:
        return AccountType.user;
    }
  }
}
