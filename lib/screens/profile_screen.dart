// developed and designed by outly • © 2026
// profile screen — zone-2 content: user info card + stats pill + event grid.
//
// layout zones used:
//   zone 1 — background  : kBgColor from VezPageLayout
//   zone 2 — body        : SingleChildScrollView anchored from top
//   zone 3 — blur veil   : handled by VezPageLayout
//   zone 4 — navbars     : settings button / search / follow-requests + bottom pill

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui';

import '../models/vez_glass.dart';
import '../models/vez_page_layout.dart';
import '../models/vez_popup.dart';
import '../services/auth_service.dart';
import '../services/getters_service.dart';
import '../services/setters_service.dart';
import '../services/translation_service.dart';
import '../services/user_session.dart';
import 'create_event/create_event_screen.dart';
import 'home_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// stateful widget wrapper
// ─────────────────────────────────────────────────────────────────────────────

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

// ─────────────────────────────────────────────────────────────────────────────
// state
// ─────────────────────────────────────────────────────────────────────────────

class _ProfilePageState extends State<ProfilePage> {

  // ── controllers & services ─────────────────────────────────────────────────

  final TextEditingController _searchController      = TextEditingController();
  final TextEditingController _usernameCtrl          = TextEditingController();
  final TextEditingController _passwordCtrl          = TextEditingController();
  final TextEditingController _cityAkaNameCtrl       = TextEditingController();
  final TextEditingController _bioCtrl               = TextEditingController();

  final ImagePicker _picker     = ImagePicker();
  final RemoteDbService _remote = RemoteDbService();

  late final GetDBService _dbGet;
  late final SetDBService _dbSet;

  // ── user data state ────────────────────────────────────────────────────────

  String _profilePhoto         = '';
  String _username             = '';
  String _city                 = '';
  String _cityAkaName          = '';
  String _bio                  = '';
  int    _numFollowers         = 0;
  int    _numFollowing         = 0;
  int    _numParticipatedEvents = 0;

  // ── ui flags ───────────────────────────────────────────────────────────────

  bool   _showBadge            = true;
  bool   _showPassword         = false;
  File?  _newProfileImage;
  String? _popupError;

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
    _cityAkaNameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  // ── data loading ───────────────────────────────────────────────────────────

  Future<void> _loadUserData() async {
    final photo      = await _dbGet.getUserData('profile_photo');
    final username   = await _dbGet.getUserData('username');
    final city       = await _dbGet.getUserData('city');
    final akaName    = await _dbGet.getUserData('city_aka_name');
    final bio        = await _dbGet.getUserData('bio');
    final eventsStr  = await _dbGet.getUserData('num_participated_events');
    final badge      = await _dbGet.getUserData('category_badge');
    final followers  = await _dbGet.getFollowersCount();
    final following  = await _dbGet.getFollowing();

    if (!mounted) return;
    setState(() {
      _profilePhoto          = photo?.trim()                     ?? '';
      _username              = username                          ?? 'Username';
      _city                  = city                              ?? StringRes.at('city');
      _cityAkaName           = akaName                           ?? StringRes.at('city_aka_name');
      _bio                   = bio                               ?? StringRes.at('bio');
      _numParticipatedEvents = int.tryParse(eventsStr ?? '0')    ?? 0;
      _showBadge             = bool.tryParse(badge ?? 'true')    ?? true;
      _numFollowers          = followers;
      _numFollowing          = (following as List).length;
    });
  }

  // ── save profile data ──────────────────────────────────────────────────────

  Future<void> _saveProfileData(StateSetter setPopupState) async {
    final String uName    = _usernameCtrl.text.trim();
    final String psw      = _passwordCtrl.text;
    final String akaName  = _cityAkaNameCtrl.text.trim();
    final String bio      = _bioCtrl.text.trim();

    // username validation
    if (uName.isNotEmpty && uName.length < 3) {
      setPopupState(() => _popupError = StringRes.at('username_too_short'));
      return;
    }

    // password validation
    if (psw.isNotEmpty) {
      final bool valid = psw.length >= 8 &&
          RegExp(r'[A-Z]').hasMatch(psw) &&
          RegExp(r'[a-z]').hasMatch(psw) &&
          RegExp(r'[0-9]').hasMatch(psw) &&
          RegExp(r'[!@#$&*~£€?§+]').hasMatch(psw);
      if (!valid) {
        setPopupState(() => _popupError = StringRes.at('invalid_password'));
        return;
      }
    }

    // save fields that changed
    if (uName.isNotEmpty) {
      final int res = await _dbSet.updateUserData('username', uName);
      if (res == 409) {
        setPopupState(() => _popupError = StringRes.at('user_already_exists'));
        return;
      }
      setState(() => _username = uName);
    }
    if (psw.isNotEmpty)      _dbSet.updateUserData('hash_psw', psw);
    if (akaName.isNotEmpty)  _dbSet.updateUserData('city_aka_name', akaName);
    if (bio.isNotEmpty)      _dbSet.updateUserData('bio', bio);
    _dbSet.updateUserData('category_badge', _showBadge);

    // profile photo upload
    if (_newProfileImage != null) {
      final String? url = await _remote.uploadProfilePhoto(_newProfileImage!, _username);
      if (url != null) {
        _dbSet.updateUserData('profile_photo', url);
        setState(() => _profilePhoto = url);
      }
    }

    // update local display values
    setState(() {
      if (akaName.isNotEmpty) _cityAkaName = akaName;
      if (bio.isNotEmpty)     _bio = bio;
    });
  }

  // ── navigation helpers ─────────────────────────────────────────────────────

  void _goToHome() {
    HapticFeedback.selectionClick();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
  }

  void _goToCreateEvent() {
    HapticFeedback.selectionClick();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CreateEvent()));
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final double s  = (sw / 390).clamp(0.8, 1.2);

    return VezPageLayout(
      // ── top navbar ──────────────────────────────────────────────────────
      searchController: _searchController,
      searchHint:       StringRes.at('search'),
      // left button: settings icon (not an avatar on the profile screen)
      profileIconPath:  'assets/icons/profile_page/settings.png',
      isProfileAvatar:  false,
      onProfileTap:     () => _showLanguagePopup(),
      // right button: follow-requests icon
      filterIconPath:   'assets/icons/profile_page/following_requests.png',
      onFilterSelected: (_) {}, // todo: navigate to follow-requests screen

      // ── bottom navbar ────────────────────────────────────────────────────
      bottomNavBar: _BottomNavPill(
        s: s,
        activeIndex:        -1,           // no tab is active on the profile screen
        onHomeTap:          _goToHome,
        onCreateEventTap:   _goToCreateEvent,
        onNotificationsTap: () {},
      ),

      // ── zone-2 body: scrollable profile content ──────────────────────────
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // top spacer so content clears the top blur veil + navbar
            SizedBox(height: 130 * s),

            // ── user info card ─────────────────────────────────────────────
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                _showEditProfilePopup(s);
              },
              child: _UserCard(
                s:            s,
                profilePhoto: _profilePhoto,
                username:     _username,
                cityAkaName:  _cityAkaName,
                city:         _city,
                bio:          _bio,
                showBadge:    _showBadge,
              ),
            ),

            SizedBox(height: 16 * s),

            // ── stats pill ─────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30 * s),
              child: _StatsPill(
                s:                    s,
                numFollowers:         _numFollowers,
                numEvents:            _numParticipatedEvents,
                numFollowing:         _numFollowing,
              ),
            ),

            SizedBox(height: 16 * s),

            // ── past-events grid ───────────────────────────────────────────
            _PastEventsGrid(s: s),

            // bottom spacer so content clears the bottom blur veil + navbar
            SizedBox(height: 120 * s),
          ],
        ),
      ),
    );
  }

  // ── popup: edit profile ────────────────────────────────────────────────────

  void _showEditProfilePopup(double s) {
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
                    maxWidth: 512, maxHeight: 512, imageQuality: 75,
                  );
                  if (file != null) setPopupState(() => _newProfileImage = File(file.path));
                },
                child: _AvatarPicker(
                  newImage:     _newProfileImage,
                  networkPhoto: _profilePhoto,
                ),
              ),

              SizedBox(height: 24 * s),

              // username field
              _PopupInput(
                hint:       StringRes.at('new_username'),
                controller: _usernameCtrl,
                maxLength:  15,
                onChanged:  (v) => setPopupState(() {}),
              ),

              // password field with visibility toggle
              _PopupInput(
                hint:       StringRes.at('new_password'),
                controller: _passwordCtrl,
                obscure:    !_showPassword,
                onChanged:  (v) => setPopupState(() {}),
                suffixIcon: GestureDetector(
                  onTap: () => setPopupState(() => _showPassword = !_showPassword),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      _showPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: Colors.white54, size: 20,
                    ),
                  ),
                ),
              ),

              // city aka-name field
              _PopupInput(
                hint:       StringRes.at('city_aka_name'),
                controller: _cityAkaNameCtrl,
                maxLength:  10,
                onChanged:  (v) => setPopupState(() {}),
              ),

              // bio field
              _PopupInput(
                hint:       StringRes.at('bio'),
                controller: _bioCtrl,
                maxLength:  30,
                onChanged:  (v) => setPopupState(() {}),
              ),

              // category badge toggle
              _BadgeToggle(
                s:          s,
                value:      _showBadge,
                onChanged:  (val) {
                  HapticFeedback.selectionClick();
                  setPopupState(() => _showBadge = val);
                  setState(()  => _showBadge = val);
                },
              ),

              SizedBox(height: 24 * s),

              // error banner (animated, only visible when _popupError is set)
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve:    Curves.easeOut,
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
                s: s,
                onSave: () async {
                  HapticFeedback.mediumImpact();
                  await _saveProfileData(setPopupState);
                  if (!mounted) return;
                  Navigator.pop(context);
                  _clearPopupControllers();
                },
                onDiscard: () {
                  HapticFeedback.mediumImpact();
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

  // ── popup: language selection ──────────────────────────────────────────────

  void _showLanguagePopup() {
    VezPopup.show(
      context: context,
      width: MediaQuery.of(context).size.width * 0.55,
      backgroundColor: const Color.fromARGB(200, 14, 14, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            StringRes.at('select_language'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _LanguageOption(flag: '🇬🇧', label: StringRes.at('lang_en'), code: 'en', onTap: _rebuildAfterLocale),
          const SizedBox(height: 6),
          _LanguageOption(flag: '🇮🇹', label: StringRes.at('lang_it'), code: 'it', onTap: _rebuildAfterLocale),
        ],
      ),
    );
  }

  void _rebuildAfterLocale() {
    Navigator.pop(context);
    setState(() {});
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  void _clearPopupControllers() {
    _usernameCtrl.clear();
    _passwordCtrl.clear();
    _cityAkaNameCtrl.clear();
    _bioCtrl.clear();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BottomNavPill — re-export from home_screen for this file's use.
// in a real project, move this to a shared vez_bottom_nav.dart.
// ─────────────────────────────────────────────────────────────────────────────

class _BottomNavPill extends StatelessWidget {
  final double s;
  final int activeIndex;
  final VoidCallback onHomeTap;
  final VoidCallback onCreateEventTap;
  final VoidCallback onNotificationsTap;

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
      radius:  BorderRadius.circular(40),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: ImageIcon(const AssetImage('assets/icons/nav_bar/go_to_home_page.png'),
                color: activeIndex == 0 ? Colors.white : Colors.white54),
            iconSize: 30, onPressed: onHomeTap,
          ),
          SizedBox(width: 16 * s),
          IconButton(
            icon: ImageIcon(const AssetImage('assets/icons/nav_bar/create_event.png'),
                color: activeIndex == 1 ? Colors.white : Colors.white54),
            iconSize: 30, onPressed: onCreateEventTap,
          ),
          SizedBox(width: 16 * s),
          IconButton(
            icon: ImageIcon(const AssetImage('assets/icons/nav_bar/notifications.png'),
                color: activeIndex == 2 ? Colors.white : Colors.white54),
            iconSize: 30, onPressed: onNotificationsTap,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _UserCard — the rounded card with photo, name, city and bio
// ─────────────────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final double s;
  final String profilePhoto;
  final String username;
  final String cityAkaName;
  final String city;
  final String bio;
  final bool   showBadge;

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
        color: const Color(0xFF0E0E0E),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white38, width: 2),
        boxShadow: const [
          BoxShadow(color: Color.fromARGB(100, 255, 255, 255), blurRadius: 6),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // avatar with optional category badge
          _AvatarWithBadge(photo: profilePhoto, showBadge: showBadge, size: 75),

          SizedBox(width: 16 * s),

          // username / city / bio
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontFamily: 'InstagramSans',
                    fontSize: 30, fontWeight: FontWeight.bold,
                    color: Colors.white, height: 1.0,
                  ),
                ),
                SizedBox(height: 4 * s),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontFamily: 'InstagramSans', color: Colors.white, fontSize: 14),
                    children: [
                      TextSpan(text: cityAkaName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: ' • $city',  style: const TextStyle(fontWeight: FontWeight.w300)),
                    ],
                  ),
                ),
                SizedBox(height: 4 * s),
                Text(
                  bio,
                  style: const TextStyle(
                    fontFamily: 'InstagramSans',
                    fontSize: 14, color: Colors.white,
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

// ─────────────────────────────────────────────────────────────────────────────
// _AvatarWithBadge — circular photo with an optional category badge overlay
// ─────────────────────────────────────────────────────────────────────────────

class _AvatarWithBadge extends StatelessWidget {
  final String photo;
  final bool   showBadge;
  final double size;

  const _AvatarWithBadge({required this.photo, required this.showBadge, required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size, height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            image: DecorationImage(
              image: photo.isNotEmpty
                  ? NetworkImage(photo)
                  : const AssetImage('assets/icons/home_page/profile_photo.png') as ImageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        // category badge (top-right)
        if (showBadge)
          Positioned(
            top: -4, right: -4,
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(51, 0, 10, 218),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color.fromARGB(128, 0, 10, 218), width: 2),
                  ),
                  padding: const EdgeInsets.all(5),
                  // todo: replace with the user's most-frequent event category icon
                  child: Image.asset('assets/icons/categories/pub.png', color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StatsPill — rounded pill with followers / events / following counts
// ─────────────────────────────────────────────────────────────────────────────

class _StatsPill extends StatelessWidget {
  final double s;
  final int numFollowers;
  final int numEvents;
  final int numFollowing;

  const _StatsPill({
    required this.s,
    required this.numFollowers,
    required this.numEvents,
    required this.numFollowing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white38, width: 2),
        boxShadow: const [
          BoxShadow(color: Color.fromARGB(100, 255, 255, 255), blurRadius: 6),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(icon: 'assets/icons/profile_page/followers.png',           value: numFollowers.toString()),
          _StatItem(icon: 'assets/icons/profile_page/participated_events.png', value: numEvents.toString()),
          _StatItem(icon: 'assets/icons/profile_page/following_requests.png',  value: numFollowing.toString()),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String icon;
  final String value;

  const _StatItem({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(icon, width: 28, height: 28, color: Colors.white),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'InstagramSans',
            fontWeight: FontWeight.bold,
            fontSize: 18, color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PastEventsGrid — 3-column grid of past event thumbnails
// ─────────────────────────────────────────────────────────────────────────────

class _PastEventsGrid extends StatelessWidget {
  final double s;

  const _PastEventsGrid({required this.s});

  @override
  Widget build(BuildContext context) {
    // fixed height; fade top+bottom edges with a ShaderMask so content
    // blends smoothly with the blur veil above / below
    return SizedBox(
      height: 400,
      child: ShaderMask(
        shaderCallback: (Rect rect) => const LinearGradient(
          begin:  Alignment.topCenter,
          end:    Alignment.bottomCenter,
          colors: [Colors.black, Colors.transparent, Colors.transparent, Colors.black],
          stops:  [0.0, 0.05, 0.90, 1.0],
        ).createShader(rect),
        blendMode: BlendMode.dstOut,
        child: GridView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 10, bottom: 80),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:   3,
            crossAxisSpacing: 8,
            mainAxisSpacing:  8,
            childAspectRatio: 0.7,
          ),
          // todo: replace 0 with the real event count and provide real data
          itemCount:   0,
          itemBuilder: (_, __) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// popup sub-widgets  (contained here to avoid polluting the screen file)
// ─────────────────────────────────────────────────────────────────────────────

// ── _AvatarPicker: tappable circle that previews the chosen photo ────────────

class _AvatarPicker extends StatelessWidget {
  final File?  newImage;
  final String networkPhoto;

  const _AvatarPicker({required this.newImage, required this.networkPhoto});

  @override
  Widget build(BuildContext context) {
    final ImageProvider img = newImage != null
        ? FileImage(newImage!)
        : (networkPhoto.isNotEmpty
            ? NetworkImage(networkPhoto)
            : const AssetImage('assets/icons/auth/icon_camera_90x90.png')) as ImageProvider;

    return Container(
      width: 80, height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        image: DecorationImage(image: img, fit: BoxFit.cover),
      ),
    );
  }
}

// ── _PopupInput: glass-style rounded text field for the edit popup ───────────

class _PopupInput extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final int? maxLength;
  final int  maxLines;
  final bool obscure;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;

  const _PopupInput({
    required this.hint,
    required this.controller,
    this.maxLength,
    this.maxLines = 1,
    this.obscure  = false,
    this.onChanged,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14, left: 16, right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(maxLines > 1 ? 20 : 30),
        border: Border.all(color: Colors.white54, width: 2),
      ),
      child: TextField(
        controller:  controller,
        onChanged:   onChanged,
        maxLength:   maxLength,
        maxLines:    maxLines,
        obscureText: obscure,
        style: const TextStyle(
          color: Colors.white, fontFamily: 'InstagramSans',
          fontWeight: FontWeight.bold, fontSize: 18,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          border: InputBorder.none,
          counterText: '',
          // show a live character counter when maxLength is set
          suffixText: maxLength != null ? '${controller.text.length}/$maxLength' : null,
          suffixIcon: suffixIcon,
          suffixIconConstraints: const BoxConstraints(),
        ),
      ),
    );
  }
}

// ── _BadgeToggle: row with icon + label + switch ─────────────────────────────

class _BadgeToggle extends StatelessWidget {
  final double s;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _BadgeToggle({required this.s, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(51, 6, 0, 92),
            shape: BoxShape.circle,
            border: Border.all(color: const Color.fromARGB(128, 0, 10, 218), width: 2),
          ),
          padding: const EdgeInsets.all(5),
          child: ImageIcon(const AssetImage('assets/icons/categories/hang_out.png'),
              color: Colors.white, size: 20),
        ),
        SizedBox(width: 16 * s),
        Text(
          StringRes.at('category_badge'),
          style: const TextStyle(
            color: Colors.white54, fontSize: 18,
            fontWeight: FontWeight.bold, fontFamily: 'InstagramSans',
          ),
        ),
        SizedBox(width: 16 * s),
        Switch(
          value:               value,
          onChanged:           onChanged,
          activeThumbColor:    Colors.black,
          activeTrackColor:    Colors.white,
          inactiveThumbColor:  Colors.white54,
          inactiveTrackColor:  Colors.white24,
        ),
      ],
    );
  }
}

// ── _SaveDiscardRow: green save + red discard circle buttons ─────────────────

class _SaveDiscardRow extends StatelessWidget {
  final double s;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  const _SaveDiscardRow({required this.s, required this.onSave, required this.onDiscard});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ActionCircle(
          icon:        'assets/icons/profile_page/save.png',
          color:       const Color.fromARGB(128, 8, 157, 13),
          borderColor: const Color.fromARGB(200, 8, 157, 13),
          onTap:       onSave,
        ),
        SizedBox(width: 28 * s),
        _ActionCircle(
          icon:        'assets/icons/profile_page/delete.png',
          color:       const Color.fromARGB(128, 255, 49, 49),
          borderColor: const Color.fromARGB(200, 255, 49, 49),
          onTap:       onDiscard,
        ),
      ],
    );
  }
}

class _ActionCircle extends StatelessWidget {
  final String icon;
  final Color  color;
  final Color  borderColor;
  final VoidCallback onTap;

  const _ActionCircle({
    required this.icon,
    required this.color,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color, shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 2),
        ),
        child: ImageIcon(AssetImage(icon), color: Colors.white, size: 30),
      ),
    );
  }
}

// ── _LanguageOption: single tappable row in the language popup ───────────────

class _LanguageOption extends StatelessWidget {
  final String flag;
  final String label;
  final String code;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.flag,
    required this.label,
    required this.code,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool selected = StringRes.locale == code;
    return GestureDetector(
      onTap: () {
        StringRes.setLocale(code);
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: selected ? Border.all(color: Colors.white24, width: 1.5) : null,
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: Colors.white, fontSize: 16,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (selected) const Icon(Icons.check_circle, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}
