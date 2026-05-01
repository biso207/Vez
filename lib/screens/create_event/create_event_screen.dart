// developed and designed by Outly • © 2026
// create event screen — zone-2 content: a single full-height event card
// where the user configures all event details before saving.
//
// layout zones used:
//   zone 1 — background  : kBgColor from VezPageLayout
//   zone 2 — body        : Center → event creation card (fixed ratio)
//   zone 3 — blur veil   : handled by VezPageLayout
//   zone 4 — navbars     : top bar (profile/search/type) + bottom pill nav
//
// all popup interactions delegate to VezEventPopups for consistent styling.
// the category and type popups still use VezPopup directly (unchanged design).

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/event_catalog.dart';
import '../../models/home_event.dart';
import '../../services/getters_service.dart';
import '../../services/haptic_service.dart';
import '../../services/setters_service.dart';
import '../../services/translation_service.dart';
import '../../services/user_session.dart';
import '../../views/widgets/vez_event_popups.dart';
import '../../views/widgets/vez_glass.dart';
import '../../views/widgets/vez_page_layout.dart';
import '../../views/widgets/vez_popup.dart';
import '../notifications_screen.dart';
import '../profile_screen.dart';
import 'vez_map_picker.dart';

enum _GuestAudienceFilter { friends, following, anyone }

// ─────────────────────────────────────────────────────────────────────────────
// stateful widget wrapper
// ─────────────────────────────────────────────────────────────────────────────

class CreateEvent extends StatefulWidget {
  const CreateEvent({super.key, this.editingEvent});

  final HomeEventCardData? editingEvent;

  @override
  State<CreateEvent> createState() => _CreateEventState();
}

// ─────────────────────────────────────────────────────────────────────────────
// state
// ─────────────────────────────────────────────────────────────────────────────

class _CreateEventState extends State<CreateEvent> {
  // ── controllers & services ─────────────────────────────────────────────────

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _titleFocus = FocusNode();
  final ImagePicker _picker = ImagePicker();

  late final GetDBService _dbGet;
  late final SetDBService _dbSet;

  // ── event creation state ───────────────────────────────────────────────────

  String _bgImage = EventCatalog.defaultBackgroundImage;
  String _categoryName = 'cinema';
  String _categoryIcon = 'assets/icons/categories/cinema.png';
  String _typeName = 'Public';
  String _typeIcon = 'assets/icons/event/public.png';

  DateTime? _date;
  TimeOfDay? _time;
  String? _description;
  String? _maxGuests;
  String? _price;

  String _locationName = '';
  String _locationAddress = '';
  double? _locationLat;
  double? _locationLng;
  bool _locationPrecise = false;

  // ── user state ─────────────────────────────────────────────────────────────

  String _profilePhoto = '';
  String _originalBackgroundUrl = '';
  List<Map<String, dynamic>> _allUsers = const [];
  Set<String> _followingIds = const {};
  Set<String> _followerIds = const {};
  final Map<String, Map<String, dynamic>> _pendingGuests = {};

  // ── static data ────────────────────────────────────────────────────────────

  static const List<Map<String, String>> _categories = EventCatalog.categories;

  static const List<Map<String, String>> _eventTypes = EventCatalog.eventTypes;

  bool get _isEditMode => widget.editingEvent != null;
  bool get _canInviteGuests => EventCatalog.canInviteGuests(_typeName);
  int get _pendingGuestCount => _pendingGuests.length;

  // ── lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    final String uid = UserSession().userID;
    if (uid.isNotEmpty) {
      _dbGet = GetDBService(userID: uid);
      _dbSet = SetDBService(userID: uid);
      _loadProfilePhoto();
    }
    if (_isEditMode) {
      _applyEventData(widget.editingEvent!);
    }
    // rebuild on focus change for the title counter / alignment
    _titleFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  // ── data loading ───────────────────────────────────────────────────────────

  Future<void> _loadProfilePhoto() async {
    final String? photo = await _dbGet.getUserData('profile_photo');
    if (!mounted) return;
    setState(() => _profilePhoto = photo?.trim() ?? '');
  }

  Future<void> _ensureUserDirectoryLoaded() async {
    if (_allUsers.isNotEmpty) return;

    final results = await Future.wait([
      _dbGet.getUsersBasic(),
      _dbGet.getFollowing(),
      _dbGet.getFollowers(),
    ]);

    _allUsers = results[0];
    _followingIds = results[1]
        .map((row) => (row['following_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();
    _followerIds = results[2]
        .map((row) => (row['follower_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  // ── validation ─────────────────────────────────────────────────────────────

  bool get _isValid =>
      _titleController.text.isNotEmpty &&
      _date != null &&
      _time != null &&
      _locationName.isNotEmpty;

  void _applyEventData(HomeEventCardData event) {
    final DateTime? parsedDate = DateTime.tryParse(
      event.rawDateEvent,
    )?.toLocal();

    _originalBackgroundUrl = event.imagePath.trim();
    _bgImage = _originalBackgroundUrl.isNotEmpty
        ? _originalBackgroundUrl
        : EventCatalog.defaultBackgroundImage;
    _categoryName = event.categoryName;
    _categoryIcon = event.categoryIconPath;
    _typeName = EventCatalog.normalizeTypeName(event.typeLabel);
    _typeIcon = event.typeIconPath;
    _titleController.text = event.title;
    _date = parsedDate;
    _time = parsedDate != null
        ? TimeOfDay(hour: parsedDate.hour, minute: parsedDate.minute)
        : null;
    _description = event.description.isEmpty ? null : event.description;
    _maxGuests = event.maxGuests?.toString();
    _price = event.price?.toString();
    _locationName = event.locationLabel;
    _locationAddress = event.placeAddress;
    _locationLat = event.latitude;
    _locationLng = event.longitude;
    _locationPrecise = event.locationPrecise;
  }

  // ── event save / reset ─────────────────────────────────────────────────────

  Future<void> _saveEvent() async {
    String? placeId = widget.editingEvent?.placeId;

    if (_isEditMode && placeId != null && placeId.isNotEmpty) {
      final int placeRes = await _dbSet.updatePlace(
        placeId: placeId,
        name: _locationName,
        address: _locationAddress.isNotEmpty ? _locationAddress : null,
        isPrecise: _locationPrecise,
        latitude: _locationLat,
        longitude: _locationLng,
      );
      if (placeRes != 200 && placeRes != 204) {
        _showSnackBar(StringRes.at('event_place_save_failed'), isError: true);
        return;
      }
    } else {
      placeId = await _dbSet.storePlace(
        name: _locationName,
        address: _locationAddress.isNotEmpty ? _locationAddress : null,
        isPrecise: _locationPrecise,
        latitude: _locationLat,
        longitude: _locationLng,
      );
    }

    if (placeId == null || placeId.isEmpty) {
      _showSnackBar(StringRes.at('event_place_save_failed'), isError: true);
      return;
    }

    final Map<String, dynamic> payload = {
      'title': _titleController.text.trim(),
      'category': _categoryName,
      'type': _typeName,
      'date': '${_date!.year}-${_date!.month}-${_date!.day}',
      'time': '${_time!.hour}:${_time!.minute}',
      'max_guests': _maxGuests,
      'price': _price,
      'description': _description,
      'bg_photo': _resolveBackgroundPayload(),
    };

    int res;
    String? savedEventId;

    if (_isEditMode) {
      savedEventId = widget.editingEvent!.eventId;
      res = await _dbSet.updateEvent(
        savedEventId,
        payload,
        placeId: placeId,
        currentBackgroundUrl: _originalBackgroundUrl,
      );
    } else {
      savedEventId = await _dbSet.storeEventAndGetId(payload, placeId: placeId);
      res = savedEventId != null && savedEventId.isNotEmpty ? 201 : 0;
    }

    if (!mounted) return;

    if (res == 200 || res == 201 || res == 204) {
      final int inviteFailures = savedEventId != null && savedEventId.isNotEmpty
          ? await _inviteSelectedGuests(savedEventId)
          : _pendingGuestCount;
      if (!mounted) return;

      _showSnackBar(
        inviteFailures == 0
            ? StringRes.at(
                _isEditMode ? 'event_updated_success' : 'event_saved_success',
              )
            : '${StringRes.at(_isEditMode ? 'event_updated_success' : 'event_saved_success')} • ${StringRes.at('guest_add_failed')}',
      );
      Navigator.pop(context, true);
    } else {
      _showSnackBar(
        '${StringRes.at(_isEditMode ? "event_update_failed" : "event_save_failed")} ($res)',
        isError: true,
      );
    }
  }

  void _resetFields() {
    if (_isEditMode) {
      setState(() {
        _pendingGuests.clear();
        _applyEventData(widget.editingEvent!);
      });
      return;
    }

    setState(() {
      _bgImage = EventCatalog.defaultBackgroundImage;
      _categoryName = 'cinema';
      _categoryIcon = 'assets/icons/categories/cinema.png';
      _typeName = 'Public';
      _typeIcon = 'assets/icons/event/public.png';
      _titleController.clear();
      _date = _time = null;
      _description = _maxGuests = _price = null;
      _locationName = _locationAddress = '';
      _locationLat = _locationLng = null;
      _locationPrecise = false;
      _originalBackgroundUrl = '';
      _pendingGuests.clear();
    });
  }

  Future<int> _inviteSelectedGuests(String eventId) async {
    if (_pendingGuests.isEmpty) return 0;

    int failures = 0;
    final List<String> guestIds = _pendingGuests.keys.toList();

    for (final String userId in guestIds) {
      final int result = await _dbSet.addOrUpdateEventInvite(
        eventId: eventId,
        invitedUserId: userId,
      );
      if (result != 200 && result != 201 && result != 204) {
        failures++;
      }
    }

    _pendingGuests.clear();
    return failures;
  }

  // ── pickers ────────────────────────────────────────────────────────────────

  dynamic _resolveBackgroundPayload() {
    final String trimmed = _bgImage.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http')) return trimmed;
    if (trimmed.startsWith('assets/')) {
      return _isEditMode && _originalBackgroundUrl.isNotEmpty
          ? _originalBackgroundUrl
          : null;
    }
    return File(trimmed);
  }

  Future<void> _deleteEvent() async {
    if (!_isEditMode) return;

    final int res = await _dbSet.deleteEvent(
      widget.editingEvent!.eventId,
      placeId: widget.editingEvent!.placeId,
    );

    if (!mounted) return;

    if (res == 200 || res == 204) {
      _showSnackBar(StringRes.at('event_deleted_success'));
      Navigator.pop(context, true);
    } else {
      _showSnackBar(
        '${StringRes.at("event_delete_failed")} ($res)',
        isError: true,
      );
    }
  }

  Future<void> _pickBackground() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _bgImage = file.path);
  }

  Future<void> _pickDate() async {
    _titleFocus.unfocus();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    _titleFocus.unfocus();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  // ── navigation helpers ─────────────────────────────────────────────────────

  void _goToHome() {
    HapticService.tap();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _goToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    ).then((_) {
      if (!mounted) return;
      _loadProfilePhoto();
    });
  }

  void _goToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
  }

  // ── snack bar helper ───────────────────────────────────────────────────────

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

  // ── category & type popups (VezPopup directly — established visual style) ──

  /// scrollable list of event categories
  void _showCategoryPopup() {
    _titleFocus.unfocus();
    final double pw = MediaQuery.of(context).size.width * 0.50;
    final double ph = MediaQuery.of(context).size.height * 0.50;

    VezPopup.show(
      context: context,
      width: pw,
      height: ph,
      backgroundColor: const Color.fromARGB(128, 6, 0, 92), // todo: change
      borderColor: const Color.fromARGB(128, 0, 10, 218), // todo: change
      child: ListView.separated(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.zero,
        itemCount: _categories.length,
        separatorBuilder: (_, _) => _PopupDivider(width: pw),
        itemBuilder: (_, i) => ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          leading: ImageIcon(
            AssetImage(_categories[i]['icon']!),
            color: Colors.white,
            size: 38,
          ),
          title: Text(
            StringRes.at(_categories[i]['name']!),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          onTap: () {
            setState(() {
              _categoryName = _categories[i]['name']!;
              _categoryIcon = _categories[i]['icon']!;
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  /// three event-type options (exclusive / private / public)
  void _showTypePopup() {
    _titleFocus.unfocus();
    final double pw = MediaQuery.of(context).size.width * 0.50;

    VezPopup.show(
      context: context,
      width: pw,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          _eventTypes.length,
          (i) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PopupListItem(
                icon: _eventTypes[i]['icon']!,
                label: StringRes.at(_eventTypes[i]['name']!.toLowerCase()),
                onTap: () {
                  final String selectedType = _eventTypes[i]['name']!;
                  setState(() {
                    _typeName = selectedType;
                    _typeIcon = _eventTypes[i]['icon']!;
                    if (!EventCatalog.canInviteGuests(selectedType)) {
                      _pendingGuests.clear();
                    }
                  });
                  Navigator.pop(context);
                },
              ),
              if (i < _eventTypes.length - 1) _PopupDivider(width: pw),
            ],
          ),
        ),
      ),
    );
  }

  // ── unified detail popups (VezEventPopups) ─────────────────────────────────

  /// description — multiline text input
  void _showDescriptionPopup() {
    _titleFocus.unfocus();
    VezEventPopups.showTextInput(
      context,
      title: StringRes.at('set_details'),
      titleIcon: 'assets/icons/event/description.png',
      currentValue: _description,
      isMultiline: true,
      onSave: (v) => setState(() => _description = v.isNotEmpty ? v : null),
    );
  }

  /// max guests — numeric input
  void _showMaxGuestsPopup() {
    _titleFocus.unfocus();
    VezEventPopups.showTextInput(
      context,
      title: StringRes.at('set_max_guests'),
      titleIcon: 'assets/icons/event/guests.png',
      currentValue: _maxGuests,
      isNumeric: true,
      onSave: (v) => setState(() => _maxGuests = v.isNotEmpty ? v : null),
    );
  }

  /// price — numeric input
  void _showPricePopup() {
    _titleFocus.unfocus();
    VezEventPopups.showTextInput(
      context,
      title: StringRes.at('set_price'),
      titleIcon: 'assets/icons/event/price.png',
      currentValue: _price,
      isNumeric: true,
      onSave: (v) => setState(() => _price = v.isNotEmpty ? v : null),
    );
  }

  /// location type selector: simple name vs map
  void _showLocationSelectorPopup() {
    _titleFocus.unfocus();
    VezEventPopups.showLocationSelector(
      context,
      onSimpleNameTap: () => VezEventPopups.showTextInput(
        context,
        title: StringRes.at('location_simple_name'),
        titleIcon: 'assets/icons/event/location.png',
        currentValue: _locationName,
        onSave: (val) => setState(() {
          _locationName = val;
          _locationPrecise = false;
          _locationAddress = '';
          _locationLat = _locationLng = null;
        }),
      ),
      onMapTap: () async {
        final result = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(builder: (_) => const VezMapPicker()),
        );
        if (result != null) {
          setState(() {
            _locationName = result['name'] ?? 'Selected Location';
            _locationAddress = result['address'] ?? '';
            _locationLat = result['latitude'] as double?;
            _locationLng = result['longitude'] as double?;
            _locationPrecise = result['is_precise'] as bool? ?? false;
          });
        }
      },
    );
  }

  /// save confirmation
  void _showSaveConfirmation() {
    VezEventPopups.showConfirmation(
      context,
      title: StringRes.at('save_event'),
      titleIcon: 'assets/icons/profile_page/save.png',
      confirmLabel: StringRes.at('confirm'),
      cancelLabel: StringRes.at('cancel'),
      onConfirm: _saveEvent,
    );
  }

  /// delete / reset confirmation
  void _showDeleteConfirmation() {
    VezEventPopups.showConfirmation(
      context,
      title: StringRes.at('delete_data'),
      titleIcon: 'assets/icons/profile_page/delete.png',
      confirmLabel: StringRes.at('confirm'),
      cancelLabel: StringRes.at('cancel'),
      onConfirm: _resetFields,
    );
  }

  void _showDeleteEventConfirmation() {
    VezEventPopups.showConfirmation(
      context,
      title: StringRes.at('delete_event'),
      titleIcon: 'assets/icons/profile_page/delete.png',
      confirmLabel: StringRes.at('confirm'),
      cancelLabel: StringRes.at('cancel'),
      onConfirm: _deleteEvent,
    );
  }

  Future<void> _showAddGuestsPopup() async {
    if (!_canInviteGuests) {
      _showSnackBar(StringRes.at('guest_invites_private_only'), isError: true);
      return;
    }

    await _ensureUserDirectoryLoaded();
    if (!mounted) return;

    final TextEditingController searchController = TextEditingController();
    _GuestAudienceFilter audienceFilter = _GuestAudienceFilter.friends;
    final Set<String> friendIds = _followingIds.intersection(_followerIds);
    final double popupWidth = MediaQuery.of(context).size.width * 0.82;
    final double popupHeight = MediaQuery.of(context).size.height * 0.64;

    VezPopup.show(
      context: context,
      width: popupWidth,
      height: popupHeight,
      child: StatefulBuilder(
        builder: (context, setPopupState) {
          final Set<String> excludedIds = {
            UserSession().userID,
            ..._pendingGuests.keys,
            if (_isEditMode)
              ...widget.editingEvent!.guests.map((guest) => guest.userId),
          };

          final List<Map<String, dynamic>> candidates = _allUsers.where((user) {
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
                return _followingIds.contains(userId);
              case _GuestAudienceFilter.anyone:
                return true;
            }
          }).toList();

          final List<Map<String, dynamic>> selectedGuests = _pendingGuests
              .values
              .toList();

          return Column(
            children: [
              _GuestPopupHeader(
                title: StringRes.at('add_guest'),
                onClose: () => Navigator.pop(context),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _GuestPopupSearchField(
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
                    _GuestPopupChip(
                      label: StringRes.at('friends'),
                      isActive: audienceFilter == _GuestAudienceFilter.friends,
                      onTap: () => setPopupState(
                        () => audienceFilter = _GuestAudienceFilter.friends,
                      ),
                    ),
                    _GuestPopupChip(
                      label: StringRes.at('following'),
                      isActive:
                          audienceFilter == _GuestAudienceFilter.following,
                      onTap: () => setPopupState(
                        () => audienceFilter = _GuestAudienceFilter.following,
                      ),
                    ),
                    _GuestPopupChip(
                      label: StringRes.at('anyone'),
                      isActive: audienceFilter == _GuestAudienceFilter.anyone,
                      onTap: () => setPopupState(
                        () => audienceFilter = _GuestAudienceFilter.anyone,
                      ),
                    ),
                  ],
                ),
              ),
              if (selectedGuests.isNotEmpty) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedGuests.map((user) {
                        final String userId = (user['user_id'] ?? '')
                            .toString();
                        return _SelectedGuestChip(
                          username: (user['username'] ?? '').toString(),
                          onRemove: () {
                            setState(() => _pendingGuests.remove(userId));
                            setPopupState(() {});
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: candidates.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _GuestEmptyState(
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
                          return _GuestUserActionRow(
                            username: (user['username'] ?? '').toString(),
                            profilePhoto: (user['profile_photo'] ?? '')
                                .toString(),
                            label: _relationLabel(userId),
                            onTap: () {
                              setState(() {
                                _pendingGuests[userId] =
                                    Map<String, dynamic>.from(user);
                              });
                              setPopupState(() {});
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    ).whenComplete(searchController.dispose);
  }

  String _relationLabel(String userId) {
    if (_followingIds.contains(userId) && _followerIds.contains(userId)) {
      return StringRes.at('friends');
    }
    if (_followingIds.contains(userId)) {
      return StringRes.at('following');
    }
    return StringRes.at('anyone');
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final double sh = MediaQuery.of(context).size.height;
    final double sw = MediaQuery.of(context).size.width;
    final double s = (sw / 390).clamp(0.8, 1.2);

    final double cardH = sh * 0.65;
    final double cardW = sw * 0.85;
    final double rOuter = 40 * s;
    final double rInner = 30 * s;

    final String? fmtDate = _date != null
        ? '${_date!.day}/${_date!.month}'
        : null;
    final String? fmtTime = _time?.format(context);

    return VezPageLayout(
      // ── top navbar ──────────────────────────────────────────────────────
      searchController: _searchController,
      searchHint: StringRes.at('search'),
      profileIconPath: _profilePhoto,
      isProfileAvatar: true,
      onProfileTap: _goToProfile,
      filterIconPath: 'assets/icons/profile_page/following_requests.png',
      onFilterSelected: (_) {},

      // ── bottom navbar ────────────────────────────────────────────────────
      bottomNavBar: _BottomNavPill(
        s: s,
        activeIndex: 1,
        onHomeTap: _goToHome,
        onCreateEventTap: () {},
        onNotificationsTap: _goToNotifications,
      ),

      // ── zone-2 body: event creation card ────────────────────────────────
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _EventCard(
              width: cardW,
              height: cardH,
              rOuter: rOuter,
              rInner: rInner,
              s: s,
              bgImage: _bgImage,

              categoryIcon: _categoryIcon,
              typeIcon: _typeIcon,
              titleController: _titleController,
              titleFocus: _titleFocus,

              formattedDate: fmtDate,
              formattedTime: fmtTime,
              locationName: _locationName.isNotEmpty ? _locationName : null,
              description: _description,
              maxGuests: _maxGuests,
              price: _price != null ? '$_price€' : null,

              isValid: _isValid,

              onPickBackground: _pickBackground,
              onCategoryTap: _showCategoryPopup,
              onTypeTap: _showTypePopup,
              onDateTap: _pickDate,
              onTimeTap: _pickTime,
              onLocationTap: _showLocationSelectorPopup,
              onDescriptionTap: _showDescriptionPopup,
              onMaxGuestsTap: _showMaxGuestsPopup,
              onPriceTap: _showPricePopup,
              onSaveTap: _showSaveConfirmation,
              onDeleteTap: _showDeleteConfirmation,
            ),
            if (_isEditMode) ...[
              SizedBox(height: 16 * s),
              _DeleteEventButton(onTap: _showDeleteEventConfirmation, s: s),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EventCard — the full create-event card (zone-2 centre element)
// ─────────────────────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final double width, height, rOuter, rInner, s;
  final String bgImage, categoryIcon, typeIcon;
  final TextEditingController titleController;
  final FocusNode titleFocus;

  final String? formattedDate,
      formattedTime,
      locationName,
      description,
      maxGuests,
      price;
  final bool isValid;

  final VoidCallback onPickBackground;
  final VoidCallback onCategoryTap, onTypeTap;
  final VoidCallback onDateTap, onTimeTap, onLocationTap;
  final VoidCallback onDescriptionTap, onMaxGuestsTap, onPriceTap;
  final VoidCallback onSaveTap, onDeleteTap;

  const _EventCard({
    required this.width,
    required this.height,
    required this.rOuter,
    required this.rInner,
    required this.s,
    required this.bgImage,
    required this.categoryIcon,
    required this.typeIcon,
    required this.titleController,
    required this.titleFocus,
    required this.formattedDate,
    required this.formattedTime,
    required this.locationName,
    required this.description,
    required this.maxGuests,
    required this.price,
    required this.isValid,
    required this.onPickBackground,
    required this.onCategoryTap,
    required this.onTypeTap,
    required this.onDateTap,
    required this.onTimeTap,
    required this.onLocationTap,
    required this.onDescriptionTap,
    required this.onMaxGuestsTap,
    required this.onPriceTap,
    required this.onSaveTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color.fromARGB(128, 0, 0, 0),
        borderRadius: BorderRadius.circular(rOuter),
        boxShadow: const [
          BoxShadow(color: Color.fromARGB(100, 255, 255, 255), blurRadius: 6),
        ],
      ),
      child: Stack(
        children: [
          // ── dynamic background ──────────────────────────────────────────
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(rOuter),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: bgImage.startsWith('http')
                        ? Image.network(bgImage, fit: BoxFit.cover)
                        : bgImage.startsWith('assets')
                        ? Image.asset(bgImage, fit: BoxFit.cover)
                        : Image.file(File(bgImage), fit: BoxFit.cover),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(80, 0, 0, 0),
                        borderRadius: BorderRadius.circular(rOuter),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── card content ────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.all(14 * s),
            child: Column(
              children: [
                // top row: category + type  |  preview badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _GlassCircleButton(
                          icon: categoryIcon,
                          onTap: onCategoryTap,
                          isBlue: true,
                          s: s,
                        ),
                        SizedBox(width: 12 * s),
                        _GlassCircleButton(
                          icon: typeIcon,
                          onTap: onTypeTap,
                          s: s,
                        ),
                      ],
                    ),
                    _PreviewBadge(label: StringRes.at('preview')),
                  ],
                ),

                const Spacer(),

                _EditBgButton(onTap: onPickBackground, s: s),
                SizedBox(height: 14 * s),

                _InfoGrid(
                  rInner: rInner,
                  s: s,
                  titleController: titleController,
                  titleFocus: titleFocus,
                  formattedDate: formattedDate,
                  formattedTime: formattedTime,
                  locationName: locationName,
                  description: description,
                  maxGuests: maxGuests,
                  price: price,
                  onDateTap: onDateTap,
                  onTimeTap: onTimeTap,
                  onLocationTap: onLocationTap,
                  onDescriptionTap: onDescriptionTap,
                  onMaxGuestsTap: onMaxGuestsTap,
                  onPriceTap: onPriceTap,
                ),

                SizedBox(height: 14 * s),

                _ActionButtons(
                  s: s,
                  isValid: isValid,
                  onSaveTap: onSaveTap,
                  onDeleteTap: onDeleteTap,
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
// _GlassCircleButton — blur-backed circle button inside the event card
// ─────────────────────────────────────────────────────────────────────────────

class _GlassCircleButton extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;
  final bool isBlue;
  final double s;

  const _GlassCircleButton({
    required this.icon,
    required this.onTap,
    this.isBlue = false,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final Color fill = isBlue
        ? const Color.fromARGB(51, 0, 11, 223)
        : const Color.fromARGB(51, 0, 0, 0);
    final Color border = isBlue
        ? const Color.fromARGB(128, 0, 11, 223)
        : const Color.fromARGB(128, 255, 255, 255);

    return GestureDetector(
      onTap: () {
        HapticService.tap();
        onTap();
      },
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.all(6 * s),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fill,
              border: Border.all(color: border, width: 2),
            ),
            child: ImageIcon(AssetImage(icon), color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PreviewBadge — yellow frosted pill in the top-right corner
// ─────────────────────────────────────────────────────────────────────────────

class _PreviewBadge extends StatelessWidget {
  final String label;
  const _PreviewBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color.fromARGB(128, 255, 195, 0),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color.fromARGB(204, 255, 195, 0),
              width: 2,
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EditBgButton — frosted "Edit Background" pill
// ─────────────────────────────────────────────────────────────────────────────

class _EditBgButton extends StatelessWidget {
  final VoidCallback onTap;
  final double s;
  const _EditBgButton({required this.onTap, required this.s});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 4),
            decoration: BoxDecoration(
              color: const Color.fromARGB(51, 255, 255, 255),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color.fromARGB(128, 255, 255, 255),
                width: 2,
              ),
            ),
            child: Text(
              StringRes.at('edit_bg'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _InfoGrid — frosted container: title field + two grid rows
// ─────────────────────────────────────────────────────────────────────────────

class _DeleteEventButton extends StatelessWidget {
  const _DeleteEventButton({required this.onTap, required this.s});

  final VoidCallback onTap;
  final double s;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.tap();
        onTap();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 18 * s, vertical: 8 * s),
            decoration: BoxDecoration(
              color: const Color.fromARGB(70, 255, 49, 49),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color.fromARGB(180, 255, 49, 49),
                width: 2,
              ),
            ),
            child: Text(
              StringRes.at('delete_event'),
              style: TextStyle(
                color: Colors.white,
                fontSize: 15 * s,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final double rInner, s;
  final TextEditingController titleController;
  final FocusNode titleFocus;
  final String? formattedDate,
      formattedTime,
      locationName,
      description,
      maxGuests,
      price;
  final VoidCallback onDateTap, onTimeTap, onLocationTap;
  final VoidCallback onDescriptionTap, onMaxGuestsTap, onPriceTap;

  const _InfoGrid({
    required this.rInner,
    required this.s,
    required this.titleController,
    required this.titleFocus,
    required this.formattedDate,
    required this.formattedTime,
    required this.locationName,
    required this.description,
    required this.maxGuests,
    required this.price,
    required this.onDateTap,
    required this.onTimeTap,
    required this.onLocationTap,
    required this.onDescriptionTap,
    required this.onMaxGuestsTap,
    required this.onPriceTap,
  });

  static const Widget _vDiv = VerticalDivider(
    color: Color.fromARGB(128, 255, 255, 255),
    width: 2,
    thickness: 2,
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(rInner),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(51, 0, 0, 0),
            borderRadius: BorderRadius.circular(rInner),
            border: Border.all(
              color: const Color.fromARGB(128, 255, 255, 255),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              _TitleField(controller: titleController, focus: titleFocus),
              const Divider(
                color: Color.fromARGB(128, 255, 255, 255),
                height: 2,
                thickness: 2,
              ),

              // row 1: date / time / location / description
              IntrinsicHeight(
                child: Row(
                  children: [
                    _GridCell(
                      label: StringRes.at('date'),
                      icon: 'assets/icons/event/calendar.png',
                      value: formattedDate,
                      onTap: onDateTap,
                    ),
                    _vDiv,
                    _GridCell(
                      label: StringRes.at('time'),
                      icon: 'assets/icons/event/time.png',
                      value: formattedTime,
                      onTap: onTimeTap,
                    ),
                    _vDiv,
                    _GridCell(
                      label: StringRes.at('location'),
                      icon: 'assets/icons/event/location.png',
                      value: locationName,
                      onTap: onLocationTap,
                    ),
                    _vDiv,
                    _GridCell(
                      label: StringRes.at('details'),
                      icon: 'assets/icons/event/description.png',
                      value: description,
                      onTap: onDescriptionTap,
                    ),
                  ],
                ),
              ),

              const Divider(
                color: Color.fromARGB(128, 255, 255, 255),
                height: 2,
                thickness: 2,
              ),

              // row 2: max guests / price
              IntrinsicHeight(
                child: Row(
                  children: [
                    _GridCell(
                      label: StringRes.at('max_guests'),
                      icon: 'assets/icons/event/guests.png',
                      value: maxGuests,
                      onTap: onMaxGuestsTap,
                    ),
                    _vDiv,
                    _GridCell(
                      label: StringRes.at('price'),
                      icon: 'assets/icons/event/price.png',
                      value: price,
                      onTap: onPriceTap,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TitleField — centered editable title with live character counter
// ─────────────────────────────────────────────────────────────────────────────

class _TitleField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focus;
  const _TitleField({required this.controller, required this.focus});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        TextField(
          controller: controller,
          focusNode: focus,
          maxLength: 15,
          onChanged: (_) {},
          textAlign: focus.hasFocus ? TextAlign.left : TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: StringRes.at('event_title'),
            hintStyle: const TextStyle(color: Colors.white),
            border: InputBorder.none,
            counterText: '',
            contentPadding: EdgeInsets.only(
              left: focus.hasFocus ? 18 : 0,
              right: focus.hasFocus ? 72 : 0,
            ),
          ),
        ),
        if (focus.hasFocus)
          Positioned(
            right: 18,
            child: Text(
              '${controller.text.length}/15',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _GridCell — single tappable cell of the event-details grid
// ─────────────────────────────────────────────────────────────────────────────

class _GridCell extends StatelessWidget {
  final String label, icon;
  final String? value;
  final VoidCallback onTap;

  const _GridCell({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ImageIcon(AssetImage(icon), color: Colors.white, size: 20),
              Text(
                (value != null && value!.isNotEmpty) ? value! : label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ActionButtons — save (green) / delete (red) at the bottom of the card
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final double s;
  final bool isValid;
  final VoidCallback onSaveTap, onDeleteTap;

  const _ActionButtons({
    required this.s,
    required this.isValid,
    required this.onSaveTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CardActionCircle(
          icon: 'assets/icons/profile_page/save.png',
          active: isValid,
          activeColor: const Color.fromARGB(128, 8, 157, 13),
          activeBorder: const Color.fromARGB(204, 8, 157, 13),
          onTap: isValid ? onSaveTap : null,
        ),
        SizedBox(width: 28 * s),
        _CardActionCircle(
          icon: 'assets/icons/profile_page/delete.png',
          active: isValid,
          activeColor: const Color.fromARGB(128, 255, 49, 49),
          activeBorder: const Color.fromARGB(204, 255, 49, 49),
          onTap: isValid ? onDeleteTap : null,
        ),
      ],
    );
  }
}

class _CardActionCircle extends StatelessWidget {
  final String icon;
  final bool active;
  final Color activeColor, activeBorder;
  final VoidCallback? onTap;

  const _CardActionCircle({
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.activeBorder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap != null
          ? () {
              HapticService.tap();
              onTap!();
            }
          : null,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? activeColor : const Color.fromARGB(128, 0, 0, 0),
              border: Border.all(
                color: active ? activeBorder : Colors.grey,
                width: 2,
              ),
            ),
            child: ImageIcon(AssetImage(icon), color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BottomNavPill — shared pill nav (see home_screen.dart for the canonical copy)
// todo: move to vez_bottom_nav.dart when the project grows
// ─────────────────────────────────────────────────────────────────────────────

class _GuestPopupHeader extends StatelessWidget {
  const _GuestPopupHeader({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

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
          const SizedBox(width: 36),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _GuestPopupSearchField extends StatelessWidget {
  const _GuestPopupSearchField({
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

class _GuestPopupChip extends StatelessWidget {
  const _GuestPopupChip({
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

class _SelectedGuestChip extends StatelessWidget {
  const _SelectedGuestChip({required this.username, required this.onRemove});

  final String username;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color.fromARGB(60, 255, 255, 255),
        border: Border.all(color: Colors.white24, width: 1.3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            username.isNotEmpty ? username : 'User',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            onPressed: onRemove,
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            splashRadius: 18,
            icon: const Icon(Icons.close, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _GuestUserActionRow extends StatelessWidget {
  const _GuestUserActionRow({
    required this.username,
    required this.profilePhoto,
    required this.label,
    required this.onTap,
  });

  final String username;
  final String profilePhoto;
  final String label;
  final VoidCallback onTap;

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
          _GuestUserAvatar(photo: profilePhoto),
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
            icon: const Icon(
              Icons.person_add_alt_1_rounded,
              color: Color(0xFF089D0D),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestUserAvatar extends StatelessWidget {
  const _GuestUserAvatar({required this.photo});

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

class _GuestEmptyState extends StatelessWidget {
  const _GuestEmptyState({required this.title});

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

class _InviteGuestsButton extends StatelessWidget {
  const _InviteGuestsButton({required this.onTap, required this.label});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.tap();
        onTap();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
              color: const Color.fromARGB(70, 255, 255, 255),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color.fromARGB(128, 255, 255, 255),
                width: 2,
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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

// ─────────────────────────────────────────────────────────────────────────────
// popup helper widgets — used by the category and type popups only
// ─────────────────────────────────────────────────────────────────────────────

class _PopupListItem extends StatelessWidget {
  final String icon, label;
  final VoidCallback onTap;

  const _PopupListItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: Row(
          children: [
            Image.asset(icon, width: 38, height: 38),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
