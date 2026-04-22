// services/user_session.dart

// global userID var
String userID = "";

class UserSession {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  String userID = "";
  String profilePic = "assets/icons/home_page/icon_profile.png";
  String locale = 'en'; // default language, updated on app start
}