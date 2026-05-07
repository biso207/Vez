// Developed and Designed by Outly • © 2026
// profile screen : zone-2 content: user info card + stats pill + event grid.
//
// layout zones used:
//   zone 1 : background  : kBgColor from VezPageLayout
//   zone 2 : body        : SingleChildScrollView anchored from top
//   zone 3 : blur veil   : handled by VezPageLayout
//   zone 4 : navbars     : settings / search / follow-requests + bottom pill
//
// top-bar left button = settings icon â†’ opens _SettingsPopup (full glass panel)
//   the settings popup replaces the old standalone language popup and groups
//   all user preferences (language, badge toggle, etc.) in one place.
//
// top-bar left button on profile screen is intentionally NOT a profile avatar;
// the settings icon is used instead since the user is already viewing their profile.

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/getters_service.dart';
import '../services/haptic_service.dart';
import '../services/setters_service.dart';
import '../services/translation_service.dart';
import '../services/user_session.dart';
import '../views/widgets/vez_glass.dart';
import '../views/widgets/vez_page_layout.dart';
import '../views/widgets/vez_popup.dart';
import 'auth/login_screen.dart';
import 'create_event/create_event_screen.dart';
import 'notifications_screen.dart';

const double kBlurValue = 5.0;

// ─────────────────────────────────────────────────────────────
// stateful widget wrapper
// ─────────────────────────────────────────────────────────────

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

// ─────────────────────────────────────────────────────────────
// state
// ─────────────────────────────────────────────────────────────

class _ProfilePageState extends State<ProfilePage> {
  // ── controllers & services ────────────────────────────────────────────────

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _currentPasswordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();
  final TextEditingController _deleteAccountCtrl = TextEditingController();
  final TextEditingController _cityAkaNameCtrl = TextEditingController();
  final TextEditingController _bioCtrl = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final RemoteDbService _remote = RemoteDbService();

  late final GetDBService _dbGet;
  late final SetDBService _dbSet;

  // ── user data state ────────────────────────────────────────────────────────

  String _profilePhoto = '';
  String _username = '';
  String _city = '';
  String _cityAkaName = '';
  String _bio = '';
  int _numFollowers = 0;
  int _numFollowing = 0;
  int _numParticipatedEvents = 0;
  List<Map<String, dynamic>> _pastCreatedEvents = const [];
  List<Map<String, dynamic>> _pastParticipatedEvents = const [];

  // ── ui flags ──────────────────────────────────────────────────────────────

  bool _showBadge = true;
  bool _showPassword = false;
  bool _showCurrentPassword = false;
  bool _showConfirmPassword = false;
  File? _newProfileImage;
  String? _popupError;

  // ── static data ────────────────────────────────────────────────────────────

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

  @override
  void initState() {
    super.initState();
    final String uid = UserSession().userID;
    if (uid.isNotEmpty) {
      _dbGet = GetDBService(userID: uid);
      _dbSet = SetDBService(userID: uid);
      _loadUserData();
    }
  }

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

  bool get _isValid =>
      _usernameCtrl.text.trim().isNotEmpty &&
      _usernameCtrl.text.trim().length >= 4;

  // ── data loading ──────────────────────────────────────────────────────────

  Future<void> _loadUserData() async {
    final photo = await _dbGet.getUserData('profile_photo');
    final username = await _dbGet.getUserData('username');
    final city = await _dbGet.getUserData('city');
    final akaName = await _dbGet.getUserData('city_aka_name');
    final bio = await _dbGet.getUserData('bio');
    final eventsStr = await _dbGet.getUserData('num_participated_events');
    final badge = await _dbGet.getUserData('category_badge');
    final followers = await _dbGet.getFollowersCount();
    final following = await _dbGet.getFollowing();
    final pastCreated = await _dbGet.getExpiredCreatedEvents();
    final pastParticipated = await _dbGet.getExpiredParticipatedEvents();

    if (!mounted) return;
    setState(() {
      _profilePhoto = photo?.trim() ?? '';
      _username = username ?? 'Username';
      _city = city ?? StringRes.at('city');
      _cityAkaName = akaName?.trim().isNotEmpty == true ? '$akaName • ' : '';
      _bio = bio ?? StringRes.at('bio');
      _numParticipatedEvents = int.tryParse(eventsStr ?? '0') ?? 0;
      _showBadge = bool.tryParse(badge ?? 'true') ?? true;
      _numFollowers = followers;
      _numFollowing = (following).length;
      _pastCreatedEvents = pastCreated;
      _pastParticipatedEvents = pastParticipated;
    });
  }

  // ── save profile edits ────────────────────────────────────────────────────

  Future<void> _saveProfileData(StateSetter setPopupState) async {
    final String uName = _usernameCtrl.text.trim();
    final String akaName = _cityAkaNameCtrl.text.trim();
    final String bio = _bioCtrl.text.trim();

    if (uName != _username && uName.length >= 4) {
      final int res = await _dbSet.updateUserData('username', uName);
      if (res == 409) {
        setPopupState(() => _popupError = StringRes.at('user_already_exists'));
        return;
      }
      // update on db
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
      _bio = bio;
    });
  }

  // ── navigation helpers ────────────────────────────────────────────────────

  void _goToHome() {
    HapticService.tap();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

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

  void _goToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
  }

  void _clearPopupControllers() {
    _usernameCtrl.clear();
    _passwordCtrl.clear();
    _currentPasswordCtrl.clear();
    _confirmPasswordCtrl.clear();
    _deleteAccountCtrl.clear();
    _cityAkaNameCtrl.clear();
    _bioCtrl.clear();
    _showPassword = false;
    _showCurrentPassword = false;
    _showConfirmPassword = false;
    _popupError = null;
  }

  bool _isStrongPassword(String password) {
    return password.length >= 12 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[!@#$&*~Â£â‚¬?Â§+._-]').hasMatch(password);
  }

  Future<void> _handlePasswordChange(StateSetter setPopupState) async {
    final String currentPassword = _currentPasswordCtrl.text;
    final String newPassword = _passwordCtrl.text;
    final String confirmPassword = _confirmPasswordCtrl.text;

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
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

  Future<void> _handleAccountDeletion(StateSetter setPopupState) async {
    final String typedUsername = _deleteAccountCtrl.text.trim();
    if (typedUsername != _username) {
      setPopupState(
        () => _popupError = StringRes.at('username_confirm_failed'),
      );
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

  void _handleLogout() {
    HapticService.emphasis();
    Navigator.pop(context);
    _logoutAndRedirect();
  }

  Future<void> _logoutAndRedirect() async {
    await _remote.logout();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final double s = (sw / 390).clamp(0.8, 1.2);

    return VezPageLayout(
      // ── top navbar ──────────────────────────────────────────────────────
      // search area
      searchController: _searchController,
      searchHint: StringRes.at('search'),

      // left button: settings icon which opens the full settings popup
      profileIconPath: 'assets/icons/profile_page/settings.png',
      isProfileAvatar: false,
      onProfileTap: () {
        HapticService.emphasis();
        _showSettingsPopup(s);
      },

      // right button: follow-requests
      filterIconPath: 'assets/icons/event/edit.png',
      isFilterSelected: false,
      onFilterTap: () {
        HapticService.emphasis();
        _showEditProfilePopup(s);
      },
      onFilterSelected: null,
      // ── bottom navbar ────────────────────────────────────────────────────
      bottomNavBar: _BottomNavPill(
        s: s,
        activeIndex: -1,
        onHomeTap: _goToHome,
        onCreateEventTap: _goToCreateEvent,
        onNotificationsTap: _goToNotifications,
      ),

      // ── zone-2 body: scrollable profile content ──────────────────────────
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // top spacer to clear the navbar + blur veil
            SizedBox(height: 130 * s),

            // ── user info card (tap to edit) ──────────────────────────────
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

            // ── stats pill ────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 50 * s),
              child: _StatsPill(
                s: s,
                numFollowers: _numFollowers,
                numEvents: _numParticipatedEvents,
                numFollowing: _numFollowing,
              ),
            ),

            SizedBox(height: 16 * s),

            // ── past-events grid ──────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24 * s),
              child: Row(
                children: [
                  Expanded(
                    child: _PastEventsButton(
                      s: s,
                      label: 'I Tuoi Eventi Passati',
                      count: _pastCreatedEvents.length,
                      icon: Icons.event_available_rounded,
                      onTap: () => _showPastEventsPopup(
                        'I Tuoi Eventi Passati',
                        _pastCreatedEvents,
                      ),
                    ),
                  ),
                  SizedBox(width: 10 * s),
                  Expanded(
                    child: _PastEventsButton(
                      s: s,
                      label: 'Eventi A Cui Hai Partecipato',
                      count: _pastParticipatedEvents.length,
                      icon: Icons.verified_rounded,
                      onTap: () => _showPastEventsPopup(
                        'Eventi A Cui Hai Partecipato',
                        _pastParticipatedEvents,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 120 * s),
          ],
        ),
      ),
    );
  }

  // ── popup: settings ────────────────────────────────────────────────────────
  //
  // this is the full settings panel opened by the gear icon in the top-bar.
  // it groups all user preferences together:
  //   • language selection
  //   • category badge toggle
  //   • (future: notifications, privacy, etc.)
  //
  // the language section replaces the old standalone language popup.

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
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
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

  String _formatPastEventDate(String raw) {
    final date = DateTime.tryParse(raw)?.toLocal();
    if (date == null) return '';
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} - ${two(date.hour)}:${two(date.minute)}';
  }

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

              // ── settings title ──────────────────────────────────────────
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
                    // Troviamo i dati della lingua corrente nella lista _languages
                    final currentLang = _languages.firstWhere(
                      (lang) => lang['code'] == StringRes.locale,
                      orElse: () => _languages
                          .first, // Fallback sulla prima lingua se non trova il codice
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
                            // Icona della lingua corrente
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
                                  style: TextStyle(
                                    color: const Color.fromARGB(
                                      128,
                                      255,
                                      255,
                                      255,
                                    ),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: const Color.fromARGB(128, 255, 255, 255),
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

              // ── section: display preferences ────────────────────────────
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
                    _dbSet.updateUserData(
                      'category_badge',
                      val,
                    ); // changing value in the db
                  },
                ),
              ),

              SizedBox(height: 14 * s),

              // ── section: account ────────────────────────────────────────
              _SettingsSection(
                label: StringRes.at('account'),
                iconPath: 'assets/icons/profile_page/account.png',
                child: Column(
                  mainAxisSize: MainAxisSize
                      .min, // Opzionale: restringe la colonna al contenuto
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
                    _AccountActions(s: s, onLogout: _handleLogout), // logout
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

  // ── popup: edit profile ────────────────────────────────────────────────────
  //
  // opened by tapping the user info card.
  // fields: username, password, city aka-name, bio, profile photo.

  void _showEditProfilePopup(double s) {
    _usernameCtrl.text = _username;
    _cityAkaNameCtrl.text = _cityAkaName.replaceAll(' • ', '');
    _bioCtrl.text = _bio;

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
                hint: StringRes.at("edit_username"),
                controller: _usernameCtrl,
                maxLength: 15,
                onChanged: (v) => setPopupState(() {}),
              ),

              // city aka-name field
              _PopupInput(
                hint: StringRes.at("city_aka_name"),
                controller: _cityAkaNameCtrl,
                maxLength: 10,
                onChanged: (v) => setPopupState(() {}),
              ),

              // bio field
              _PopupInput(
                hint: StringRes.at("bio"),
                controller: _bioCtrl,
                maxLength: 30,
                onChanged: (v) => setPopupState(() {}),
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

  // ── popup: language selector ───────────────────────────────────────────────
  //
  // opened by tapping the language in the settings.

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
              _PopupInput(
                hint: StringRes.at('current_password'),
                controller: _currentPasswordCtrl,
                obscure: !_showCurrentPassword,
                onChanged: (v) => setPopupState(() => _popupError = null),
                suffixIcon: _PasswordVisibilityToggle(
                  visible: _showCurrentPassword,
                  onTap: () => setPopupState(
                    () => _showCurrentPassword = !_showCurrentPassword,
                  ),
                ),
              ),
              _PopupInput(
                hint: StringRes.at('new_password'),
                controller: _passwordCtrl,
                obscure: !_showPassword,
                onChanged: (v) => setPopupState(() => _popupError = null),
                suffixIcon: _PasswordVisibilityToggle(
                  visible: _showPassword,
                  onTap: () =>
                      setPopupState(() => _showPassword = !_showPassword),
                ),
              ),
              _PopupInput(
                hint: StringRes.at('confirm_password'),
                controller: _confirmPasswordCtrl,
                obscure: !_showConfirmPassword,
                onChanged: (v) => setPopupState(() => _popupError = null),
                suffixIcon: _PasswordVisibilityToggle(
                  visible: _showConfirmPassword,
                  onTap: () => setPopupState(
                    () => _showConfirmPassword = !_showConfirmPassword,
                  ),
                ),
              ),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  StringRes.at(
                    'delete_account_confirm_message',
                  ).replaceAll('{username}', _username),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 16 * s),
              _PopupInput(
                hint: _username,
                controller: _deleteAccountCtrl,
                onChanged: (v) => setPopupState(() => _popupError = null),
              ),
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
              _ConfirmCancelRow(
                s: s,
                confirmEnabled: _deleteAccountCtrl.text.trim() == _username,
                confirmColor: const Color.fromARGB(128, 255, 49, 49),
                confirmBorder: const Color.fromARGB(204, 255, 49, 49),
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

  /// scrollable list of languages
  void _showLanguageSelector({VoidCallback? onLanguageChanged}) {
    final double pw = MediaQuery.of(context).size.width * 0.50;
    final double totalHeight = (_languages.length * 50.0);
    final double ph = totalHeight.clamp(
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
        separatorBuilder: (_, _) => _PopupDivider(width: pw),
        itemBuilder: (context, i) {
          final String code = _languages[i]['code']!;
          final String name = _languages[i]['name']!;
          final String iconPath = _languages[i]['icon']!;
          final bool isSelected = StringRes.locale == code;

          return GestureDetector(
            onTap: () async {
              final navigator = Navigator.of(context);
              final int res = await _dbSet.updateUserData('language', code);

              if (res == 200 || res == 204) {
                HapticService.selection();
                StringRes.setLocale(code);
                onLanguageChanged?.call();
                if (mounted) setState(() {});
              }

              if (navigator.canPop()) navigator.pop();
            },
            child: Container(
              // Padding interno per simulare il ListTile del category popup
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.start, // Forza l'allineamento a sinistra
                children: [
                  // Icona leading (stesse dimensioni del category popup)
                  Image.asset(
                    iconPath,
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(width: 12), // Spazio fisso tra icona e testo
                  // Testo della lingua
                  Text(
                    StringRes.at(name),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),

                  const Spacer(),

                  // confirm icon
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
}

// ─────────────────────────────────────────────────────────────
// _PopupDivider
// ─────────────────────────────────────────────────────────────

class _PopupDivider extends StatelessWidget {
  final double width;
  const _PopupDivider({required this.width});

  @override
  Widget build(BuildContext context) {
    final double w = (width * 0.70).clamp(100.0, width - 32.0);
    return Center(
      child: Container(
        width: w,
        height: 2,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _BottomNavPill
// ─────────────────────────────────────────────────────────────

class _BottomNavPill extends StatelessWidget {
  final double s;
  final int activeIndex;
  final VoidCallback onHomeTap, onCreateEventTap, onNotificationsTap;

  const _BottomNavPill({
    required this.s,
    required this.activeIndex,
    required this.onHomeTap,
    required this.onCreateEventTap,
    required this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    return VezGlass.container(
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 0),
      radius: BorderRadius.circular(40),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: ImageIcon(
              const AssetImage('assets/icons/nav_bar/go_to_home_page.png'),
              color: activeIndex == 0 ? Colors.white : Colors.white54,
            ),
            iconSize: 30,
            onPressed: onHomeTap,
          ),
          SizedBox(width: 16 * s),
          IconButton(
            icon: ImageIcon(
              const AssetImage('assets/icons/nav_bar/create_event.png'),
              color: activeIndex == 1 ? Colors.white : Colors.white54,
            ),
            iconSize: 30,
            onPressed: onCreateEventTap,
          ),
          SizedBox(width: 16 * s),
          IconButton(
            icon: ImageIcon(
              const AssetImage('assets/icons/nav_bar/notifications.png'),
              color: activeIndex == 2 ? Colors.white : Colors.white54,
            ),
            iconSize: 30,
            onPressed: onNotificationsTap,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// zone-2 sub-widgets
// ─────────────────────────────────────────────────────────────

// ── _UserCard ────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final double s;
  final String profilePhoto, username, cityAkaName, city, bio;
  final bool showBadge;

  const _UserCard({
    required this.s,
    required this.profilePhoto,
    required this.username,
    required this.cityAkaName,
    required this.city,
    required this.bio,
    required this.showBadge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.fromARGB(50, 0, 0, 0),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: Color.fromARGB(128, 255, 255, 255),
          width: 2 * s,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AvatarWithBadge(
            photo: profilePhoto,
            showBadge: showBadge,
            size: 75 * s,
          ),
          SizedBox(width: 16 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontFamily: 'InstagramSans',
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                SizedBox(height: 4 * s),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: 'InstagramSans',
                      color: Colors.white,
                      fontSize: 14 * s,
                    ),
                    children: [
                      TextSpan(
                        text: cityAkaName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: city,
                        style: const TextStyle(fontWeight: FontWeight.w300),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4 * s),
                Text(
                  bio,
                  style: TextStyle(
                    fontFamily: 'InstagramSans',
                    fontSize: 14 * s,
                    color: Colors.white,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── _AvatarWithBadge ─────────────────────────────────────────────────────────

class _AvatarWithBadge extends StatelessWidget {
  final String photo;
  final bool showBadge;
  final double size;

  const _AvatarWithBadge({
    required this.photo,
    required this.showBadge,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            image: DecorationImage(
              image: photo.isNotEmpty
                  ? NetworkImage(photo)
                  : const AssetImage('assets/icons/home_page/profile_photo.png')
                        as ImageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (showBadge)
          Positioned(
            top: -4,
            right: -4,
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: kBlurValue,
                  sigmaY: kBlurValue,
                ),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(51, 0, 10, 218),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color.fromARGB(128, 0, 10, 218),
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(5),
                  // todo: replace with the user's most-frequent event category icon
                  child: Image.asset(
                    'assets/icons/categories/pub.png',
                    color: Colors.white,
                    height: 22,
                    width: 22,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── _StatsPill ───────────────────────────────────────────────────────────────

class _StatsPill extends StatelessWidget {
  final double s;
  final int numFollowers, numEvents, numFollowing;

  const _StatsPill({
    required this.s,
    required this.numFollowers,
    required this.numEvents,
    required this.numFollowing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      decoration: BoxDecoration(
        color: Color.fromARGB(50, 0, 0, 0),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: Color.fromARGB(128, 255, 255, 255),
          width: 2 * s,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(
            icon: 'assets/icons/profile_page/followers.png',
            value: numFollowers.toString(),
          ),
          _StatItem(
            icon: 'assets/icons/profile_page/participated_events.png',
            value: numEvents.toString(),
          ),
          _StatItem(
            icon: 'assets/icons/profile_page/following_requests.png',
            value: numFollowing.toString(),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String icon, value;
  const _StatItem({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(icon, width: 30, height: 30, color: Colors.white),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'InstagramSans',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
            height: 1,
          ),
        ),
      ],
    );
  }
}

// ── _PastEventsGrid ──────────────────────────────────────────────────────────

class _PastEventsButton extends StatelessWidget {
  final double s;
  final String label;
  final int count;
  final IconData icon;
  final VoidCallback onTap;

  const _PastEventsButton({
    required this.s,
    required this.label,
    required this.count,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 82 * s,
        padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 10 * s),
        decoration: BoxDecoration(
          color: const Color.fromARGB(50, 0, 0, 0),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white60, width: 2 * s),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 24 * s),
                  SizedBox(width: 8 * s),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12 * s,
                        fontWeight: FontWeight.bold,
                        height: 1.05,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14 * s,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PastEventsPopupHeader extends StatelessWidget {
  final String title;
  final int count;

  const _PastEventsPopupHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24, width: 1.5),
          ),
          child: const Icon(
            Icons.history_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$count eventi archiviati',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PastEventRow extends StatelessWidget {
  final Map<String, dynamic> event;
  final String date;

  const _PastEventRow({required this.event, required this.date});

  @override
  Widget build(BuildContext context) {
    final title = (event['title'] ?? '').toString().trim();
    final type = (event['type'] ?? '').toString().trim();
    final photo = (event['bg_photo'] ?? '').toString().trim();
    final place = event['place'] is Map
        ? Map<String, dynamic>.from(event['place'] as Map)
        : <String, dynamic>{};
    final placeName = (place['name'] ?? '').toString().trim();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white38, width: 1.4),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: 76,
              height: 76,
              child: photo.isNotEmpty
                  ? Image.network(
                      photo,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _PastEventFallbackImage(type: type),
                    )
                  : Image.asset(
                      'assets/images/bg/default_create_event_bg.jpg',
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? 'Evento' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  [date, placeName].where((v) => v.isNotEmpty).join(' - '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      type.isEmpty ? 'Expired' : type,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PastEventFallbackImage extends StatelessWidget {
  final String type;

  const _PastEventFallbackImage({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withValues(alpha: 0.10),
      child: Center(
        child: Icon(
          type.toLowerCase() == 'public'
              ? Icons.public_rounded
              : Icons.lock_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// settings
// ─────────────────────────────────────────────────────────────

// ── _SettingsSection ─────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final String label;
  final String iconPath;
  final Widget child;

  const _SettingsSection({
    required this.label,
    required this.iconPath,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Color.fromARGB(50, 0, 0, 0),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white54, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // section header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                children: [
                  ImageIcon(
                    AssetImage(iconPath),
                    color: Colors.white54,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            // section content
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

// ── _BadgeToggleRow: category badge on/off switch ────────────────────────────

class _BadgeToggleRow extends StatelessWidget {
  final double s;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _BadgeToggleRow({
    required this.s,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(51, 6, 0, 92),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color.fromARGB(128, 0, 10, 218),
              width: 2,
            ),
          ),
          padding: const EdgeInsets.all(5),
          child: ImageIcon(
            const AssetImage('assets/icons/categories/hang_out.png'),
            color: Colors.white,
            size: 20,
          ),
        ),
        SizedBox(width: 12 * s),
        Expanded(
          child: Text(
            StringRes.at('category_badge'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.green,
          activeTrackColor: Colors.white,
          inactiveThumbColor: Colors.red,
          inactiveTrackColor: Colors.white24,
        ),
      ],
    );
  }
}

// ── _AccountActions: logout (and future account actions) ─────────────────────

class _AccountActionButton extends StatelessWidget {
  final double s;
  final String label;
  final String iconPath;
  final Color color;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _AccountActionButton({
    required this.s,
    required this.label,
    required this.iconPath,
    required this.color,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            ImageIcon(AssetImage(iconPath), color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color.withValues(alpha: .7),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountActions extends StatelessWidget {
  final double s;
  final VoidCallback onLogout;

  const _AccountActions({required this.s, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onLogout,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color.fromARGB(40, 255, 49, 49),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color.fromARGB(100, 255, 49, 49),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            const ImageIcon(
              AssetImage('assets/icons/profile_page/logout.png'),
              color: Color(0xFFFF3131),
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              StringRes.at('logout'),
              style: const TextStyle(
                color: Color(0xFFFF3131),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// edit-profile popup sub-widgets
// ─────────────────────────────────────────────────────────────

// ── _AvatarPicker: tappable circle that previews the new profile photo ───────

class _PopupTitle extends StatelessWidget {
  final String text;

  const _PopupTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _PasswordVisibilityToggle extends StatelessWidget {
  final bool visible;
  final VoidCallback onTap;

  const _PasswordVisibilityToggle({required this.visible, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Icon(
          visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: Colors.white54,
          size: 20,
        ),
      ),
    );
  }
}

class _ConfirmCancelRow extends StatelessWidget {
  final double s;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool confirmEnabled;
  final Color confirmColor;
  final Color confirmBorder;

  const _ConfirmCancelRow({
    required this.s,
    required this.onConfirm,
    required this.onCancel,
    this.confirmEnabled = true,
    this.confirmColor = const Color.fromARGB(128, 8, 157, 13),
    this.confirmBorder = const Color.fromARGB(204, 8, 157, 13),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ActionCircle(
          active: confirmEnabled,
          icon: 'assets/icons/profile_page/confirm.png',
          activeColor: confirmColor,
          activeBorder: confirmBorder,
          onTap: confirmEnabled ? onConfirm : () {},
        ),
        SizedBox(width: 28 * s),
        _ActionCircle(
          active: true,
          icon: 'assets/icons/profile_page/delete.png',
          activeColor: const Color.fromARGB(128, 255, 49, 49),
          activeBorder: const Color.fromARGB(204, 255, 49, 49),
          onTap: onCancel,
        ),
      ],
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  final File? newImage;
  final String networkPhoto;

  const _AvatarPicker({required this.newImage, required this.networkPhoto});

  @override
  Widget build(BuildContext context) {
    final ImageProvider img = newImage != null
        ? FileImage(newImage!)
        : (networkPhoto.isNotEmpty
                  ? NetworkImage(networkPhoto)
                  : const AssetImage('assets/icons/auth/icon_camera_90x90.png'))
              as ImageProvider;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white54, width: 2),
        image: DecorationImage(image: img, fit: BoxFit.cover),
      ),
    );
  }
}

// ── _PopupInput: glass pill text field ───────────────────────────────────────

class _PopupInput extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final int? maxLength;
  final bool obscure;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;

  const _PopupInput({
    required this.hint,
    required this.controller,
    this.maxLength,
    this.obscure = false,
    this.onChanged,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14, left: 16, right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white54, width: 2),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        maxLength: maxLength,
        maxLines: 1,
        obscureText: obscure,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'InstagramSans',
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          border: InputBorder.none,
          counterText: '',
          suffixText: maxLength != null
              ? '${controller.text.length}/$maxLength'
              : null,
          suffixIcon: suffixIcon,
          suffixIconConstraints: const BoxConstraints(),
        ),
      ),
    );
  }
}

// ── _SaveDiscardRow: green save + red discard circle buttons ─────────────────

class _SaveDiscardRow extends StatelessWidget {
  final double s;
  final VoidCallback onSave, onDiscard;
  final bool isValid;

  const _SaveDiscardRow({
    required this.s,
    required this.onSave,
    required this.onDiscard,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ActionCircle(
          active: isValid,
          icon: 'assets/icons/profile_page/save.png',
          activeColor: const Color.fromARGB(128, 8, 157, 13),
          activeBorder: const Color.fromARGB(204, 8, 157, 13),
          onTap: isValid ? onSave : () {},
        ),
        SizedBox(width: 28 * s),
        _ActionCircle(
          active: isValid,
          icon: 'assets/icons/profile_page/delete.png',
          activeColor: const Color.fromARGB(128, 255, 49, 49),
          activeBorder: const Color.fromARGB(204, 255, 49, 49),
          onTap: isValid ? onDiscard : () {},
        ),
      ],
    );
  }
}

class _ActionCircle extends StatelessWidget {
  final String icon;
  final bool active;
  final Color activeColor, activeBorder;
  final VoidCallback onTap;

  const _ActionCircle({
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.activeBorder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active ? activeColor : const Color.fromARGB(128, 0, 0, 0),
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? activeBorder : Colors.grey,
            width: 2,
          ),
        ),
        child: ImageIcon(AssetImage(icon), color: Colors.white, size: 30),
      ),
    );
  }
}
