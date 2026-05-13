// account_type.dart

import '../services/translation_service.dart';

enum AccountType {
  user,
  venue,
}

extension AccountTypeData on AccountType {
  // UI
  String get title => this == AccountType.user
      ? StringRes.at('user_signup_title')
      : StringRes.at('venue_signup_title');

  String get subtitle => this == AccountType.user
      ? StringRes.at('user_signup_subtitle')
      : StringRes.at('venue_signup_subtitle');

  String get backgroundAsset => this == AccountType.user
      ? 'assets/images/bg/user_signup.jpg'
      : 'assets/images/bg/venue_signup.jpg';

  String get nameHint => this == AccountType.user
      ? StringRes.at('username')
      : StringRes.at('venue_name');

  // DB
  String get dbValue => this.name; // 🔥 "user" o "venue"

  static AccountType fromString(String value) {
    return value == 'venue' ? AccountType.venue : AccountType.user;
  }
}