import 'package:flutter/material.dart';

import '../controllers/home_controller.dart';
import '../models/home_event.dart';
import '../services/haptic_service.dart';
import '../services/translation_service.dart';
import '../services/user_session.dart';
import '../views/widgets/vez_event_card.dart';
import '../views/widgets/vez_glass.dart';
import '../views/widgets/vez_page_layout.dart';
import '../views/widgets/vez_popup.dart';
import 'create_event/create_event_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

// ── guest audience filter ──────────────────────────────────────────────────
//
//   used for: defining the target audience when inviting guests.
//   design: enum representing friends, followed users, or anyone.
enum _GuestAudienceFilter { friends, following, anyone }

// ── guest state filter ─────────────────────────────────────────────────────
//
//   used for: filtering the guest list by their RSVP status.
//   design: enum covering all, going, not going, and maybe statuses.
enum _GuestStateFilter { all, going, notGoing, maybe }

// ── home page ──────────────────────────────────────────────────────────────
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

// ── home page state ────────────────────────────────────────────────────────
//
//   used for: managing the lifecycle and UI state of the home screen.
//   design: handles data fetching, filtering, and popup orchestration.
class _HomePageState extends State<HomePage> {
  static const String _emptyStateIcon =
      'assets/icons/home_page/no_event_found.png';

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

  final TextEditingController _searchController = TextEditingController();
  late final HomeController _controller;

  late int _filterIndex;

  // ── init state ─────────────────────────────────────────────────────────────
  //
  //   used for: initializing controllers and loading initial page data.
  @override
  void initState() {
    super.initState();
    _filterIndex = widget.initialFilterIndex.clamp(0, _filterIcons.length - 1);
    _controller = HomeController(userId: UserSession().userID)
      ..addListener(_onControllerChanged);
    _controller.loadPageData();
  }

  // ── dispose ────────────────────────────────────────────────────────────────
  //
  //   used for: cleaning up resources to prevent memory leaks.
  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── on controller changed ──────────────────────────────────────────────────
  //
  //   used for: triggering a UI rebuild when the home controller updates.
  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  // ── selected type ──────────────────────────────────────────────────────────
  //
  //   used for: identifying the currently active event category filter.
  EventType get _selectedType =>
      _filterIcons[_filterIndex]['type'] as EventType;

  // ── visible events ─────────────────────────────────────────────────────────
  //
  //   used for: retrieving the list of events to display based on selected filter.
  List<HomeEventCardData> get _visibleEvents =>
      _controller.eventsByType[_selectedType] ?? const [];

  // ── is nearby selected ─────────────────────────────────────────────────────
  //
  //   used for: determining if the "nearby" filter tab is currently active.
  bool get _isNearbySelected => _selectedType == EventType.nearby;

  // ── go to profile ──────────────────────────────────────────────────────────
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

  // ── go to create event ─────────────────────────────────────────────────────
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

  // ── go to notifications ────────────────────────────────────────────────────
  //
  //   used for: navigating to the notifications list screen.
  void _goToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
  }

  // ── select filter ──────────────────────────────────────────────────────────
  //
  //   used for: switching between event categories (Invited, By You, Nearby).
  void _selectFilter(int index) {
    setState(() => _filterIndex = index);
    final selectedType = _filterIcons[index]['type'] as EventType;
    if (selectedType == EventType.nearby) {
      _controller.loadNearbyEvents();
    }
  }

  // ── edit event ─────────────────────────────────────────────────────────────
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

  // ── show guest list popup ──────────────────────────────────────────────────
  //
  //   used for: displaying and managing the list of people invited to an event.
  //   design: popup with search, status filters, and guest removal options.
  void _showGuestListPopup(HomeEventCardData event) {
    final TextEditingController searchController = TextEditingController();
    HomeEventCardData currentEvent = event;
    _GuestStateFilter statusFilter = _GuestStateFilter.all;
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
                .refreshByYouEvent(currentEvent.eventId);
            if (refreshed == null) return;
            currentEvent = refreshed;
            _controller.upsertByYouEvent(refreshed);
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
              _PopupHeaderBar(
                title: StringRes.at('guest_list'),
                onClose: () => Navigator.pop(context),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _PopupSearchField(
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
                            border: Border.all(color: const Color.fromARGB(128, 255, 255, 255), width: 2),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 25),
                        ),
                      ),
                    ]
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
                    _PopupFilterChip(
                      iconPath: 'assets/icons/event/participation_state/whoever_state.png',
                      fallbackIcon: Icons.group,
                      isActive: statusFilter == _GuestStateFilter.all,
                      onTap: () => setPopupState(
                            () => statusFilter = _GuestStateFilter.all,
                      ),
                    ),
                    _PopupFilterChip(
                      iconPath: 'assets/icons/event/participation_state/going.png',
                      isActive: statusFilter == _GuestStateFilter.going,
                      onTap: () => setPopupState(
                            () => statusFilter = _GuestStateFilter.going,
                      ),
                    ),
                    _PopupFilterChip(
                      iconPath: 'assets/icons/event/participation_state/not_going.png',
                      isActive: statusFilter == _GuestStateFilter.notGoing,
                      onTap: () => setPopupState(
                            () => statusFilter = _GuestStateFilter.notGoing,
                      ),
                    ),
                    _PopupFilterChip(
                      iconPath: 'assets/icons/event/participation_state/maybe.png',
                      isActive: statusFilter == _GuestStateFilter.maybe,
                      onTap: () => setPopupState(
                            () => statusFilter = _GuestStateFilter.maybe,
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
                    _PopupGuestRow(
                      username: currentEvent.creatorUsername.isNotEmpty
                          ? currentEvent.creatorUsername
                          : StringRes.at('host'),
                      profilePhoto: currentEvent.creatorProfilePhoto,
                      state: 'going',
                      roleLabel: StringRes.at('host'),
                    ),
                    const SizedBox(height: 10),
                    if (visibleGuests.isEmpty)
                      _PopupEmptyState(title: StringRes.at('no_guests_yet'))
                    else
                      ...visibleGuests.map(
                            (guest) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PopupGuestRow(
                            username: guest.username,
                            profilePhoto: guest.profilePhoto,
                            state: guest.state,
                            trailing: currentEvent.canInviteGuests
                                ? GestureDetector(
                              onTap: isBusy
                                  ? null
                                  : () => removeGuest(guest.userId),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color.fromARGB(128, 255, 49, 49),
                                  border: Border.all(
                                    color: const Color.fromARGB(204, 255, 49, 49),
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
                child: _PopupCountsFooter(counts: currentEvent.guestCounts),
              ),
            ],
          );
        },
      ),
    ).whenComplete(searchController.dispose);
  }

  // ── show add guest popup ───────────────────────────────────────────────────
  //
  //   used for: inviting new users to an event.
  //   design: popup with directory search and relationship filters.
  Future<void> _showAddGuestPopup(HomeEventCardData event) async {
    await _controller.ensureUserDirectoryLoaded();
    if (!mounted) return;

    final TextEditingController searchController = TextEditingController();
    HomeEventCardData currentEvent = event;
    _GuestAudienceFilter audienceFilter = _GuestAudienceFilter.friends;
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
              case _GuestAudienceFilter.friends:
                return friendIds.contains(userId);
              case _GuestAudienceFilter.following:
                return _controller.followingIds.contains(userId);
              case _GuestAudienceFilter.anyone:
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
                  .refreshByYouEvent(currentEvent.eventId);
              if (refreshed != null) {
                currentEvent = refreshed;
                _controller.upsertByYouEvent(refreshed);
                setPopupState(() {});
              }
            } else {
              _showSnackBar(StringRes.at('guest_add_failed'), isError: true);
            }
            setPopupState(() => isBusy = false);
          }

          return Column(
            children: [
              _PopupHeaderBar(
                title: StringRes.at('add_guest'),
                onClose: () => Navigator.pop(context),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _PopupSearchField(
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
                    _PopupFilterChip(
                      iconPath: 'assets/icons/event/friends.png',
                      isActive: audienceFilter == _GuestAudienceFilter.friends,
                      onTap: () => setPopupState(
                            () => audienceFilter = _GuestAudienceFilter.friends,
                      ),
                    ),
                    _PopupFilterChip(
                      iconPath: 'assets/icons/event/following.png',
                      isActive: audienceFilter == _GuestAudienceFilter.following,
                      onTap: () => setPopupState(
                            () => audienceFilter = _GuestAudienceFilter.following,
                      ),
                    ),
                    _PopupFilterChip(
                      iconPath: 'assets/icons/event/public.png',
                      isActive: audienceFilter == _GuestAudienceFilter.anyone,
                      onTap: () => setPopupState(
                            () => audienceFilter = _GuestAudienceFilter.anyone,
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
                  child: _PopupEmptyState(
                    title: StringRes.at('no_guests_found'),
                  ),
                )
                    : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: candidates.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final Map<String, dynamic> user = candidates[index];
                    final String userId = (user['user_id'] ?? '').toString();

                    // Determiniamo l'icona della relazione
                    String relationIconPath;
                    if (friendIds.contains(userId)) {
                      relationIconPath = 'assets/icons/event/friends.png';
                    } else if (_controller.followingIds.contains(userId)) {
                      relationIconPath = 'assets/icons/event/following.png';
                    } else {
                      relationIconPath = 'assets/icons/event/public.png';
                    }

                    return _PopupUserSelectionRow(
                      username: (user['username'] ?? '').toString(),
                      profilePhoto: (user['profile_photo'] ?? '').toString(),
                      relationIconPath: relationIconPath,
                      onAdd: isBusy ? null : () => addGuest(userId),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _PopupCountsFooter(counts: currentEvent.guestCounts),
              ),
            ],
          );
        },
      ),
    ).whenComplete(searchController.dispose);
  }

  // ── matches guest state filter ─────────────────────────────────────────────
  //
  //   used for: logic to filter guests by their current RSVP state.
  bool _matchesGuestStateFilter(
      HomeEventGuestData guest,
      _GuestStateFilter filter,
      ) {
    switch (filter) {
      case _GuestStateFilter.all:
        return true;
      case _GuestStateFilter.going:
        return guest.state == 'going';
      case _GuestStateFilter.notGoing:
        return guest.state == 'not_going';
      case _GuestStateFilter.maybe:
        return guest.state == 'maybe';
    }
  }

  // ── show snack bar ─────────────────────────────────────────────────────────
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

  // ── empty state title ──────────────────────────────────────────────────────
  //
  //   used for: retrieving the appropriate title for the empty state UI.
  String _emptyStateTitle() {
    switch (_selectedType) {
      case EventType.byYou:
        return StringRes.at('no_events_by_you');
      case EventType.invited:
        return StringRes.at('no_events_invited');
      case EventType.nearby:
        return StringRes.at('no_events_nearby');
    }
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final double s = (sw / 390).clamp(0.8, 1.2);

    return VezPageLayout(
      searchController: _searchController,
      searchHint: StringRes.at('search'),
      profileIconPath: _controller.profilePhoto,
      isProfileAvatar: true,
      onProfileTap: _goToProfile,
      filterIconPath: _filterIcons[_filterIndex]['icon'] as String,
      onFilterSelected: _selectFilter,
      bottomNavBar: _BottomNavPill(
        s: s,
        activeIndex: 0,
        onHomeTap: () {},
        onCreateEventTap: _goToCreateEvent,
        onNotificationsTap: _goToNotifications,
      ),
      body: Padding(
        padding: EdgeInsets.only(top: _isNearbySelected ? 108 * s : 0),
        child: Column(
          children: [
            if (_isNearbySelected)
              _NearbyRangeControl(
                s: s,
                radiusKm: _controller.nearbyRadiusKm,
                isLoading: _controller.isLoadingNearby,
                error: _controller.nearbyError,
                eventCount: _visibleEvents.length,
                onRadiusChanged: _controller.updateNearbyRadius,
                onRefreshPosition: () =>
                    _controller.loadNearbyEvents(refreshPosition: true),
              ),
            Expanded(
              child: _EventCarousel(
                events: _visibleEvents,
                s: s,
                isLoading:
                _controller.isLoadingEvents || _controller.isLoadingNearby,
                emptyStateTitle: _emptyStateTitle(),
                emptyStateIconPath: _emptyStateIcon,
                highlightedEventId: widget.initialEventId,
                onAddGuestsTap: _showAddGuestPopup,
                onGuestListTap: _showGuestListPopup,
                onEditTap: _editEvent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── nearby range control ────────────────────────────────────────────────────
//
//   used for: adjusting the distance radius for nearby event discovery.
//   design: glassy container with radius display, refresh button, and slider.
class _NearbyRangeControl extends StatelessWidget {
  const _NearbyRangeControl({
    required this.s,
    required this.radiusKm,
    required this.isLoading,
    required this.error,
    required this.eventCount,
    required this.onRadiusChanged,
    required this.onRefreshPosition,
  });

  final double s;
  final double radiusKm;
  final bool isLoading;
  final String error;
  final int eventCount;
  final ValueChanged<double> onRadiusChanged;
  final VoidCallback onRefreshPosition;

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final roundedRadius = radiusKm.round();

    return Padding(
      padding: EdgeInsets.fromLTRB(20 * s, 0, 20 * s, 8 * s),
      child: VezGlass.container(
        padding: EdgeInsets.fromLTRB(16 * s, 12 * s, 12 * s, 10 * s),
        radius: BorderRadius.circular(28 * s),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    error.isNotEmpty
                        ? error
                        : '$roundedRadius km - $eventCount eventi',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15 * s,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: isLoading ? null : onRefreshPosition,
                  icon: isLoading
                      ? SizedBox(
                    width: 18 * s,
                    height: 18 * s,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.my_location, color: Colors.white),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.white,
                overlayColor: const Color.fromARGB(40, 255, 255, 255),
                valueIndicatorColor: Colors.white,
                valueIndicatorTextStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Slider(
                min: 1,
                max: 100,
                divisions: 99,
                label: '$roundedRadius km',
                value: radiusKm.clamp(1, 100),
                onChanged: isLoading ? null : onRadiusChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── event carousel ──────────────────────────────────────────────────────────
//
//   used for: displaying a vertical list of event cards.
//   design: vertical PageView that supports highlighting specific events.
class _EventCarousel extends StatefulWidget {
  const _EventCarousel({
    required this.events,
    required this.s,
    required this.isLoading,
    required this.emptyStateTitle,
    required this.emptyStateIconPath,
    required this.highlightedEventId,
    required this.onAddGuestsTap,
    required this.onGuestListTap,
    required this.onEditTap,
  });

  final List<HomeEventCardData> events;
  final double s;
  final bool isLoading;
  final String emptyStateTitle;
  final String emptyStateIconPath;
  final String? highlightedEventId;
  final ValueChanged<HomeEventCardData> onAddGuestsTap;
  final ValueChanged<HomeEventCardData> onGuestListTap;
  final ValueChanged<HomeEventCardData> onEditTap;

  @override
  State<_EventCarousel> createState() => _EventCarouselState();
}

// ── event carousel state ────────────────────────────────────────────────────
//
//   used for: managing carousel scroll position and event highlighting logic.
class _EventCarouselState extends State<_EventCarousel> {
  late final PageController _controller;
  String? _lastJumpedEventId;

  // ── init state ─────────────────────────────────────────────────────────────
  //
  //   used for: initializing the page controller and handling post-frame jumps.
  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.75);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeJumpToEvent());
  }

  // ── did update widget ──────────────────────────────────────────────────────
  //
  //   used for: checking if the highlighted event has changed to perform a jump.
  @override
  void didUpdateWidget(covariant _EventCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events != widget.events ||
        oldWidget.highlightedEventId != widget.highlightedEventId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeJumpToEvent());
    }
  }

  // ── maybe jump to event ────────────────────────────────────────────────────
  //
  //   used for: automatically scrolling to a specific event ID if requested.
  void _maybeJumpToEvent() {
    if (!mounted || !_controller.hasClients) return;

    final String? eventId = widget.highlightedEventId?.trim();
    if (eventId == null || eventId.isEmpty || eventId == _lastJumpedEventId) {
      return;
    }

    final int targetIndex = widget.events.indexWhere(
          (event) => event.eventId == eventId,
    );
    if (targetIndex < 0) return;

    _controller.jumpToPage(targetIndex);
    _lastJumpedEventId = eventId;
  }

  // ── dispose ────────────────────────────────────────────────────────────────
  //
  //   used for: disposing the page controller.
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (widget.events.isEmpty) {
      return _EmptyEventsState(
        s: widget.s,
        title: widget.emptyStateTitle,
        iconPath: widget.emptyStateIconPath,
      );
    }

    return PageView.builder(
      scrollDirection: Axis.vertical,
      controller: _controller,
      itemCount: widget.events.length,
      itemBuilder: (context, index) {
        final HomeEventCardData event = widget.events[index];
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 6 * widget.s),
          child: VezEventCard(
            event: event,
            onAddGuestsTap: event.canInviteGuests
                ? () => widget.onAddGuestsTap(event)
                : null,
            onGuestListTap: event.isByYou
                ? () => widget.onGuestListTap(event)
                : null,
            onEditTap: event.isByYou ? () => widget.onEditTap(event) : null,
          ),
        );
      },
    );
  }
}

// ── empty events state ──────────────────────────────────────────────────────
//
//   used for: displaying a placeholder when no events match the current filter.
//   design: centered icon and text within the event carousel area.
class _EmptyEventsState extends StatelessWidget {
  const _EmptyEventsState({
    required this.s,
    required this.title,
    required this.iconPath,
  });

  final double s;
  final String title;
  final String iconPath;

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28 * s),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              iconPath,
              width: 90 * s,
              height: 90 * s,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 18 * s),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20 * s,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── bottom nav pill ─────────────────────────────────────────────────────────
//
//   used for: main navigation controls at the bottom of the home screen.
//   design: glassy capsule containing home, create, and notification actions.
class _BottomNavPill extends StatelessWidget {
  const _BottomNavPill({
    required this.s,
    required this.activeIndex,
    required this.onHomeTap,
    required this.onCreateEventTap,
    required this.onNotificationsTap,
  });

  final double s;
  final int activeIndex;
  final VoidCallback onHomeTap;
  final VoidCallback onCreateEventTap;
  final VoidCallback onNotificationsTap;

  // ── build ──────────────────────────────────────────────────────────────────
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

// ── popup header bar ───────────────────────────────────────────────────────
//
//   used for: the top section of popup windows.
//   design: contains title, close button, and an optional custom action icon.
class _PopupHeaderBar extends StatelessWidget {
  const _PopupHeaderBar({
    required this.title,
    required this.onClose,
  });

  final String title;
  final VoidCallback onClose;

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color.fromARGB(51, 0, 0, 0),
                border: Border.all(color: const Color.fromARGB(128, 255, 255, 255), width: 2),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 25),
            ),
          ),
        ],
      ),
    );
  }
}

// ── popup search field ─────────────────────────────────────────────────────
//
//   used for: searching through lists within a popup.
//   design: glassy text field with search icon and custom hints.
class _PopupSearchField extends StatelessWidget {
  const _PopupSearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return VezGlass.textField(
      controller: controller,
      hint: hint,
      height: 40,
      fontSize: 17,
      prefixIcon: const Icon(Icons.search, color: Colors.white),
      color: Colors.white,
      onChanged: onChanged,
    );
  }
}

// ── popup filter chip ──────────────────────────────────────────────────────
//
//   used for: selecting categories or states within a popup.
//   design: styled chip with border, translucent background, and icon reference.
class _PopupFilterChip extends StatelessWidget {
  const _PopupFilterChip({
    this.iconPath,
    this.fallbackIcon,
    required this.isActive,
    required this.onTap,
  });

  final String? iconPath;
  final IconData? fallbackIcon;
  final bool isActive;
  final VoidCallback onTap;

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color.fromARGB(179, 0, 0, 0),
          border: Border.all(
            color: isActive ? Colors.white70 : Colors.white30,
            width: 2,
          ),
        ),
        child: iconPath != null
            ? Image.asset(iconPath!, width: 20, height: 20)
            : Icon(fallbackIcon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ── popup guest row ────────────────────────────────────────────────────────
//
//   used for: displaying a single guest in the guest list popup.
//   design: row with avatar, name, optional action, and status icon.
class _PopupGuestRow extends StatelessWidget {
  const _PopupGuestRow({
    required this.username,
    required this.profilePhoto,
    required this.state,
    this.roleLabel,
    this.trailing,
  });

  final String username;
  final String profilePhoto;
  final String state;
  final String? roleLabel;
  final Widget? trailing;

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color.fromARGB(51, 0, 0, 0),
        border: Border.all(color: const Color.fromARGB(128, 255, 255, 255), width: 2),
      ),
      child: Row(
        children: [
          _PopupUserAvatar(photo: profilePhoto),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    username.isNotEmpty ? username : 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (roleLabel == null) _PopupStateIcon(state: state), // no state for the host
          if (roleLabel != null) _RoleBadge(label: roleLabel!), // "host" target for the host

          if (trailing != null) ...[ // remove guest buttons
            const SizedBox(width: 13), // space from the state icon
            trailing!
          ],
        ],
      ),
    );
  }
}

// ── popup user action row ──────────────────────────────────────────────────
//
//   used for: displaying users that can be interacted with (e.g., invited).
//   design: row with avatar, name, relationship label, and action icon.
class _PopupUserSelectionRow extends StatelessWidget {
  const _PopupUserSelectionRow({
    required this.username,
    required this.profilePhoto,
    required this.relationIconPath,
    required this.onAdd,
  });

  final String username;
  final String profilePhoto;
  final String relationIconPath;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color.fromARGB(51, 0, 0, 0),
        border: Border.all(
          color: const Color.fromARGB(128, 255, 255, 255),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          _PopupUserAvatar(photo: profilePhoto),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              username.isNotEmpty ? username : 'User',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Icona della correlazione (Bianca)
          Image.asset(
            relationIconPath,
            width: 24,
            height: 24,
            color: Colors.white,
          ),
          const SizedBox(width: 13),
          // Icona per aggiungere l'utente (Verde)
          GestureDetector(
            onTap: onAdd,
            child: const Icon(
              Icons.person_add_alt_1_rounded, // Quella che usavi prima o la tua custom
              color: Color(0xFF089D0D),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

// ── popup user avatar ──────────────────────────────────────────────────────
//
//   used for: displaying a circular user profile picture within popups.
//   design: handles both network and asset images with a placeholder icon.
class _PopupUserAvatar extends StatelessWidget {
  const _PopupUserAvatar({required this.photo});

  final String photo;

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bool isNetworkImage = photo.startsWith('http');

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white30, width: 2),
      ),
      child: ClipOval(
        child: photo.isEmpty
            ? const Icon(Icons.person, color: Colors.white70, size: 18)
            : Image(
          image: isNetworkImage
              ? NetworkImage(photo)
              : AssetImage(photo) as ImageProvider,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

// ── popup state icon ───────────────────────────────────────────────────────
//
//   used for: visual representation of a guest's participation status.
//   design: displays different icons for going, not going, or maybe.
class _PopupStateIcon extends StatelessWidget {
  const _PopupStateIcon({required this.state});

  final String state;

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final String iconPath = switch (state) {
      'going' => 'assets/icons/event/participation_state/going.png',
      'not_going' => 'assets/icons/event/participation_state/not_going.png',
      _ => 'assets/icons/event/participation_state/maybe.png',
    };

    return Image.asset(iconPath, width: 22, height: 22);
  }
}

// ── popup counts footer ────────────────────────────────────────────────────
//
//   used for: summarizing RSVP totals at the bottom of the guest list popup.
//   design: horizontal bar showing counts for going, not going, and maybe.
class _PopupCountsFooter extends StatelessWidget {
  const _PopupCountsFooter({required this.counts});

  final HomeEventGuestCounts counts;

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: const Color.fromARGB(51, 0, 0, 0),
        border: Border.all(color: const Color.fromARGB(128, 255, 255, 255), width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PopupCountItem(
              iconPath: 'assets/icons/event/participation_state/going.png',
              label: StringRes.at('going'),
              value: counts.going,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _PopupCountItem(
              iconPath: 'assets/icons/event/participation_state/not_going.png',
              label: StringRes.at('not_going'),
              value: counts.notGoing,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _PopupCountItem(
              iconPath: 'assets/icons/event/participation_state/maybe.png',
              label: StringRes.at('maybe'),
              value: counts.maybe,
            ),
          ),
        ],
      ),
    );
  }
}

// ── popup count item ───────────────────────────────────────────────────────
//
//   used for: a single statistic entry within the counts footer.
//   design: vertical stack of icon, label, and numeric value.
class _PopupCountItem extends StatelessWidget {
  const _PopupCountItem({
    required this.iconPath,
    required this.label,
    required this.value,
  });

  final String iconPath;
  final String label;
  final int value;

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(iconPath, width: 22, height: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ── popup empty state ──────────────────────────────────────────────────────
//
//   used for: displaying a message when a popup list has no items.
//   design: glassy container with centered descriptive text.
class _PopupEmptyState extends StatelessWidget {
  const _PopupEmptyState({required this.title});

  final String title;

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color.fromARGB(51, 0, 0, 0),
        border: Border.all(color: const Color.fromARGB(128, 255, 255, 255), width: 2),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 30
        ),
      ),
    );
  }
}

// ── role badge ─────────────────────────────────────────────────────────────
//
//   used for: highlighting a user's role (e.g., "Host").
//   design: small, colored capsule with bold text.
class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label});

  final String label;

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Text(
        label,
        style: const TextStyle(
          color: Color.fromARGB(255, 255, 195, 0),
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}