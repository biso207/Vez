// services/user_session.dart

// Questa è la variabile globale "neutra"
String userID = "";

// Se vuoi essere ancora più pulito, usa una classe Singleton
class UserSession {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  String userID = "";
  String profilePic = "assets/icons/home_page/icon_profile.png";
}