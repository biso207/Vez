// main screen of the app used for displaying, managing and exploring different events

import 'dart:async';

import 'package:flutter/material.dart';

import 'home_controller.dart';
import 'home_event.dart';
import 'home_filters.dart';
import 'home_screen_widgets.dart';
import '../../services/getters_service.dart';
import '../../services/haptic_service.dart';
import '../../services/setters_service.dart';
import '../../services/translation_service.dart';
import '../../services/user_session.dart';
import '../../views/widgets/vez_coach_marks.dart';
import '../../views/widgets/vez_page_layout.dart';
import '../../views/widgets/vez_popup.dart';
import '../event_creation/create_event_screen.dart';
import '../notifications_screen.dart';
import '../profile/profile_screen.dart';

//
//   used for: the primary landing screen of the application.
//   design: a stateful widget that orchestrates event feeds and navigation.
class HomePage extends StatefulWidget {
  const HomePage({super.key, this.initialFilterIndex = 0, this.initialEventId});

  final int initialFilterIndex;
  final String? initialEventId;

  @override
  State<HomePage> createState() => _HomePageState();
}

//
//   used for: managing the lifecycle and ui state of the home screen.
//   design: handles data fetching, filtering, and popup orchestration.
class _HomePageState extends State<HomePage> {
  static const String _emptyStateIcon =
      'assets/icons/home_page/no_event_found.png';
  static const Duration _autoRefreshInterval = Duration(seconds: 60);

  static const List<Map<String, dynamic>> _filterIcons = [
    {
      'icon': 'assets/icons/home_page/invited_events.png',
      'type': EventType.invited,
    },
    {
      'icon': 'assets/icons/home_page/by_you_events.png',
      'type': EventType.byYou,
    },
    {
      'icon': 'assets/icons/home_page/nearby_events.png',
      'type': EventType.nearby,
    },
  ];
  static const int _byYouFilterIndex = 1;

  final TextEditingController _searchController = TextEditingController();
  late final HomeController _controller;
  late final GetDBService _dbGet;
  late final SetDBService _dbSet;
  Timer? _autoRefreshTimer;
  bool _isAutoRefreshing = false;
  bool _hasCheckedTutorial = false;

  late int _filterIndex;

  bool get _isVenueAccount => UserSession().accountType == 'venue';

  //
  //   used for: initializing controllers and loading initial page data.
  @override
  void initState() {
    super.initState();
    _filterIndex = _isVenueAccount
        ? _byYouFilterIndex
        : widget.initialFilterIndex.clamp(0, _filterIcons.length - 1);
    _dbGet = GetDBService(userID: UserSession().userID);
    _dbSet = SetDBService(userID: UserSession().userID);
    _controller = HomeController(userId: UserSession().userID)
      ..addListener(_onControllerChanged);
    _controller.loadPageData();
    _startAutoRefresh();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowTutorial());
  }

  //
  //   used for: cleaning up resources to prevent memory leaks.
  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    _autoRefreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  //
  //   used for: triggering a ui rebuild when the home controller updates.
  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  // automatically refreshes the home feeds while the home route is visible.
  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      _autoRefreshInterval,
      (_) => _refreshHomeAutomatically(),
    );
  }

  Future<void> _refreshHomeAutomatically() async {
    if (!mounted || _isAutoRefreshing || _controller.isLoadingEvents) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;

    _isAutoRefreshing = true;
    try {
      await _controller.loadEvents();
    } finally {
      _isAutoRefreshing = false;
    }
  }

  Future<void> _maybeShowTutorial() async {
    if (_hasCheckedTutorial || !mounted) return;
    _hasCheckedTutorial = true;

    final seenValue = await _dbGet.getUserData('has_seen_tutorial');
    final hasSeenTutorial = bool.tryParse(seenValue ?? 'false') ?? false;
    if (!mounted || hasSeenTutorial) return;

    // the tutorial is modal: once the user finishes or skips it, we mark it as
    // seen in supabase so it does not reappear on the next login/device.
    final bool completedHome = await VezCoachMarks.showHomeTutorial(context);
    if (!mounted) return;

    if (completedHome) {
      final bool completedCreate =
          await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateEvent(showTutorial: true),
            ),
          ) ??
          false;
      if (mounted && completedCreate) {
        await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => const ProfilePage(showTutorial: true),
          ),
        );
      }
    }

    if (!mounted) return;
    await _dbSet.updateUserData('has_seen_tutorial', true);
  }

  //
  //   used for: identifying the currently active event category filter.
  EventType get _selectedType => _isVenueAccount
      ? EventType.byYou
      : _filterIcons[_filterIndex]['type'] as EventType;

  //
  //   used for: retrieving the list of events to display based on selected filter.
  List<HomeEventCardData> get _visibleEvents =>
      _controller.eventsByType[_selectedType] ?? const [];

  //
  //   used for: determining if the "nearby" filter tab is currently active.
  bool get _isNearbySelected =>
      !_isVenueAccount && _selectedType == EventType.nearby;

  //
  //   used for: navigating to the user profile screen and refreshing data on return.
  void _goToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    ).then((_) async {
      if (!mounted) return;
      await Future.wait([
        _controller.loadProfilePhoto(),
        _controller.loadEvents(),
      ]);
    });
  }

  //
  //   used for: navigating to the event creation flow with haptic feedback.
  void _goToCreateEvent() {
    HapticService.tap();
    Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateEvent()),
    ).then((changed) async {
      if (changed == true && mounted) {
        await _controller.loadEvents();
      }
    });
  }

  //
  //   used for: navigating to the notifications list screen.
  void _goToNotifications() {
    if (_isVenueAccount) {
      _showSnackBar(StringRes.at('venue_notifications_disabled'));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
  }

  // save the card response selected from invited and nearby previews
  Future<void> _updateEventCardResponse(
    HomeEventCardData event,
    String responseState,
  ) async {
    final int result = await _controller.updateEventResponse(
      event: event,
      responseState: responseState,
    );

    if (!mounted || result == 200 || result == 204) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${StringRes.at("event_update_failed")} ($result)'),
        backgroundColor: const Color.fromARGB(200, 255, 49, 49),
      ),
    );
  }

  //
  //   used for: switching between event groups (invited, by you, nearby).
  void _selectFilter(int index) {
    if (_isVenueAccount) {
      _showSnackBar(StringRes.at('venue_filter_locked'));
      return;
    }

    setState(() => _filterIndex = index);
    final selectedType = _filterIcons[index]['type'] as EventType;
    if (selectedType == EventType.nearby) {
      _controller.loadNearbyEvents();
    }
  }

  //
  //   used for: opening the creation screen in edit mode for an existing event.
  void _editEvent(HomeEventCardData event) {
    HapticService.tap();
    Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CreateEvent(editingEvent: event)),
    ).then((changed) async {
      if (changed == true && mounted) {
        await _controller.loadEvents();
      }
    });
  }

  //
  //   used for: displaying and managing the list of people invited to an event.
  //   design: popup with search, status filters, and guest removal options.
  void _showGuestListPopup(HomeEventCardData event) {
    final TextEditingController searchController = TextEditingController();
    HomeEventCardData currentEvent = event;
    GuestStateFilter statusFilter = GuestStateFilter.all;
    bool isBusy = false;
    final double popupWidth = MediaQuery.of(context).size.width * 0.82;
    final double popupHeight = MediaQuery.of(context).size.height * 0.62;

    VezPopup.show(
      context: context,
      width: popupWidth,
      height: popupHeight,
      child: StatefulBuilder(
        builder: (context, setPopupState) {
          final List<HomeEventGuestData> visibleGuests = currentEvent.guests
              .where((guest) => _matchesGuestStateFilter(guest, statusFilter))
              .where(
                (guest) => guest.username.toLowerCase().contains(
                  searchController.text.trim().toLowerCase(),
                ),
              )
              .toList();

          Future<void> refreshCurrentEvent() async {
            final HomeEventCardData? refreshed = await _controller
                .refreshEventForType(currentEvent.eventId, currentEvent.type);
            if (refreshed == null) return;
            currentEvent = refreshed;
            _controller.upsertEvent(refreshed);
            setPopupState(() {});
          }

          Future<void> removeGuest(String userId) async {
            setPopupState(() => isBusy = true);
            final int res = await _controller.removeEventInvite(
              eventId: currentEvent.eventId,
              invitedUserId: userId,
            );
            if (res == 200 || res == 204) {
              await refreshCurrentEvent();
            } else {
              _showSnackBar(StringRes.at('guest_remove_failed'), isError: true);
            }
            setPopupState(() => isBusy = false);
          }

          return Column(
            children: [
              PopupHeaderBar(
                title: StringRes.at('guest_list'),
                onClose: () => Navigator.pop(context),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: PopupSearchField(
                        controller: searchController,
                        hint: StringRes.at('search_guest'),
                        onChanged: (_) => setPopupState(() {}),
                      ),
                    ),
                    if (currentEvent.canInviteGuests) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _showAddGuestPopup(currentEvent);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color.fromARGB(51, 0, 0, 0),
                            border: Border.all(
                              color: const Color.fromARGB(128, 255, 255, 255),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PopupFilterChip(
                      iconPath:
                          'assets/icons/event/participation_state/whoever_state.png',
                      fallbackIcon: Icons.group,
                      isActive: statusFilter == GuestStateFilter.all,
                      onTap: () => setPopupState(
                        () => statusFilter = GuestStateFilter.all,
                      ),
                    ),
                    PopupFilterChip(
                      iconPath:
                          'assets/icons/event/participation_state/going.png',
                      isActive: statusFilter == GuestStateFilter.going,
                      onTap: () => setPopupState(
                        () => statusFilter = GuestStateFilter.going,
                      ),
                    ),
                    PopupFilterChip(
                      iconPath:
                          'assets/icons/event/participation_state/not_going.png',
                      isActive: statusFilter == GuestStateFilter.notGoing,
                      onTap: () => setPopupState(
                        () => statusFilter = GuestStateFilter.notGoing,
                      ),
                    ),
                    PopupFilterChip(
                      iconPath:
                          'assets/icons/event/participation_state/maybe.png',
                      isActive: statusFilter == GuestStateFilter.maybe,
                      onTap: () => setPopupState(
                        () => statusFilter = GuestStateFilter.maybe,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    PopupGuestRow(
                      username: currentEvent.creatorUsername.isNotEmpty
                          ? currentEvent.creatorUsername
                          : StringRes.at('host'),
                      profilePhoto: currentEvent.creatorProfilePhoto,
                      state: 'going',
                      roleLabel: StringRes.at('host'),
                    ),
                    const SizedBox(height: 10),
                    if (visibleGuests.isEmpty)
                      PopupEmptyState(title: StringRes.at('no_guests_yet'))
                    else
                      ...visibleGuests.map(
                        (guest) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: PopupGuestRow(
                            username: guest.username,
                            profilePhoto: guest.profilePhoto,
                            state: guest.state,
                            guest: guest,
                            roleLabel: guest.isCohost
                                ? StringRes.at('cohost')
                                : null,
                            trailing:
                                currentEvent.isCurrentUserCohost ||
                                    currentEvent.isByYou
                                ? GestureDetector(
                                    onTap: isBusy
                                        ? null
                                        : () => removeGuest(guest.userId),
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color.fromARGB(
                                          128,
                                          255,
                                          49,
                                          49,
                                        ),
                                        border: Border.all(
                                          color: const Color.fromARGB(
                                            204,
                                            255,
                                            49,
                                            49,
                                          ),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Center(
                                        child: Image.asset(
                                          'assets/icons/profile_page/delete.png',
                                          width: 13,
                                          height: 13,
                                        ),
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: PopupCountsFooter(counts: currentEvent.guestCounts),
              ),
            ],
          );
        },
      ),
    ).whenComplete(searchController.dispose);
  }

  //
  //   used for: inviting new users to an event.
  //   design: popup with directory search and relationship filters.
  Future<void> _showAddGuestPopup(HomeEventCardData event) async {
    await _controller.ensureUserDirectoryLoaded();
    if (!mounted) return;

    final TextEditingController searchController = TextEditingController();
    HomeEventCardData currentEvent = event;
    GuestAudienceFilter audienceFilter = GuestAudienceFilter.friends;
    bool isBusy = false;
    final double popupWidth = MediaQuery.of(context).size.width * 0.82;
    final double popupHeight = MediaQuery.of(context).size.height * 0.62;

    VezPopup.show(
      context: context,
      width: popupWidth,
      height: popupHeight,
      child: StatefulBuilder(
        builder: (context, setPopupState) {
          final Set<String> excludedIds = {
            currentEvent.creatorUserId,
            ...currentEvent.guests.map((guest) => guest.userId),
          };

          final Set<String> friendIds = _controller.followingIds.intersection(
            _controller.followerIds,
          );

          final List<Map<String, dynamic>>
          candidates = _controller.allUsers.where((user) {
            final String userId = (user['user_id'] ?? '').toString();
            final String username = (user['username'] ?? '').toString();
            if (userId.isEmpty || excludedIds.contains(userId)) return false;

            final String query = searchController.text.trim().toLowerCase();
            if (query.isNotEmpty && !username.toLowerCase().contains(query)) {
              return false;
            }

            switch (audienceFilter) {
              case GuestAudienceFilter.friends:
                return friendIds.contains(userId);
              case GuestAudienceFilter.following:
                return _controller.followingIds.contains(userId);
              case GuestAudienceFilter.anyone:
                return true;
            }
          }).toList();

          Future<void> addGuest(String userId) async {
            setPopupState(() => isBusy = true);
            final int res = await _controller.addOrUpdateEventInvite(
              eventId: currentEvent.eventId,
              invitedUserId: userId,
            );
            if (res == 200 || res == 201 || res == 204) {
              final HomeEventCardData? refreshed = await _controller
                  .refreshEventForType(currentEvent.eventId, currentEvent.type);
              if (refreshed != null) {
                currentEvent = refreshed;
                _controller.upsertEvent(refreshed);
                setPopupState(() {});
              }
            } else {
              _showSnackBar(StringRes.at('guest_add_failed'), isError: true);
            }
            setPopupState(() => isBusy = false);
          }

          return Column(
            children: [
              PopupHeaderBar(
                title: StringRes.at('add_guest'),
                onClose: () => Navigator.pop(context),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: PopupSearchField(
                  controller: searchController,
                  hint: StringRes.at('search_guest'),
                  onChanged: (_) => setPopupState(() {}),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PopupFilterChip(
                      iconPath: 'assets/icons/event/friends.png',
                      isActive: audienceFilter == GuestAudienceFilter.friends,
                      onTap: () => setPopupState(
                        () => audienceFilter = GuestAudienceFilter.friends,
                      ),
                    ),
                    PopupFilterChip(
                      iconPath: 'assets/icons/event/following.png',
                      isActive: audienceFilter == GuestAudienceFilter.following,
                      onTap: () => setPopupState(
                        () => audienceFilter = GuestAudienceFilter.following,
                      ),
                    ),
                    PopupFilterChip(
                      iconPath: 'assets/icons/event/public.png',
                      isActive: audienceFilter == GuestAudienceFilter.anyone,
                      onTap: () => setPopupState(
                        () => audienceFilter = GuestAudienceFilter.anyone,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: candidates.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: PopupEmptyState(
                          title: StringRes.at('no_guests_found'),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: candidates.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, index) {
                          final Map<String, dynamic> user = candidates[index];
                          final String userId = (user['user_id'] ?? '')
                              .toString();

                          // determines the relationship icon.
                          String relationIconPath;
                          if (friendIds.contains(userId)) {
                            relationIconPath = 'assets/icons/event/friends.png';
                          } else if (_controller.followingIds.contains(
                            userId,
                          )) {
                            relationIconPath =
                                'assets/icons/event/following.png';
                          } else {
                            relationIconPath = 'assets/icons/event/public.png';
                          }

                          return PopupUserSelectionRow(
                            username: (user['username'] ?? '').toString(),
                            profilePhoto: (user['profile_photo'] ?? '')
                                .toString(),
                            relationIconPath: relationIconPath,
                            onAdd: isBusy ? null : () => addGuest(userId),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: PopupCountsFooter(counts: currentEvent.guestCounts),
              ),
            ],
          );
        },
      ),
    ).whenComplete(searchController.dispose);
  }

  Future<void> _showCohostManagerPopup(HomeEventCardData event) async {
    if (!event.canManageCohosts) return;

    await _controller.ensureUserDirectoryLoaded();
    if (!mounted) return;

    final TextEditingController searchController = TextEditingController();
    HomeEventCardData currentEvent = event;
    bool isBusy = false;
    final double popupWidth = MediaQuery.of(context).size.width * 0.86;
    final double popupHeight = MediaQuery.of(context).size.height * 0.68;

    VezPopup.show(
      context: context,
      width: popupWidth,
      height: popupHeight,
      child: StatefulBuilder(
        builder: (context, setPopupState) {
          final List<HomeEventGuestData> cohosts = currentEvent.cohosts;
          final Set<String> invitedIds = currentEvent.guests
              .map((guest) => guest.userId)
              .toSet();
          final Set<String> cohostIds = cohosts
              .map((guest) => guest.userId)
              .toSet();
          final String query = searchController.text.trim().toLowerCase();

          final List<HomeEventGuestData> promotableGuests = currentEvent.guests
              .where((guest) => !guest.isCohost)
              .where(
                (guest) =>
                    query.isEmpty ||
                    guest.username.toLowerCase().contains(query),
              )
              .toList();

          final List<Map<String, dynamic>> newCandidates = _controller.allUsers
              .where((user) {
                final String userId = (user['user_id'] ?? '').toString();
                final String username = (user['username'] ?? '').toString();
                if (userId.isEmpty ||
                    userId == currentEvent.creatorUserId ||
                    invitedIds.contains(userId) ||
                    cohostIds.contains(userId)) {
                  return false;
                }
                return query.isEmpty || username.toLowerCase().contains(query);
              })
              .toList();

          Future<void> refreshCurrentEvent() async {
            final HomeEventCardData? refreshed = await _controller
                .refreshEventForType(currentEvent.eventId, EventType.byYou);
            if (refreshed == null) return;
            currentEvent = refreshed;
            _controller.upsertEvent(refreshed);
            // the popup may close while the async refresh is running.
            // guard setpopupstate to avoid "dependent is no longer mounted".
            if (context.mounted) setPopupState(() {});
          }

          Future<void> saveRole(String userId, HomeEventRole role) async {
            // role updates can outlive the popup context, so every popup
            // state write is mounted-checked.
            if (context.mounted) setPopupState(() => isBusy = true);
            final int res = await _controller.updateEventInviteRole(
              eventId: currentEvent.eventId,
              invitedUserId: userId,
              role: role.encode(),
            );
            if (res == 200 || res == 204) {
              await refreshCurrentEvent();
            } else {
              _showSnackBar(
                StringRes.at('cohost_update_failed'),
                isError: true,
              );
            }
            if (context.mounted) setPopupState(() => isBusy = false);
          }

          Future<void> addCohost(
            String userId, {
            required bool alreadyGuest,
          }) async {
            if (cohosts.length >= 5) {
              _showSnackBar(
                StringRes.at('cohost_limit_reached'),
                isError: true,
              );
              return;
            }

            if (context.mounted) setPopupState(() => isBusy = true);
            final int res = alreadyGuest
                ? await _controller.updateEventInviteRole(
                    eventId: currentEvent.eventId,
                    invitedUserId: userId,
                    role: HomeEventRole.fullCohost.encode(),
                  )
                : await _controller.addOrUpdateEventInvite(
                    eventId: currentEvent.eventId,
                    invitedUserId: userId,
                    role: HomeEventRole.fullCohost.encode(),
                  );
            if (res == 200 || res == 201 || res == 204) {
              await refreshCurrentEvent();
            } else {
              _showSnackBar(
                StringRes.at('cohost_update_failed'),
                isError: true,
              );
            }
            if (context.mounted) setPopupState(() => isBusy = false);
          }

          return Column(
            children: [
              PopupHeaderBar(
                title: '${StringRes.at('cohosts')} - ${cohosts.length}/5',
                onClose: () => Navigator.pop(context),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: PopupSearchField(
                  controller: searchController,
                  hint: StringRes.at('search_guest'),
                  onChanged: (_) => setPopupState(() {}),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (cohosts.isNotEmpty) ...[
                      PopupSectionLabel(label: StringRes.at('cohosts')),
                      const SizedBox(height: 8),
                      ...cohosts.map(
                        (guest) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: CohostPermissionRow(
                            guest: guest,
                            isBusy: isBusy,
                            onDemote: () =>
                                saveRole(guest.userId, HomeEventRole.guest),
                          ),
                        ),
                      ),
                    ],
                    PopupSectionLabel(label: StringRes.at('add_cohost')),
                    const SizedBox(height: 8),
                    if (promotableGuests.isEmpty && newCandidates.isEmpty)
                      PopupEmptyState(title: StringRes.at('no_guests_found'))
                    else ...[
                      ...promotableGuests.map(
                        (guest) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: PopupGuestRow(
                            username: guest.username,
                            profilePhoto: guest.profilePhoto,
                            state: guest.state,
                            trailing: PopupMiniActionButton(
                              icon: Icons.admin_panel_settings_rounded,
                              color: const Color(0xFF55D6FF),
                              onTap: isBusy
                                  ? null
                                  : () => addCohost(
                                      guest.userId,
                                      alreadyGuest: true,
                                    ),
                            ),
                          ),
                        ),
                      ),
                      ...newCandidates.map(
                        (user) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: PopupUserSelectionRow(
                            username: (user['username'] ?? '').toString(),
                            profilePhoto: (user['profile_photo'] ?? '')
                                .toString(),
                            relationIconPath: 'assets/icons/event/public.png',
                            onAdd: isBusy
                                ? null
                                : () => addCohost(
                                    (user['user_id'] ?? '').toString(),
                                    alreadyGuest: false,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ).whenComplete(searchController.dispose);
  }

  //
  //   used for: logic to filter guests by their current rsvp state.
  bool _matchesGuestStateFilter(
    HomeEventGuestData guest,
    GuestStateFilter filter,
  ) {
    switch (filter) {
      case GuestStateFilter.all:
        return true;
      case GuestStateFilter.going:
        return guest.state == 'going';
      case GuestStateFilter.notGoing:
        return guest.state == 'not_going';
      case GuestStateFilter.maybe:
        return guest.state == 'maybe';
    }
  }

  //
  //   used for: providing brief feedback or error messages to the user.
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color.fromARGB(200, 255, 49, 49)
            : const Color.fromARGB(200, 8, 157, 13),
      ),
    );
  }

  //
  //   used for: retrieving the appropriate title for the empty state ui.
  String? _emptyStateTitle() {
    switch (_selectedType) {
      case EventType.byYou:
        return StringRes.at('no_events_by_you');
      case EventType.cohost:
        return null;
      case EventType.invited:
        return StringRes.at('no_events_invited');
      case EventType.nearby:
        return StringRes.at('no_events_nearby');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final double s = (sw / 390).clamp(0.8, 1.2);

    return VezPageLayout(
      // search area
      searchController: _searchController,
      searchHint: StringRes.at('search'),

      // left button
      profileIconPath: _controller.profilePhoto,
      isProfileAvatar: true,
      onProfileTap: _goToProfile,

      // right button
      isFilterSelected: true,
      onFilterTap: null,
      filterIconPath: _isVenueAccount
          ? _filterIcons[_byYouFilterIndex]['icon'] as String
          : _filterIcons[_filterIndex]['icon'] as String,
      onFilterSelected: _selectFilter,
      isFilterEnabled: !_isVenueAccount,
      bottomNavBar: HomeBottomNavPill(
        s: s,
        activeIndex: 0,
        onHomeTap: () {},
        onCreateEventTap: _goToCreateEvent,
        onNotificationsTap: _goToNotifications,
      ),

      body: Stack(
        children: [
          Positioned.fill(
            child: HomeEventCarousel(
              events: _visibleEvents,
              s: s,
              isLoading:
                  _controller.isLoadingEvents || _controller.isLoadingNearby,
              emptyStateTitle: _emptyStateTitle(),
              emptyStateIconPath: _emptyStateIcon,
              highlightedEventId: widget.initialEventId,
              onAddGuestsTap: _showAddGuestPopup,
              onGuestListTap: _showGuestListPopup,
              onManageCohostsTap: _showCohostManagerPopup,
              onEditTap: _editEvent,
              onResponseSelected: _updateEventCardResponse,
            ),
          ),
          if (_isNearbySelected)
            Positioned(
              top: MediaQuery.of(context).padding.top + 82 * s,
              left: 0,
              right: 0,
              child: NearbyRangeControl(
                s: s,
                radiusKm: _controller.nearbyRadiusKm,
                isLoading: _controller.isLoadingNearby,
                error: _controller.nearbyError,
                onRadiusChanged: _controller.updateNearbyRadius,
                onRefreshPosition: () =>
                    _controller.loadNearbyEvents(refreshPosition: true),
              ),
            ),
        ],
      ),
    );
  }
}
