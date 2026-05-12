// Developed and Designed by Outly • 2026
// signup account type model used by the authentication flow.

import '../services/translation_service.dart';

// describes the two supported signup paths.
enum SignupAccountType { user, venue }

// exposes presentation and storage metadata for a signup account type.
extension SignupAccountTypeData on SignupAccountType {
  // returns the localized title for the signup flow.
  String get title => this == SignupAccountType.user
      ? StringRes.at('user_signup_title')
      : StringRes.at('venue_signup_title');

  // returns the localized subtitle for the signup flow.
  String get subtitle => this == SignupAccountType.user
      ? StringRes.at('user_signup_subtitle')
      : StringRes.at('venue_signup_subtitle');

  // returns the background image used by the signup flow.
  String get backgroundAsset => this == SignupAccountType.user
      ? 'assets/images/bg/user_signup.jpg'
      : 'assets/images/bg/venue_signup.jpg';

  // returns the account type value stored in the database.
  String get dbValue => this == SignupAccountType.user ? 'user' : 'venue';

  // returns the localized name field hint.
  String get nameHint => this == SignupAccountType.user
      ? StringRes.at('username')
      : StringRes.at('venue_name');
}
