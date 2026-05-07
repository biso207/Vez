// create event screen.
// owns form state, save/delete actions, and popups.
// visual widgets live in widgets/*.dart to keep this file readable.

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

part 'widgets/event_editor_card.dart';
part 'widgets/create_event_bottom_nav.dart';

class CreateEvent extends StatefulWidget {
  const CreateEvent({super.key, this.editingEvent});

  final HomeEventCardData? editingEvent;

  @override
  State<CreateEvent> createState() => _CreateEventState();
}

class _CreateEventState extends State<CreateEvent> {
  // controllers and services.
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _titleFocus = FocusNode();
  final ImagePicker _picker = ImagePicker();

  late final GetDBService _dbGet;
  late final SetDBService _dbSet;

  // editable event fields.
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

  // loaded user and original event data.
  String _profilePhoto = '';
  String _originalBackgroundUrl = '';

  // static picker data.
  static const List<Map<String, String>> _categories = EventCatalog.categories;

  static const List<Map<String, String>> _eventTypes = EventCatalog.eventTypes;

  bool get _isEditMode => widget.editingEvent != null;

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

    // added listener on controller to force rebuild during real-time typing
    // this keeps the character counter perfectly updated on screen.
    _titleController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  Future<void> _loadProfilePhoto() async {
    final String? photo = await _dbGet.getUserData('profile_photo');
    if (!mounted) return;
    setState(() => _profilePhoto = photo?.trim() ?? '');
  }

  // boolean to validate an event and be saved
  bool get _isValid =>
      _titleController.text.isNotEmpty &&
          _date != null &&
          _time != null &&
          _locationName.isNotEmpty &&
          _bgImage.isNotEmpty && !_bgImage.startsWith('assets/');

  // populate all fields when the screen edits an existing event.
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
      _showSnackBar(
        StringRes.at(
          _isEditMode ? 'event_updated_success' : 'event_saved_success',
        ),
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
    });
  }

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

  // scrollable list of event categories
  void _showCategoryPopup() {
    _titleFocus.unfocus();
    final double pw = MediaQuery.of(context).size.width * 0.50;
    final double ph = MediaQuery.of(context).size.height * 0.50;

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

  // three event-type options (exclusive / private / public)
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

  // location type selector: simple name vs map
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
          MaterialPageRoute(
            builder: (_) => VezMapPicker(
              initialLatitude: _locationLat,
              initialLongitude: _locationLng,
              initialName: _locationName,
              initialAddress: _locationAddress,
            ),
          ),
        );
        if (result != null) {
          setState(() {
            _locationName = (result['name'] ?? 'Selected Location')
                .toString();
            _locationAddress = (result['address'] ?? '').toString();
            _locationLat = (result['latitude'] as num?)?.toDouble();
            _locationLng = (result['longitude'] as num?)?.toDouble();
            _locationPrecise = result['is_precise'] as bool? ?? false;
          });
        }
      },
    );
  }

  // save confirmation
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

  // delete / reset confirmation
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
      // search area
      searchController: _searchController,
      searchHint: StringRes.at('search'),

      // left button
      profileIconPath: _profilePhoto,
      isProfileAvatar: true,
      onProfileTap: _goToProfile,

      // right button
      filterIconPath: 'assets/icons/profile_page/following_requests.png',
      isFilterSelected: true,
      onFilterTap: null,
      onFilterSelected: (_) {},

      bottomNavBar: _BottomNavPill(
        s: s,
        activeIndex: 1,
        onHomeTap: _goToHome,
        onCreateEventTap: () {},
        onNotificationsTap: _goToNotifications,
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          final double cardBottom = (constraints.maxHeight + cardH) / 2;

          return Stack(
            children: [
              Center(
                child: _EventCard(
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
                  price: _price != null ? '$_price EUR' : null,

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
              ),
              if (_isEditMode)
                Positioned(
                  top: cardBottom + 16 * s,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _DeleteEventButton(
                      onTap: _showDeleteEventConfirmation,
                      s: s,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// popup list item used by the category and type selectors.
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
