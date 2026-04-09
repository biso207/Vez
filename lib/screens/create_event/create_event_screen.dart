// Developed and Designed by Outly • © 2026
// Screen to create an event

// TODO: improve UI of the popup setters
// todo: fix the bug related the display of the location name (is not display when selected from the map)

import 'package:flutter/material.dart';
import 'package:vez/screens/profile_screen.dart';
import 'package:vez/screens/create_event/vez_map_picker.dart';
import 'dart:ui';
import '../../models/vez_glass.dart';
import '../../models/vez_page_layout.dart';
import '../../models/vez_popup.dart';
import '../../services/auth_service.dart';
import '../../services/getters_service.dart';
import '../../services/setters_service.dart';
import '../../services/translation_service.dart';
import '../../services/user_session.dart';
import '../home_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CreateEvent extends StatefulWidget {
  // constructor
  const CreateEvent({
    super.key,
  });

  @override
  State<CreateEvent> createState() => _CreateEventState();
}

class _CreateEventState extends State<CreateEvent> {
  final TextEditingController searchController = TextEditingController();
  final ImagePicker picker = ImagePicker();

  // --- EVENT CREATION STATE ---
  File? eventBackgroundImage;
  String selectedCategoryName = "cinema";
  String selectedCategoryIcon = "assets/icons/categories/cinema.png";
  String selectedTypeName = "Public";
  String selectedTypeIcon = "assets/icons/event/public.png";

  final TextEditingController titleController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();

  // --- GRID VARIABLES ---
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _location;
  String? _description;
  String? _maxGuests;
  String? _price;

  String _locationName = "";
  String _locationAddress = "";
  double? _locationLat;
  double? _locationLng;
  bool _isLocationPrecise = false;

  // Data Lists
  final List<Map<String, String>> categoriesList = [
    {"name": "cinema", "icon": "assets/icons/categories/cinema.png"},
    {"name": "concert", "icon": "assets/icons/categories/concert.png"},
    {"name": "disco", "icon": "assets/icons/categories/disco.png"},
    {"name": "gaming", "icon": "assets/icons/categories/gaming.png"},
    {"name": "hang_out", "icon": "assets/icons/categories/hang_out.png"},
    {"name": "journey", "icon": "assets/icons/categories/journey.png"},
    {"name": "kids_and_family", "icon": "assets/icons/categories/kids_and_family.png"},
    {"name": "museum", "icon": "assets/icons/categories/museum.png"},
    {"name": "outdoor", "icon": "assets/icons/categories/outdoor.png"},
    {"name": "party", "icon": "assets/icons/categories/party.png"},
    {"name": "pub", "icon": "assets/icons/categories/pub.png"},
    {"name": "restaurant", "icon": "assets/icons/categories/restaurant.png"},
    {"name": "shopping", "icon": "assets/icons/categories/shopping.png"},
    {"name": "sport", "icon": "assets/icons/categories/sport.png"},
    {"name": "theatre", "icon": "assets/icons/categories/theatre.png"},
    {"name": "wellness", "icon": "assets/icons/categories/wellness.png"},
    {"name": "workshop", "icon": "assets/icons/categories/workshop.png"},
  ];

  final List<Map<String, String>> eventTypesList = [
    {"name": "Exclusive", "icon": "assets/icons/event/exclusive.png"},
    {"name": "Private", "icon": "assets/icons/event/private.png"},
    {"name": "Public", "icon": "assets/icons/event/public.png"},
  ];

  late GetDBService _dbServiceGet;
  late SetDBService _dbServiceSet;
  String _profilePhoto = "";

  @override
  void initState() {
    super.initState();
    final currentID = UserSession().userID;

    if (currentID.isNotEmpty) {
      _dbServiceGet = GetDBService(userID: currentID);
      _dbServiceSet = SetDBService(userID: currentID);
      getUserProfilePhoto();
    }
  }

  void getUserProfilePhoto() async {
    String? photo = await _dbServiceGet.getUserData("profile_photo");
    if (!mounted) return;
    setState(() {
      _profilePhoto = photo?.trim() ?? "";
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  // --- EVENT LOGIC ---
  Future<void> _pickBackgroundImage() async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        eventBackgroundImage = File(image.path);
      });
    }
  }

  void _resetEventData() {
    setState(() {
      eventBackgroundImage = null;
      selectedCategoryName = "cinema";
      selectedCategoryIcon = "assets/icons/categories/cinema.png";
      selectedTypeName = "Public";
      selectedTypeIcon = "assets/icons/event/public.png";
      titleController.clear();
      _selectedDate = null;
      _selectedTime = null;
      _location = null;
      _description = null;
      _maxGuests = null;
      _price = null;
    });
  }

  // method to save the event in the db
  Future<void> saveEvent() async {
    // --- VALIDATION: all fields are required ---
    final String title = titleController.text.trim();

    if (title.isEmpty) {
      _showErrorSnackBar(StringRes.at("event_title_required"));
      return;
    }
    if (_selectedDate == null) {
      _showErrorSnackBar(StringRes.at("event_date_required"));
      return;
    }
    if (_selectedTime == null) {
      _showErrorSnackBar(StringRes.at("event_time_required"));
      return;
    }
    if (_locationName.isEmpty) {
      _showErrorSnackBar(StringRes.at("event_location_required"));
      return;
    }
    if (_description == null || _description!.isEmpty) {
      _showErrorSnackBar(StringRes.at("event_details_required"));
      return;
    }
    if (_maxGuests == null || _maxGuests!.isEmpty) {
      _showErrorSnackBar(StringRes.at("event_guests_required"));
      return;
    }
    if (_price == null || _price!.isEmpty) {
      _showErrorSnackBar(StringRes.at("event_price_required"));
      return;
    }

    // --- STEP 1: Create the Place ---
    final String? placeId = await _dbServiceSet.storePlace(
      name: _locationName,
      address: _locationAddress.isNotEmpty ? _locationAddress : null,
      isPrecise: _isLocationPrecise,
      latitude: _locationLat,
      longitude: _locationLng,
    );

    if (placeId == null) {
      _showErrorSnackBar(StringRes.at("event_place_save_failed"));
      return;
    }

    // --- STEP 2: Create the Event with the place_id ---
    Map<String, dynamic> eventData = {
      "title": title,
      "category": selectedCategoryName,
      "type": selectedTypeName,
      "date": "${_selectedDate!.year}-${_selectedDate!.month}-${_selectedDate!.day}",
      "time": "${_selectedTime!.hour}:${_selectedTime!.minute}",
      "max_guests": _maxGuests,
      "price": _price,
      "description": _description,
      "background_image": eventBackgroundImage,
    };

    final int response = await _dbServiceSet.storeEvent(eventData, placeId: placeId);

    if (!mounted) return;

    if (response == 200 || response == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(StringRes.at("event_saved_success")),
          backgroundColor: const Color.fromARGB(200, 8, 157, 13),
        ),
      );
      // Reset and go back to home
      _resetEventData();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      _showErrorSnackBar("${StringRes.at("event_save_failed")} ($response)");
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color.fromARGB(200, 255, 49, 49),
      ),
    );
  }

  // --- INTERACTIVE GRID LOGIC ---
  Future<void> _selectDate() async {
    _titleFocusNode.unfocus();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime() async {
    _titleFocusNode.unfocus();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // popup to digit text for a specific event data
  void _showTextInputPopup(String title, String? currentValue, Function(String) onSave, {bool isNumeric = false, bool isMultiline = false}) {
    _titleFocusNode.unfocus();
    final TextEditingController popupController = TextEditingController(text: currentValue);

    VezPopup.show(
      context: context,
      width: MediaQuery.of(context).size.width * 0.8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 15),
          TextField(
            controller: popupController,
            style: const TextStyle(color: Colors.white),
            keyboardType: isNumeric ? TextInputType.number : (isMultiline ? TextInputType.multiline : TextInputType.text),
            maxLines: isMultiline ? 4 : 1,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.white24)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.blueAccent)),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () {
              FocusScope.of(context).unfocus();
              onSave(popupController.text);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  // --- POPUPS ---
  // category popup
  void _showCategoryPopup() {
    _titleFocusNode.unfocus();
    final double width = MediaQuery.of(context).size.width * 0.60;
    final double height = MediaQuery.of(context).size.height * 0.5;

    VezPopup.show(
      context: context,
      width: width,
      height: height,
      backgroundColor: const Color.fromARGB(128, 6, 0, 92),
      borderColor: const Color.fromARGB(128, 0, 10, 218),
      child: ListView.separated(
        // fisic in iOS style: scroll more natural and with a bouncing
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),

        itemCount: categoriesList.length, // number of items to display

        padding: const EdgeInsets.symmetric(vertical: 0),
        separatorBuilder: (context, index) => _customDivider(width), // row separator

        itemBuilder: (context, i) => ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          leading: ImageIcon(
            AssetImage(categoriesList[i]["icon"]!),
            color: Colors.white,
            size: 40,
          ),
          title: Text(
            StringRes.at(categoriesList[i]["name"]!),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          onTap: () {
            setState(() {
              selectedCategoryName = categoriesList[i]["name"]!;
              selectedCategoryIcon = categoriesList[i]["icon"]!;
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  // typology popup -> same UI of the group popup of the home screen
  void _showTypePopup() {
    _titleFocusNode.unfocus();
    final double width = MediaQuery.of(context).size.width * 0.60;

    VezPopup.show(
      context: context,
      width: width,
      backgroundColor: const Color.fromARGB(200, 14, 14, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPopupItem(
            icon: eventTypesList[0]["icon"]!,
            label: StringRes.at("exclusive"),
            onTap: () {
              setState(() {
                selectedTypeName = eventTypesList[0]["name"]!;
                selectedTypeIcon = eventTypesList[0]["icon"]!;
              });
              Navigator.pop(context);
            },
          ),
          _customDivider(width), // horizontal divider
          _buildPopupItem(
            icon: eventTypesList[1]["icon"]!,
            label: StringRes.at("private"),
            onTap: () {
              setState(() {
                selectedTypeName = eventTypesList[1]["name"]!;
                selectedTypeIcon = eventTypesList[1]["icon"]!;
              });
              Navigator.pop(context);
            },
          ),
          _customDivider(width),
          _buildPopupItem(
            icon: eventTypesList[2]["icon"]!,
            label: StringRes.at("public"),
            onTap: () {
              setState(() {
                selectedTypeName = eventTypesList[2]["name"]!;
                selectedTypeIcon = eventTypesList[2]["icon"]!;
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showConfirmationPopup(String title, VoidCallback onConfirm) {
    _titleFocusNode.unfocus();
    VezPopup.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("NO", style: TextStyle(color: Colors.redAccent))),
              TextButton(onPressed: () { Navigator.pop(context); onConfirm(); }, child: const Text("OK", style: TextStyle(color: Colors.green))),
            ],
          )
        ],
      ),
    );
  }

  // --- SUPPORT WIDGETS ---
  Widget _buildTopButton(String iconPath, VoidCallback onTap, {bool isBlue = false}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isBlue ? const Color.fromARGB(51, 0, 11, 223) : const Color.fromARGB(51, 0, 0, 0),
              border: Border.all(color: isBlue ? const Color.fromARGB(128, 0, 11, 223) : const Color.fromARGB(128, 255, 255, 255), width: 2),
            ),
            child: Center(child: ImageIcon(AssetImage(iconPath), color: Colors.white, size: 30)), // icon size
          ),
        ),
      ),
    );
  }

  // widget to create and manage the grid of the event details
  Widget _buildGridCell(String title, String iconPath, String? displayValue, VoidCallback onTap, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          // change 'vertical' to manage the height
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // icon
              ImageIcon(AssetImage(iconPath), color: Colors.white, size: 20),
              const SizedBox(height: 0), // space between icon and text

              // text
              Text(
                (displayValue != null && displayValue.isNotEmpty) ? displayValue : title,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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

  // widget to create the row divider
  Widget _customDivider(double popupWidth) {
    // proportion of ~70%
    double calculatedWidth = popupWidth * 0.7;
    // width of the divider
    double finalWidth = calculatedWidth.clamp(142.0, popupWidth - 32.0);

    return Center(
      child: Container(
        width: finalWidth,
        height: 2,
        decoration: BoxDecoration(
          color: Colors.white54,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildPopupItem({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10), // I 10px di Figma
        child: Row(
          children: [
            Image.asset(icon, width: 40, height: 40), // Icona dimensione 40
            const SizedBox(width: 15),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- LOCATION LOGIC ---
  void _showLocationTypeSelector() {
    _titleFocusNode.unfocus();
    VezPopup.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(StringRes.at("set_location"), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),

          // 1) simple name -> "marco's house"
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              _showTextInputPopup("Location Name", _locationName, (val) {
                setState(() {
                  _locationName = val;
                  _isLocationPrecise = false;
                  _locationAddress = "";
                  _locationLat = null;
                  _locationLng = null;
                });
              });
            },
            child: VezGlass.container(
              padding: const EdgeInsets.all(15),
              child: const Row(
                children: [
                  Icon(Icons.edit, color: Colors.white),
                  SizedBox(width: 15),
                  Expanded(child: Text("Simple Name (e.g. Casa Marco)", style: TextStyle(color: Colors.white, fontSize: 16))),
                ],
              ),
            ),
          ),

          const SizedBox(height: 15),

          // 2) precise map location -> open the map -> set the place -> everything perfect
          GestureDetector(
            onTap: () async {
              Navigator.pop(context);
              // Apriamo la pagina della mappa (che creeremo al passo 3)
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VezMapPicker()),
              );

              // Se l'utente ha salvato un luogo dalla mappa, aggiorniamo i dati
              if (result != null && result is Map<String, dynamic>) {
                setState(() {
                  _locationName = result['name'] ?? "Selected Location";
                  _locationAddress = result['address'];
                  _locationLat = result['latitude'];
                  _locationLng = result['longitude'];
                  _isLocationPrecise = result['is_precise'];
                });
              }
            },
            child: VezGlass.container(
              padding: const EdgeInsets.all(15),
              child: const Row(
                children: [
                  Icon(Icons.map, color: Colors.white),
                  SizedBox(width: 15),
                  Expanded(child: Text("Precise Location (Map)", style: TextStyle(color: Colors.white, fontSize: 16))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- PAGE LAYOUT ---
  @override
  Widget build(BuildContext context) {
    String? formattedDate = _selectedDate != null ? "${_selectedDate!.day}/${_selectedDate!.month}" : null;
    String? formattedTime = _selectedTime?.format(context);

    // defining size based on the screen size
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    // height at 65% of the screen, width at 85%
    final double cardHeight = screenHeight * 0.65;
    final double cardWidth = screenWidth * 0.85;
    // this is for the SizedBoxes
    final double s = (screenWidth / 390).clamp(0.8, 1.2);

    final double rOuter = 40 * s; // Raggio responsivo card
    final double rInner = 30 * s; // Raggio responsivo grid componente

    return VezPageLayout(
      // --- TOP NAVBAR (PARAMETERS) ---
      searchController: searchController,

      // user profile photo
      profileIconPath: _profilePhoto,
      isProfileAvatar: true,
      // tapping on the profile photo to open the user profile
      onProfileTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ProfilePage()),
        );
      },
      searchHint: StringRes.at("search"),
      filterIconPath: "assets/icons/profile_page/following_requests.png",
      onFilterSelected: (index) {
        setState(() {
        });
        // TODO: will this do something? idk
      },

      // --- BOTTOM NAVBAR ---
      bottomNavBar: VezGlass.container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        radius: BorderRadius.circular(40),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const ImageIcon(AssetImage("assets/icons/nav_bar/go_to_home_page.png"), color: Colors.white),
              iconSize: 30,
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage())),
            ),
            SizedBox(width: 20 * s),

            IconButton(
              icon: const ImageIcon(AssetImage("assets/icons/nav_bar/create_event.png"), color: Colors.white),
              iconSize: 30,
              onPressed: () {},
            ),

            SizedBox(width: 20 * s),

            IconButton(
              icon: const ImageIcon(AssetImage("assets/icons/nav_bar/notifications.png"), color: Colors.white),
              iconSize: 30,
              onPressed: () {},
            ),
          ],
        ),
      ),

      // --- CENTRE (EVENT CREATION CARD) ---
      body: Center(
        child: Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5), // Sfondo fumé card
            borderRadius: BorderRadius.circular(rOuter),

            // --- 1. FIGMA SPEC: NO BORDERS (BORDER: NULL) ---
            border: null,

            // --- 2. FIGMA SPEC: DROP SHADOW BIANCA 50% (Spread 5, Blur ~15-20) ---
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(128, 255, 255, 255),
                blurRadius: 5.0, // dispersione
                spreadRadius: 0, // spread
                offset: const Offset(0.0, 0.0), // offset position x and y
              ),
            ],
          ),

          // centre of the card
          child: Stack(
            children: [
              // 1. dynamic background (Avvolto in ClipRRect per angoli perfetti)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(rOuter),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: eventBackgroundImage != null
                            ? Image.file(
                          eventBackgroundImage!,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                        )
                            : Image.asset(
                          "assets/images/bg/default_create_event_bg.jpg",
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                        ),
                      ),
                      // Overlay scuro per contrasto
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(80, 0, 0, 0), // Un filo più scuro (80 invece di 51)
                            borderRadius: BorderRadius.circular(rOuter),
                          ),
                        ),
                      ),
                    ],
                  )
                )
              ),

              // 2. card content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // top buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          _buildTopButton(selectedCategoryIcon, _showCategoryPopup, isBlue: true),

                          SizedBox(width: 15 * s),

                          _buildTopButton(selectedTypeIcon, _showTypePopup),
                        ]),
                        // Preview Badge with Blur
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                  color: const Color.fromARGB(128, 255, 195, 0), // Yellow Preview
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color.fromARGB(204, 255, 195, 0), width: 2)
                              ),
                              child: Text(StringRes.at("preview"), style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Edit Background Button
                    GestureDetector(
                      onTap: _pickBackgroundImage,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(51, 255, 255, 255),
                              border: Border.all(color: const Color.fromARGB(128, 255, 255, 255), width: 2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(StringRes.at("edit_bg"), style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 20 * s),

                    // main info grid (Title + Grid)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color.fromARGB(51, 0, 0, 0),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Color.fromARGB(128, 255, 255, 255), width: 2),
                          ),
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.centerRight,
                                children: [
                                  TextField(
                                    controller: titleController,
                                    focusNode: _titleFocusNode,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                    onChanged: (value) {
                                      setState(() {});
                                    },
                                    maxLength: 15,
                                    decoration: InputDecoration(
                                      hintText: StringRes.at("event_title"),
                                      hintStyle: const TextStyle(color: Colors.white),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      counterText: "",
                                    ),
                                  ),
                                  // Counter overlay in basso a destra
                                  Positioned(
                                    right: 12,
                                    bottom: 4,
                                    child: Text(
                                      "${titleController.text.length}/15",
                                      style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),

                              const Divider(color: Color.fromARGB(128, 255, 255, 255), height: 2, thickness: 2),

                              // Grid Row 1
                              IntrinsicHeight(
                                child: Row(
                                  children: [
                                    _buildGridCell(StringRes.at("date"), "assets/icons/event/calendar.png", formattedDate, _selectDate),
                                    const VerticalDivider(color: Color.fromARGB(128, 255, 255, 255), width: 2, thickness: 2),
                                    _buildGridCell(StringRes.at("time"), "assets/icons/event/time.png", formattedTime, _selectTime),
                                    const VerticalDivider(color: Color.fromARGB(128, 255, 255, 255), width: 2, thickness: 2),
                                    _buildGridCell(StringRes.at("location"), "assets/icons/event/location.png", _locationName.isNotEmpty ? _locationName : null, _showLocationTypeSelector),
                                    const VerticalDivider(color: Color.fromARGB(128, 255, 255, 255), width: 2, thickness: 2),
                                    _buildGridCell(StringRes.at("details"), "assets/icons/event/description.png", _description, () => _showTextInputPopup(StringRes.at("set_details"), _description, (val) => setState(() => _description = val), isMultiline: true)),
                                  ],
                                ),
                              ),

                              const Divider(color: Color.fromARGB(128, 255, 255, 255), height: 2, thickness: 2),

                              // Grid Row 2
                              IntrinsicHeight(
                                child: Row(
                                  children: [
                                    _buildGridCell(StringRes.at("max_guests"), "assets/icons/event/guests.png", _maxGuests, () => _showTextInputPopup(StringRes.at("set_max_guests"), _maxGuests, (val) => setState(() => _maxGuests = val), isNumeric: true)),
                                    const VerticalDivider(color: Color.fromARGB(128, 255, 255, 255), width: 2, thickness: 2),
                                    _buildGridCell(StringRes.at("price"), "assets/icons/event/price.png", _price != null ? "$_price€" : null, () => _showTextInputPopup(StringRes.at("set_price"), _price, (val) => setState(() => _price = val), isNumeric: true)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 20 * s),

                    // action buttons (save & delete)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // save Button
                        GestureDetector(
                          onTap: () => _showConfirmationPopup(StringRes.at("save_event"), saveEvent),
                          child: ClipOval(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(128, 8, 157, 13), // original green
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color.fromARGB(204, 8, 157, 13), width: 2),
                                ),
                                child: const ImageIcon(AssetImage("assets/icons/profile_page/save.png"), color: Colors.white, size: 30),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: 30 * s),

                        // delete Button
                        GestureDetector(
                          onTap: () => _showConfirmationPopup(StringRes.at("delete_data"), _resetEventData),
                          child: ClipOval(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(128, 255, 49, 49), // original red
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color.fromARGB(204, 255, 49, 49), width: 2),
                                ),
                                child: const ImageIcon(AssetImage("assets/icons/profile_page/delete.png"), color: Colors.white, size: 30),
                              ),
                            ),
                          ),
                        ),
                      ],
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