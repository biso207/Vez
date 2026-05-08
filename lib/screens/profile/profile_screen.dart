// developed and designed by Outly • © 2026
// profile screen : zone-2 content: user info card + stats pill + event grid.
//
// layout zones used:
//   zone 1 : background  : kBgColor from VezPageLayout
//   zone 2 : body        : SingleChildScrollView anchored from top
//   zone 3 : blur veil   : handled by VezPageLayout
//   zone 4 : navbars     : settings / search / follow-requests + bottom pill
//
// top-bar left button = settings icon which opens the settings popup (full glass panel).
//   the settings popup replaces the old standalone language popup and groups
//   all user preferences (language, badge toggle, etc.) in one place.
//
// top-bar left button on profile screen is intentionally NOT a profile avatar;
//   the settings icon is used instead since the user is already viewing their profile.
//
// file structure (part system – all files share this library):
//   profile_screen.dart            ← this file (page + state + popup logic)
//   profile_card_widgets.dart      ← user card, avatar badge, stats pill
//   profile_nav_widgets.dart       ← bottom nav pill
//   profile_popup_widgets.dart     ← shared micro-widgets used inside popups
//   profile_settings_widgets.dart  ← settings section, badge toggle, account buttons
//   profile_past_events_widgets.dart ← past events button, rows, fallback image

// ─── dart / flutter imports ───────────────────────────────────────────────────

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// ─── app service imports ──────────────────────────────────────────────────────

import '../../views/widgets/vez_glass.dart';
import '../../services/auth_service.dart';
import '../../services/getters_service.dart';
import '../../services/haptic_service.dart';
import '../../services/setters_service.dart';
import '../../services/translation_service.dart';
import '../../services/user_session.dart';

// ─── app widget imports ───────────────────────────────────────────────────────

import '../../views/widgets/vez_coach_marks.dart';
import '../../views/widgets/vez_glass.dart';
import '../../views/widgets/vez_page_layout.dart';
import '../../views/widgets/vez_popup.dart';

// ─── screen imports ───────────────────────────────────────────────────────────

import '../auth/login_screen.dart';
import '../create_event/create_event_screen.dart';
import '../notifications_screen.dart';

// ─── part files (share this library namespace) ────────────────────────────────

part 'profile_card_widgets.dart';
part 'profile_nav_widgets.dart';
part 'profile_popup_widgets.dart';
part 'profile_settings_widgets.dart';
part 'profile_past_events_widgets.dart';

// ─── constants ────────────────────────────────────────────────────────────────

const double kBlurValue = 5.0;

// ─────────────────────────────────────────────────────────────────────────────
// profile page
// ─────────────────────────────────────────────────────────────────────────────

/// entry point widget for the profile screen.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.showTutorial = false});

  final bool showTutorial;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

// ─────────────────────────────────────────────────────────────────────────────
// profile page state
// manages user data, profile edits, settings popups, and account actions.
// ─────────────────────────────────────────────────────────────────────────────

class _ProfilePageState extends State<ProfilePage> {
  // ── controllers & services ─────────────────────────────────────────────────

  final TextEditingController _searchController    = TextEditingController();
  final TextEditingController _usernameCtrl        = TextEditingController();
  final TextEditingController _passwordCtrl        = TextEditingController();
  final TextEditingController _currentPasswordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();
  final TextEditingController _deleteAccountCtrl   = TextEditingController();
  final TextEditingController _cityAkaNameCtrl     = TextEditingController();
  final TextEditingController _bioCtrl             = TextEditingController();

  final ImagePicker    _picker = ImagePicker();
  final RemoteDbService _remote = RemoteDbService();

  late final GetDBService _dbGet;
  late final SetDBService _dbSet;

  // ── user data state ────────────────────────────────────────────────────────

  String _profilePhoto          = '';
  String _username              = '';
  String _city                  = '';
  String _cityAkaName           = '';
  String _bio                   = '';
  int    _numFollowers          = 0;
  int    _numFollowing          = 0;
  int    _numParticipatedEvents = 0;

  List<Map<String, dynamic>> _pastCreatedEvents     = const [];
  List<Map<String, dynamic>> _pastParticipatedEvents = const [];

  // ── ui flags ───────────────────────────────────────────────────────────────

  bool   _showBadge            = true;
  bool   _showPassword         = false;
  bool   _showCurrentPassword  = false;
  bool   _showConfirmPassword  = false;
  File?  _newProfileImage;
  String? _popupError;

  // ── static data: supported languages ──────────────────────────────────────

  static const List<Map<String, String>> _languages = [
    {
      'code': 'en',
      'name': 'lang_en',
      'icon': 'assets/icons/profile_page/flags/en_flag.png',
    },
    {
      'code': 'de',
      'name': 'lang_de',
      'icon': 'assets/icons/profile_page/flags/de_flag.png',
    },
    {
      'code': 'fr',
      'name': 'lang_fr',
      'icon': 'assets/icons/profile_page/flags/fr_flag.png',
    },
    {
      'code': 'it',
      'name': 'lang_it',
      'icon': 'assets/icons/profile_page/flags/it_flag.png',
    },
    {
      'code': 'es',
      'name': 'lang_es',
      'icon': 'assets/icons/profile_page/flags/es_flag.png',
    },
    {
      'code': 'zh',
      'name': 'lang_zh',
      'icon': 'assets/icons/profile_page/flags/zh_flag.png',
    },
  ];

  // ── lifecycle ──────────────────────────────────────────────────────────────

  /// initializes db services and kicks off user data loading.
  @override
  void initState() {
    super.initState();
    final String uid = UserSession().userID;
    if (uid.isNotEmpty) {
      _dbGet = GetDBService(userID: uid);
      _dbSet = SetDBService(userID: uid);
      _loadUserData();
    }

    if (widget.showTutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runTutorial());
    }
  }

  /// disposes all text editing controllers on widget removal.
  @override
  void dispose() {
    _searchController.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _deleteAccountCtrl.dispose();
    _cityAkaNameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  // ── validation helpers ─────────────────────────────────────────────────────

  /// returns true if the username field satisfies minimum length requirements.
  bool get _isValid =>
      _usernameCtrl.text.trim().isNotEmpty &&
      _usernameCtrl.text.trim().length >= 4;

  /// validates that a password meets all security requirements.
  bool _isStrongPassword(String password) {
    return password.length >= 12 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[!@#$&*~£€?§+._-]').hasMatch(password);
  }

  // ── data loading ───────────────────────────────────────────────────────────

  /// fetches all user profile data in parallel to reduce load time.
  Future<void> _loadUserData() async {
    // parallel network calls to reduce page loading time
    final results = await Future.wait([
      _dbGet.getFullUserData(),
      _dbGet.getFollowersCount(),
      _dbGet.getFollowing(),
      _dbGet.getExpiredCreatedEvents(),
      _dbGet.getExpiredParticipatedEvents(),
    ]);

    if (!mounted) return;

    // extract positional results from Future.wait
    final userData        = results[0] as Map<String, dynamic>?;
    final followersCount  = results[1] as int;
    final followingList   = results[2] as List<Map<String, dynamic>>;
    final pastCreated     = results[3] as List<Map<String, dynamic>>;
    final pastParticipated = results[4] as List<Map<String, dynamic>>;

    setState(() {
      _profilePhoto  = (userData?['profile_photo'] as String?)?.trim() ?? '';
      _username      = userData?['username']   as String? ?? 'Username';
      _city          = userData?['city']        as String? ?? StringRes.at('city');

      final akaName  = userData?['city_aka_name'] as String?;
      _cityAkaName   = akaName?.trim().isNotEmpty == true ? '$akaName • ' : '';

      _bio           = userData?['bio'] as String? ?? StringRes.at('bio');

      // category_badge is stored as Bool in db
      _showBadge     = userData?['category_badge'] as bool? ?? true;

      // num_participated_events is derived from list length (not a db column)
      _numParticipatedEvents = pastParticipated.length;

      _numFollowers          = followersCount;
      _numFollowing          = followingList.length;
      _pastCreatedEvents     = pastCreated;
      _pastParticipatedEvents = pastParticipated;
    });
  }

  /// starts the coach-mark tutorial and pops the route once complete.
  Future<void> _runTutorial() async {
    if (!mounted) return;
    final bool completed = await VezCoachMarks.showProfileTutorial(context);
    if (!mounted) return;
    Navigator.pop(context, completed);
  }

  // ── profile save ───────────────────────────────────────────────────────────

  /// commits username, aka-name, bio, badge, and optional photo to the db.
  Future<void> _saveProfileData(StateSetter setPopupState) async {
    final String uName   = _usernameCtrl.text.trim();
    final String akaName = _cityAkaNameCtrl.text.trim();
    final String bio     = _bioCtrl.text.trim();

    if (uName != _username && uName.length >= 4) {
      final int res = await _dbSet.updateUserData('username', uName);
      if (res == 409) {
        setPopupState(() => _popupError = StringRes.at('user_already_exists'));
        return;
      }
      setState(() => _username = uName);
    }

    _dbSet.updateUserData('city_aka_name', akaName);
    _dbSet.updateUserData('bio', bio);
    _dbSet.updateUserData('category_badge', _showBadge);

    if (_newProfileImage != null) {
      final String? url = await _remote.uploadProfilePhoto(
        _newProfileImage!,
        _username,
      );
      if (url != null) {
        _dbSet.updateUserData('profile_photo', url);
        setState(() => _profilePhoto = url);
      }
    }

    setState(() {
      _cityAkaName = akaName;
      _bio         = bio;
    });
  }

  // ── navigation helpers ─────────────────────────────────────────────────────

  /// pops back to the first route (home screen).
  void _goToHome() {
    HapticService.tap();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  /// navigates to the create-event screen and refreshes home on success.
  void _goToCreateEvent() {
    HapticService.tap();
    Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateEvent()),
    ).then((changed) {
      if (changed == true && mounted) {
        _goToHome();
      }
    });
  }

  /// navigates to the notifications screen.
  void _goToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
  }

  // ── popup helpers ──────────────────────────────────────────────────────────

  /// resets all popup-related controllers and error state between sessions.
  void _clearPopupControllers() {
    _usernameCtrl.clear();
    _passwordCtrl.clear();
    _currentPasswordCtrl.clear();
    _confirmPasswordCtrl.clear();
    _deleteAccountCtrl.clear();
    _cityAkaNameCtrl.clear();
    _bioCtrl.clear();
    _showPassword        = false;
    _showCurrentPassword = false;
    _showConfirmPassword = false;
    _popupError          = null;
  }

  // ── account actions ────────────────────────────────────────────────────────

  /// validates fields and triggers the secure password update flow.
  Future<void> _handlePasswordChange(StateSetter setPopupState) async {
    final String currentPassword = _currentPasswordCtrl.text;
    final String newPassword     = _passwordCtrl.text;
    final String confirmPassword = _confirmPasswordCtrl.text;

    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      setPopupState(() => _popupError = StringRes.at('complete_all_fields'));
      return;
    }

    if (newPassword != confirmPassword) {
      setPopupState(() => _popupError = StringRes.at('passwords_do_not_match'));
      return;
    }

    if (!_isStrongPassword(newPassword)) {
      setPopupState(() => _popupError = StringRes.at('invalid_password'));
      return;
    }

    final int res = await _dbSet.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    if (res == 200 || res == 204) {
      if (!mounted) return;
      Navigator.pop(context);
      _clearPopupControllers();
      return;
    }

    setPopupState(
      () => _popupError = res == 401
          ? StringRes.at('wrong_current_password')
          : StringRes.at('password_change_failed'),
    );
  }

  /// validates username confirmation then permanently deletes the account.
  Future<void> _handleAccountDeletion(StateSetter setPopupState) async {
    final String typedUsername = _deleteAccountCtrl.text.trim();
    if (typedUsername != _username) {
      setPopupState(() => _popupError = StringRes.at('username_confirm_failed'));
      return;
    }

    final int res = await _dbSet.deleteCurrentUserAccount(
      profilePhotoUrl: _profilePhoto,
    );

    if (res == 200 || res == 204) {
      await _remote.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
      _clearPopupControllers();
      return;
    }

    setPopupState(() => _popupError = StringRes.at('account_delete_failed'));
  }

  /// triggers logout with haptic feedback and dismisses the settings popup.
  void _handleLogout() {
    HapticService.emphasis();
    Navigator.pop(context);
    _logoutAndRedirect();
  }

  /// clears the session and pushes the login screen, removing all routes.
  Future<void> _logoutAndRedirect() async {
    await _remote.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  // ── date formatting ────────────────────────────────────────────────────────

  /// formats a raw ISO date string to dd/mm/yyyy - hh:mm local time.
  String _formatPastEventDate(String raw) {
    final date = DateTime.tryParse(raw)?.toLocal();
    if (date == null) return '';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}'
        ' - ${two(date.hour)}:${two(date.minute)}';
  }

  // ── popup builders ─────────────────────────────────────────────────────────

  /// opens a scrollable list of archived past events in a popup.
  void _showPastEventsPopup(String title, List<Map<String, dynamic>> events) {
    VezPopup.show(
      context: context,
      width: MediaQuery.of(context).size.width * 0.86,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PastEventsPopupHeader(title: title, count: events.length),
              const SizedBox(height: 16),
              if (events.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    children: [
                      Icon(
                        Icons.hourglass_empty_rounded,
                        color: Colors.white54,
                        size: 34,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Nessun Evento',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 4),
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _PastEventRow(
                      event: events[index],
                      date: _formatPastEventDate(
                        events[index]['date_event']?.toString() ?? '',
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// opens the full settings panel (language, display prefs, account actions).
  void _showSettingsPopup(double s) {
    VezPopup.show(
      context: context,
      width: MediaQuery.of(context).size.width * 0.85,
      child: StatefulBuilder(
        builder: (ctx, setPopupState) => SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20 * s),

              // settings title row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const ImageIcon(
                      AssetImage('assets/icons/profile_page/settings.png'),
                      color: Colors.white,
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      StringRes.at('settings'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20 * s),

              // ── section: language ────────────────────────────────────────
              _SettingsSection(
                label: StringRes.at('select_language'),
                iconPath: 'assets/icons/profile_page/language.png',
                child: Builder(
                  builder: (context) {
                    final currentLang = _languages.firstWhere(
                      (lang) => lang['code'] == StringRes.locale,
                      orElse: () => _languages.first,
                    );

                    return GestureDetector(
                      onTap: () => _showLanguageSelector(
                        onLanguageChanged: () {
                          setPopupState(() {});
                          if (mounted) setState(() {});
                        },
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              currentLang['icon']!,
                              width: 24,
                              height: 24,
                            ),
                            const SizedBox(width: 15),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  StringRes.at(currentLang['name']!),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  StringRes.at('click_to_change'),
                                  style: const TextStyle(
                                    color: Color.fromARGB(128, 255, 255, 255),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Color.fromARGB(128, 255, 255, 255),
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 14 * s),

              // ── section: display preferences ─────────────────────────────
              _SettingsSection(
                label: StringRes.at('display'),
                iconPath: 'assets/icons/profile_page/general_settings.png',
                child: _BadgeToggleRow(
                  s: s,
                  value: _showBadge,
                  onChanged: (val) {
                    HapticService.selection();
                    setPopupState(() => _showBadge = val);
                    setState(() => _showBadge = val);
                    _dbSet.updateUserData('category_badge', val);
                  },
                ),
              ),

              SizedBox(height: 14 * s),

              // ── section: account ─────────────────────────────────────────
              _SettingsSection(
                label: StringRes.at('account'),
                iconPath: 'assets/icons/profile_page/account.png',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _AccountActionButton(
                      s: s,
                      label: StringRes.at('change_password'),
                      iconPath: 'assets/icons/profile_page/settings.png',
                      color: Colors.white,
                      backgroundColor: const Color.fromARGB(50, 255, 255, 255),
                      borderColor: const Color.fromARGB(128, 255, 255, 255),
                      onTap: () => _showChangePasswordPopup(s),
                    ),
                    SizedBox(height: 10 * s),
                    _AccountActions(s: s, onLogout: _handleLogout),
                    SizedBox(height: 10 * s),
                    _AccountActionButton(
                      s: s,
                      label: StringRes.at('delete_account'),
                      iconPath: 'assets/icons/profile_page/delete.png',
                      color: const Color(0xFFFF3131),
                      backgroundColor: const Color.fromARGB(40, 255, 49, 49),
                      borderColor: const Color.fromARGB(100, 255, 49, 49),
                      onTap: () => _showDeleteAccountPopup(s),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20 * s),

              // close button
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(50, 255, 255, 255),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: const Color.fromARGB(128, 255, 255, 255),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      StringRes.at('close'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20 * s),
            ],
          ),
        ),
      ),
    );
  }

  /// opens the edit-profile popup (avatar, username, aka-name, bio).
  void _showEditProfilePopup(double s) {
    _usernameCtrl.text    = _username;
    _cityAkaNameCtrl.text = _cityAkaName.replaceAll(' • ', '');
    _bioCtrl.text         = _bio;

    VezPopup.show(
      context: context,
      width: MediaQuery.of(context).size.width * 0.85,
      child: StatefulBuilder(
        builder: (ctx, setPopupState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 24 * s),

              // profile photo picker
              GestureDetector(
                onTap: () async {
                  final XFile? file = await _picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 512,
                    maxHeight: 512,
                    imageQuality: 75,
                  );
                  if (file != null) {
                    setPopupState(() => _newProfileImage = File(file.path));
                  }
                },
                child: _AvatarPicker(
                  newImage: _newProfileImage,
                  networkPhoto: _profilePhoto,
                ),
              ),

              SizedBox(height: 24 * s),

              // username field
              _PopupInput(
                hint: StringRes.at('edit_username'),
                controller: _usernameCtrl,
                maxLength: 15,
                onChanged: (_) => setPopupState(() {}),
              ),

              // city aka-name field
              _PopupInput(
                hint: StringRes.at('city_aka_name'),
                controller: _cityAkaNameCtrl,
                maxLength: 10,
                onChanged: (_) => setPopupState(() {}),
              ),

              // bio field
              _PopupInput(
                hint: StringRes.at('bio'),
                controller: _bioCtrl,
                maxLength: 30,
                onChanged: (_) => setPopupState(() {}),
              ),

              SizedBox(height: 24 * s),

              // error banner
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                child: _popupError != null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: VezErrorBanner(message: _popupError!),
                      )
                    : const SizedBox.shrink(),
              ),

              if (_popupError != null) SizedBox(height: 16 * s),

              // save / discard buttons
              _SaveDiscardRow(
                isValid: _isValid,
                s: s,
                onSave: () async {
                  HapticService.success();
                  await _saveProfileData(setPopupState);
                  if (!mounted) return;
                  Navigator.pop(context);
                  _clearPopupControllers();
                },
                onDiscard: () {
                  HapticService.emphasis();
                  Navigator.pop(context);
                  _clearPopupControllers();
                  setState(() => _popupError = null);
                },
              ),

              SizedBox(height: 24 * s),
            ],
          ),
        ),
      ),
    );
  }

  /// opens the change-password popup with current / new / confirm fields.
  void _showChangePasswordPopup(double s) {
    _clearPopupControllers();

    VezPopup.show(
      context: context,
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: const Color.fromARGB(51, 0, 0, 0),
      borderColor: const Color.fromARGB(128, 255, 255, 255),
      child: StatefulBuilder(
        builder: (ctx, setPopupState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 24 * s),
              _PopupTitle(text: StringRes.at('change_password')),
              SizedBox(height: 16 * s),

              // current password field
              _PopupInput(
                hint: StringRes.at('current_password'),
                controller: _currentPasswordCtrl,
                obscure: !_showCurrentPassword,
                onChanged: (_) => setPopupState(() => _popupError = null),
                suffixIcon: _PasswordVisibilityToggle(
                  visible: _showCurrentPassword,
                  onTap: () => setPopupState(
                    () => _showCurrentPassword = !_showCurrentPassword,
                  ),
                ),
              ),

              // new password field
              _PopupInput(
                hint: StringRes.at('new_password'),
                controller: _passwordCtrl,
                obscure: !_showPassword,
                onChanged: (_) => setPopupState(() => _popupError = null),
                suffixIcon: _PasswordVisibilityToggle(
                  visible: _showPassword,
                  onTap: () => setPopupState(() => _showPassword = !_showPassword),
                ),
              ),

              // confirm password field
              _PopupInput(
                hint: StringRes.at('confirm_password'),
                controller: _confirmPasswordCtrl,
                obscure: !_showConfirmPassword,
                onChanged: (_) => setPopupState(() => _popupError = null),
                suffixIcon: _PasswordVisibilityToggle(
                  visible: _showConfirmPassword,
                  onTap: () => setPopupState(
                    () => _showConfirmPassword = !_showConfirmPassword,
                  ),
                ),
              ),

              // inline error banner
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                child: _popupError != null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: VezErrorBanner(message: _popupError!),
                      )
                    : const SizedBox.shrink(),
              ),

              if (_popupError != null) SizedBox(height: 16 * s),

              // confirm / cancel buttons
              _ConfirmCancelRow(
                s: s,
                onConfirm: () async {
                  HapticService.success();
                  await _handlePasswordChange(setPopupState);
                },
                onCancel: () {
                  HapticService.emphasis();
                  Navigator.pop(context);
                  _clearPopupControllers();
                },
              ),

              SizedBox(height: 24 * s),
            ],
          ),
        ),
      ),
    );
  }

  /// opens the destructive delete-account popup with username confirmation.
  void _showDeleteAccountPopup(double s) {
    _clearPopupControllers();

    VezPopup.show(
      context: context,
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: const Color.fromARGB(51, 0, 0, 0),
      borderColor: const Color.fromARGB(128, 255, 255, 255),
      child: StatefulBuilder(
        builder: (ctx, setPopupState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 24 * s),

              _PopupTitle(text: StringRes.at('delete_account')),

              // confirmation message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  StringRes.at('delete_account_confirm_message')
                      .replaceAll('{username}', _username),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              SizedBox(height: 16 * s),

              // username confirmation field
              _PopupInput(
                hint: _username,
                controller: _deleteAccountCtrl,
                onChanged: (_) => setPopupState(() => _popupError = null),
              ),

              // inline error banner
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                child: _popupError != null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: VezErrorBanner(message: _popupError!),
                      )
                    : const SizedBox.shrink(),
              ),

              if (_popupError != null) SizedBox(height: 16 * s),

              // confirm (red) / cancel buttons
              _ConfirmCancelRow(
                s: s,
                confirmEnabled:
                    _deleteAccountCtrl.text.trim() == _username,
                confirmColor:
                    const Color.fromARGB(128, 255, 49, 49),
                confirmBorder:
                    const Color.fromARGB(204, 255, 49, 49),
                onConfirm: () async {
                  HapticService.emphasis();
                  await _handleAccountDeletion(setPopupState);
                },
                onCancel: () {
                  HapticService.selection();
                  Navigator.pop(context);
                  _clearPopupControllers();
                },
              ),

              SizedBox(height: 24 * s),
            ],
          ),
        ),
      ),
    );
  }

  /// opens the language picker popup nested inside the settings panel.
  void _showLanguageSelector({VoidCallback? onLanguageChanged}) {
    final double pw = MediaQuery.of(context).size.width * 0.50;
    final double ph = (_languages.length * 50.0).clamp(
      100.0,
      MediaQuery.of(context).size.height * 0.8,
    );

    VezPopup.show(
      context: context,
      width: pw,
      height: ph,
      backgroundColor: const Color.fromARGB(128, 6, 0, 92),
      borderColor: const Color.fromARGB(128, 0, 10, 218),
      child: ListView.separated(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.zero,
        itemCount: _languages.length,
        separatorBuilder: (_, __) => _PopupDivider(width: pw),
        itemBuilder: (context, i) {
          final String code     = _languages[i]['code']!;
          final String name     = _languages[i]['name']!;
          final String iconPath = _languages[i]['icon']!;
          final bool isSelected = StringRes.locale == code;

          return GestureDetector(
            onTap: () async {
              final navigator = Navigator.of(context);
              final int res =
                  await _dbSet.updateUserData('language', code);

              if (res == 200 || res == 204) {
                HapticService.selection();
                StringRes.setLocale(code);
                onLanguageChanged?.call();
                if (mounted) setState(() {});
              }

              if (navigator.canPop()) navigator.pop();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              child: Row(
                children: [
                  Image.asset(
                    iconPath,
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    StringRes.at(name),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    const ImageIcon(
                      AssetImage('assets/icons/profile_page/confirm.png'),
                      color: Colors.white,
                      size: 18,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────

  /// assembles the main profile view with top/bottom navbars and body content.
  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final double s  = (sw / 390).clamp(0.8, 1.2);

    return VezPageLayout(
      // ── top navbar ─────────────────────────────────────────────────────────

      searchController: _searchController,
      searchHint: StringRes.at('search'),

      // left: settings icon → opens settings popup
      profileIconPath: 'assets/icons/profile_page/settings.png',
      isProfileAvatar: false,
      onProfileTap: () {
        HapticService.emphasis();
        _showSettingsPopup(s);
      },

      // right: edit icon → opens edit-profile popup
      filterIconPath:  'assets/icons/event/edit.png',
      isFilterSelected: false,
      onFilterTap: () {
        HapticService.emphasis();
        _showEditProfilePopup(s);
      },
      onFilterSelected: null,

      // ── bottom navbar ──────────────────────────────────────────────────────

      bottomNavBar: _BottomNavPill(
        s: s,
        activeIndex: -1,
        onHomeTap: _goToHome,
        onCreateEventTap: _goToCreateEvent,
        onNotificationsTap: _goToNotifications,
      ),

      // ── zone-2 body: scrollable profile content ────────────────────────────

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // top spacer to clear the navbar + blur veil
            SizedBox(height: 130 * s),

            // user info card
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 5 * s),
              child: _UserCard(
                s: s,
                profilePhoto: _profilePhoto,
                username: _username,
                cityAkaName: _cityAkaName,
                city: _city,
                bio: _bio,
                showBadge: _showBadge,
              ),
            ),

            SizedBox(height: 16 * s),

            // stats pill
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 50 * s),
              child: _StatsPill(
                s: s,
                numFollowers: _numFollowers,
                numEvents: _numParticipatedEvents,
                numFollowing: _numFollowing,
              ),
            ),

            SizedBox(height: 120 * s),
          ],
        ),
      ),
    );
  }
}
