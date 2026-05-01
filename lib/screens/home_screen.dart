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

enum _GuestAudienceFilter { friends, following, anyone }

enum _GuestStateFilter { all, going, notGoing, maybe }

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.initialFilterIndex = 0, this.initialEventId});

  final int initialFilterIndex;
  final String? initialEventId;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _emptyStateIcon =
      'assets/icons/home_page/no_event_found.png';

  static const List<Map<String, dynamic>> _filterIcons = [
    {
      'icon': 'assets/icons/home_page/by_you_events.png',
      'type': EventType.byYou,
    },
    {
      'icon': 'assets/icons/home_page/invited_events.png',
      'type': EventType.invited,
    },
    {
      'icon': 'assets/icons/home_page/nearby_events.png',
      'type': EventType.nearby,
    },
  ];

  final TextEditingController _searchController = TextEditingController();
  late final HomeController _controller;

  late int _filterIndex;

  @override
  void initState() {
    super.initState();
    _filterIndex = widget.initialFilterIndex.clamp(0, _filterIcons.length - 1);
    _controller = HomeController(userId: UserSession().userID)
      ..addListener(_onControllerChanged);
    _controller.loadPageData();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  EventType get _selectedType =>
      _filterIcons[_filterIndex]['type'] as EventType;

  List<HomeEventCardData> get _visibleEvents =>
      _controller.eventsByType[_selectedType] ?? const [];

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

  void _goToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
  }

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
                action: currentEvent.canInviteGuests
                    ? IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showAddGuestPopup(currentEvent);
                        },
                        icon: const Icon(Icons.add, color: Colors.white),
                      )
                    : null,
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
                      label: StringRes.at('all'),
                      isActive: statusFilter == _GuestStateFilter.all,
                      onTap: () => setPopupState(
                        () => statusFilter = _GuestStateFilter.all,
                      ),
                    ),
                    _PopupFilterChip(
                      label: StringRes.at('going'),
                      isActive: statusFilter == _GuestStateFilter.going,
                      onTap: () => setPopupState(
                        () => statusFilter = _GuestStateFilter.going,
                      ),
                    ),
                    _PopupFilterChip(
                      label: StringRes.at('not_going'),
                      isActive: statusFilter == _GuestStateFilter.notGoing,
                      onTap: () => setPopupState(
                        () => statusFilter = _GuestStateFilter.notGoing,
                      ),
                    ),
                    _PopupFilterChip(
                      label: StringRes.at('maybe'),
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
                      trailing: _RoleBadge(label: StringRes.at('host')),
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
                                ? IconButton(
                                    onPressed: isBusy
                                        ? null
                                        : () => removeGuest(guest.userId),
                                    icon: const Icon(
                                      Icons.remove_circle_rounded,
                                      color: Color(0xFFFF3131),
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
                      label: StringRes.at('friends'),
                      isActive: audienceFilter == _GuestAudienceFilter.friends,
                      onTap: () => setPopupState(
                        () => audienceFilter = _GuestAudienceFilter.friends,
                      ),
                    ),
                    _PopupFilterChip(
                      label: StringRes.at('following'),
                      isActive:
                          audienceFilter == _GuestAudienceFilter.following,
                      onTap: () => setPopupState(
                        () => audienceFilter = _GuestAudienceFilter.following,
                      ),
                    ),
                    _PopupFilterChip(
                      label: StringRes.at('anyone'),
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
                          title: StringRes.at('no_users_found'),
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
                          return _PopupUserActionRow(
                            username: (user['username'] ?? '').toString(),
                            profilePhoto: (user['profile_photo'] ?? '')
                                .toString(),
                            label: _controller.relationLabel(userId),
                            icon: Icons.person_add_alt_1_rounded,
                            iconColor: const Color(0xFF089D0D),
                            onTap: isBusy ? null : () => addGuest(userId),
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
      onFilterSelected: (index) => setState(() => _filterIndex = index),
      bottomNavBar: _BottomNavPill(
        s: s,
        activeIndex: 0,
        onHomeTap: () {},
        onCreateEventTap: _goToCreateEvent,
        onNotificationsTap: _goToNotifications,
      ),
      body: _EventCarousel(
        events: _visibleEvents,
        s: s,
        isLoading: _controller.isLoadingEvents,
        emptyStateTitle: _emptyStateTitle(),
        emptyStateIconPath: _emptyStateIcon,
        highlightedEventId: widget.initialEventId,
        onAddGuestsTap: _showAddGuestPopup,
        onGuestListTap: _showGuestListPopup,
        onEditTap: _editEvent,
      ),
    );
  }
}

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

class _EventCarouselState extends State<_EventCarousel> {
  late final PageController _controller;
  String? _lastJumpedEventId;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.75);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeJumpToEvent());
  }

  @override
  void didUpdateWidget(covariant _EventCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events != widget.events ||
        oldWidget.highlightedEventId != widget.highlightedEventId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeJumpToEvent());
    }
  }

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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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

class _EmptyEventsState extends StatelessWidget {
  const _EmptyEventsState({
    required this.s,
    required this.title,
    required this.iconPath,
  });

  final double s;
  final String title;
  final String iconPath;

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

class _PopupHeaderBar extends StatelessWidget {
  const _PopupHeaderBar({
    required this.title,
    required this.onClose,
    this.action,
  });

  final String title;
  final VoidCallback onClose;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
      child: Row(
        children: [
          const SizedBox(width: 36),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 36, child: action ?? const SizedBox.shrink()),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _PopupSearchField extends StatelessWidget {
  const _PopupSearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return VezGlass.textField(
      controller: controller,
      hint: hint,
      prefixIcon: const Icon(Icons.search, color: Colors.white),
      color: Colors.white,
      onChanged: onChanged,
    );
  }
}

class _PopupFilterChip extends StatelessWidget {
  const _PopupFilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isActive
              ? const Color.fromARGB(100, 255, 255, 255)
              : const Color.fromARGB(45, 255, 255, 255),
          border: Border.all(
            color: isActive ? Colors.white : Colors.white30,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PopupGuestRow extends StatelessWidget {
  const _PopupGuestRow({
    required this.username,
    required this.profilePhoto,
    required this.state,
    this.trailing,
  });

  final String username;
  final String profilePhoto;
  final String state;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color.fromARGB(45, 255, 255, 255),
        border: Border.all(color: Colors.white24, width: 1.5),
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
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...[trailing!, const SizedBox(width: 4)],
          _PopupStateIcon(state: state),
        ],
      ),
    );
  }
}

class _PopupUserActionRow extends StatelessWidget {
  const _PopupUserActionRow({
    required this.username,
    required this.profilePhoto,
    required this.label,
    required this.icon,
    required this.iconColor,
    this.onTap,
  });

  final String username;
  final String profilePhoto;
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color.fromARGB(45, 255, 255, 255),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: Row(
        children: [
          _PopupUserAvatar(photo: profilePhoto),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  username.isNotEmpty ? username : 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onTap,
            icon: Icon(icon, color: iconColor),
          ),
        ],
      ),
    );
  }
}

class _PopupUserAvatar extends StatelessWidget {
  const _PopupUserAvatar({required this.photo});

  final String photo;

  @override
  Widget build(BuildContext context) {
    final bool isNetworkImage = photo.startsWith('http');

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white30, width: 1.5),
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

class _PopupStateIcon extends StatelessWidget {
  const _PopupStateIcon({required this.state});

  final String state;

  @override
  Widget build(BuildContext context) {
    final String iconPath = switch (state) {
      'going' => 'assets/icons/event/participation_state/going.png',
      'not_going' => 'assets/icons/event/participation_state/not_going.png',
      _ => 'assets/icons/event/participation_state/maybe.png',
    };

    return ImageIcon(AssetImage(iconPath), color: Colors.white, size: 18);
  }
}

class _PopupCountsFooter extends StatelessWidget {
  const _PopupCountsFooter({required this.counts});

  final HomeEventGuestCounts counts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color.fromARGB(45, 255, 255, 255),
        border: Border.all(color: Colors.white24, width: 1.5),
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

class _PopupCountItem extends StatelessWidget {
  const _PopupCountItem({
    required this.iconPath,
    required this.label,
    required this.value,
  });

  final String iconPath;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ImageIcon(AssetImage(iconPath), size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w600,
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

class _PopupEmptyState extends StatelessWidget {
  const _PopupEmptyState({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color.fromARGB(30, 255, 255, 255),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color.fromARGB(140, 255, 195, 0),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
