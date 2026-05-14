// screen that displays another user's public profile.

import 'package:flutter/material.dart';

import '../../models/general_user_profile.dart';
import '../../services/getters_service.dart';
import '../../services/haptic_service.dart';
import '../../services/translation_service.dart';
import '../../services/user_session.dart';
import '../../views/widgets/vez_page_layout.dart';
import '../event_creation/create_event_screen.dart';
import '../home/home_screen_widgets.dart';
import '../notifications_screen.dart';
import 'general_user_profile_controller.dart';
import 'general_user_profile_widgets.dart';
import 'profile_screen.dart';
import 'profile_shared_widgets.dart';

/// displays the profile page for a non-local user.
class GeneralUserProfilePage extends StatefulWidget {
  const GeneralUserProfilePage({super.key, required this.userId});

  final String userId;

  @override
  State<GeneralUserProfilePage> createState() => _GeneralUserProfilePageState();
}

/// owns navigation and state wiring for the general user profile screen.
class _GeneralUserProfilePageState extends State<GeneralUserProfilePage> {
  final TextEditingController _searchController = TextEditingController();
  late final GeneralUserProfileController _controller;
  late final GetDBService _localGet;
  String _localProfilePhoto = '';

  /// initializes the controller and starts profile loading.
  @override
  void initState() {
    super.initState();
    final String localUserId = UserSession().userID;
    _localGet = GetDBService(userID: localUserId);
    _controller = GeneralUserProfileController(
      localUserId: localUserId,
      viewedUserId: widget.userId,
    )..addListener(_onControllerChanged);
    _loadPageData();
  }

  /// disposes resources owned by the screen.
  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// reloads the current user's avatar and the viewed profile.
  Future<void> _loadPageData() async {
    final results = await Future.wait([
      _localGet.getUserData('profile_photo'),
      _controller.loadProfile(),
    ]);
    if (!mounted) return;
    setState(() {
      _localProfilePhoto = (results[0] as String?)?.trim() ?? '';
    });
  }

  /// rebuilds the screen when controller state changes.
  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  /// navigates back to the home route.
  void _goToHome() {
    HapticService.tap();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  /// opens the create event screen.
  void _goToCreateEvent() {
    HapticService.tap();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateEvent()),
    );
  }

  /// opens the notifications screen.
  void _goToNotifications() {
    HapticService.tap();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
  }

  /// opens the local user's own profile.
  void _goToLocalProfile() {
    HapticService.tap();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    ).then((_) => _loadPageData());
  }

  /// toggles the follow relation for the viewed user.
  Future<void> _toggleFollowUser() async {
    HapticService.tap();
    final GeneralUserRelation? relation = _controller.profile?.relation;
    final bool shouldUnfollow =
        relation == GeneralUserRelation.friends ||
        relation == GeneralUserRelation.following;
    final int result = shouldUnfollow
        ? await _controller.unfollowViewedUser()
        : await _controller.followViewedUser();
    if (!mounted || result == 200 || result == 201 || result == 204) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${StringRes.at(shouldUnfollow ? "unfollow_failed" : "follow_failed")} ($result)',
        ),
        backgroundColor: const Color.fromARGB(200, 255, 49, 49),
      ),
    );
  }

  /// assembles the profile layout from shared app widgets.
  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final double scale = (sw / 390).clamp(0.8, 1.2);

    return VezPageLayout(
      // ── top navbar ─────────────────────────────────────────────────────────
      searchController: _searchController,
      searchHint: StringRes.at('search'),

      // left: local user profile photo → opens local user profile page
      profileIconPath: _localProfilePhoto,
      isProfileAvatar: true,
      onProfileTap: _goToLocalProfile,

      // right: ? → will open something
      filterIconPath: '',
      isFilterSelected: false,
      onFilterTap: null,
      onFilterSelected: null,
      isFilterEnabled: false,

      // ── bottom navbar ──────────────────────────────────────────────────────
      bottomNavBar: HomeBottomNavPill(
        s: scale,
        activeIndex: -1,
        onHomeTap: _goToHome,
        onCreateEventTap: _goToCreateEvent,
        onNotificationsTap: _goToNotifications,
      ),
      body: _buildBody(scale),
    );
  }

  /// builds loading, error, or loaded profile content.
  Widget _buildBody(double scale) {
    if (_controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color.fromARGB(255, 255, 255, 255),
        ),
      );
    }

    final GeneralUserProfile? profile = _controller.profile;
    if (profile == null) {
      return Center(
        child: Text(
          _controller.errorMessage.isNotEmpty
              ? _controller.errorMessage
              : StringRes.at('user_not_found'),
          style: const TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 130 * scale),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 5 * scale),
            child: ProfileInfoCard(
              scale: scale,
              profilePhoto: profile.profilePhoto,
              username: profile.username,
              cityAkaName: profile.cityAkaName,
              city: profile.city,
              bio: profile.bio,
              showBadge: profile.showBadge,
              categoryBadgeIconPath: profile.categoryBadgeIconPath,
              showFriendBadge: profile.relation == GeneralUserRelation.friends,
            ),
          ),
          SizedBox(height: 16 * scale),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 50 * scale),
            child: ProfileStatsPill(
              scale: scale,
              followers: profile.followersCount,
              events: profile.participatedEventsCount,
              likes: profile.eventLikesReceivedCount,
            ),
          ),
          SizedBox(height: 18 * scale),
          Center(
            child: GeneralFollowButton(
              relation: profile.relation,
              isBusy: _controller.isFollowing,
              onTap: _toggleFollowUser,
            ),
          ),
          SizedBox(height: 18 * scale),
          ProfilePastEventsGrid(events: profile.pastEvents, scale: scale),
          SizedBox(height: 130 * scale),
        ],
      ),
    );
  }
}
