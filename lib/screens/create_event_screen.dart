// Developed and Designed by Outly • © 2026
// Screen to create an event

import 'package:flutter/material.dart';
import 'package:vez/screens/profile_screen.dart';
import 'dart:ui';
import '../models/vez_glass.dart';
import '../models/vez_page_layout.dart';
import '../models/vez_popup.dart';
import '../services/auth_service.dart';
import '../services/getters_service.dart';
import '../services/setters_service.dart';
import '../services/translation_service.dart';
import '../services/user_session.dart';
import 'home_screen.dart';
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
  String selectedCategoryName = "Cinema";
  String selectedCategoryIcon = "assets/icons/categories/cinema.png";
  String selectedTypeName = "Public";
  String selectedTypeIcon = "assets/icons/event/public.png";

  final TextEditingController titleController = TextEditingController();

  // --- GRID VARIABLES ---
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _location;
  String? _description;
  String? _maxGuests;
  String? _price;

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
  String _profilePhoto = "";

  @override
  void initState() {
    super.initState();
    final currentID = UserSession().userID;

    if (currentID.isNotEmpty) {
      _dbServiceGet = GetDBService(userID: currentID);
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
      selectedCategoryName = "Cinema";
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

  Future<void> saveEvent() async {
    print("Event Saved: ${titleController.text}");
  }

  // --- INTERACTIVE GRID LOGIC ---
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _showTextInputPopup(String title, String? currentValue, Function(String) onSave, {bool isNumeric = false, bool isMultiline = false}) {
    final TextEditingController _popupController = TextEditingController(text: currentValue);

    VezPopup.show(
      context: context,
      width: MediaQuery.of(context).size.width * 0.8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 15),
          TextField(
            controller: _popupController,
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
              onSave(_popupController.text);
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
    VezPopup.show(
      context: context,
      width: MediaQuery.of(context).size.width * 0.75,
      height: MediaQuery.of(context).size.height * 0.5,
      backgroundColor: const Color.fromARGB(128, 6, 0, 92),
      borderColor: const Color.fromARGB(128, 0, 10, 218),
      child: ListView.separated(
        // fisic in iOS style: scroll more natural and with a bouncing
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        itemCount: categoriesList.length, // number of items to display
        padding: const EdgeInsets.symmetric(vertical: 0),
        separatorBuilder: (context, index) => _customDivider(), // row separator
        itemBuilder: (context, i) => ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
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
    VezPopup.show(
      context: context,
      width: 250, // Larghezza fissa per farlo venire slanciato in verticale
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
          _customDivider(), // horizontal divider
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
          _customDivider(),
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

  // --- POPUP HELPERS (VERTICAL LAYOUT) ---
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

  // widget to create the row divider
  Widget _customDivider() {
    return Center(
      child: Container(
        width: 200, // Divider più stretto del popup
        height: 2,
        color: Colors.white54,
      ),
    );
  }

  void _showConfirmationPopup(String title, VoidCallback onConfirm) {
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

  // --- SUPPORT WIDGETS WITH BLUR ---
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
            const SizedBox(width: 20),
            IconButton(
              icon: const ImageIcon(AssetImage("assets/icons/nav_bar/create_event.png"), color: Colors.white),
              iconSize: 30,
              onPressed: () {},
            ),
            const SizedBox(width: 20),
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
          clipBehavior: Clip.antiAlias,

          // todo: improve the background shadow
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            // 1. BORDO PIÙ LUMINOSO: Fondamentale per definire l'angolo come su Figma
            border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 1.5
            ),
            // 2. BAGLIORE ESTERNO (GLOW): Sostituisce l'ombra "sporca"
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.15), // Luce bianca soffusa
                blurRadius: 25, // Ampio per non sembrare una macchia
                spreadRadius: 2, // Definisce meglio la silhouette degli angoli
                offset: const Offset(0, 0),
              ),
            ],
          ),

          // centre of the card
          child: Stack(
            children: [
              // 1. Dynamic Background
              Positioned.fill(
                  child: eventBackgroundImage != null
                      ? Image.file(eventBackgroundImage!, fit: BoxFit.cover)
                      : Image.asset("assets/images/bg/default_create_event_bg.jpg", fit: BoxFit.cover)
              ),
              Positioned.fill(child: Container(color: Colors.black.withOpacity(0.3))),

              // 2. Card Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Top Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          _buildTopButton(selectedCategoryIcon, _showCategoryPopup, isBlue: true),
                          const SizedBox(width: 12),
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

                    const SizedBox(height: 20),

                    // Main Info Container (Title + Grid)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
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
                              TextField(
                                controller: titleController,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  hintText: StringRes.at("event_title"),
                                  hintStyle: TextStyle(color: Colors.white),
                                  border: InputBorder.none,
                                ),
                                //maxLength: 15,
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
                                    _buildGridCell(StringRes.at("location"), "assets/icons/event/location.png", _location, () => _showTextInputPopup(StringRes.at("set_location"), _location, (val) => setState(() => _location = val))),
                                    const VerticalDivider(color: Color.fromARGB(128, 255, 255, 255), width: 2, thickness: 2),
                                    _buildGridCell(StringRes.at("details"), "assets/icons/event/description.png", _description, () => _showTextInputPopup(StringRes.at("set_details"), _description, (val) => setState(() => _description = val), isMultiline: true)),
                                  ],
                                ),
                              ),

                              const Divider(color: Color.fromARGB(128, 255, 255, 255), height: 2, thickness: 1.5),

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

                    const SizedBox(height: 20),

                    // Action Buttons (Save & Delete)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Save Button
                        GestureDetector(
                          onTap: () => _showConfirmationPopup(StringRes.at("save_event"), saveEvent),
                          child: ClipOval(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.all(12),
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
                        const SizedBox(width: 40),
                        // Delete Button
                        GestureDetector(
                          onTap: () => _showConfirmationPopup(StringRes.at("delete_data"), _resetEventData),
                          child: ClipOval(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.all(12),
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