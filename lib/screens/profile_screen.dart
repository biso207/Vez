// Developed and Designed by Outly • © 2026
// Screen to manage the user profile page
// When a logged user views a profile or wants to see his profile, this screen is opened.

import 'package:flutter/material.dart';
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
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  // costruttore
  const ProfilePage({
    super.key,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController searchController = TextEditingController();

  final ImagePicker picker = ImagePicker();

  // Inizializziamo i controller con i dati attuali
  final TextEditingController newUsernameController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController cityAkaNameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  bool _showBadge = true; // Toggle category badge
  File? newProfileImage;
  String? popupError;

  final _RemoteDbService = new RemoteDbService();

  // instance of the remote db service
  late GetDBService _dbServiceGet;
  late SetDBService _dbServiceSet;

  // --- USER DATA ---
  String _profilePhoto = ""; // profile photo
  String _username = ""; // username
  String _cityAkaName = StringRes.at("city_aka_name"); // city akaName
  String _city = StringRes.at("city"); // city
  String _bio = StringRes.at("bio"); // bio
  int _numFollowers = 0; // numFollowers
  int _numFollowing = 0;// numFollowing
  int _numParticipatedEvents = 0; // numParticipatedEvents

  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    final currentID = UserSession().userID;

    if (currentID.isNotEmpty) {
      // initializing the services with the user id
      _dbServiceGet = GetDBService(userID: currentID);
      _dbServiceSet = SetDBService(userID: currentID);

      // getting the user data at the start of the page
      getUserData();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // LOGIC //
  // method to get the user data from the db
  void getUserData() async {
    // fetching all string data
    String? photo = await _dbServiceGet.getUserData("profile_photo");
    String? username = await _dbServiceGet.getUserData("username");
    String? city = await _dbServiceGet.getUserData("city");
    String? akaName = await _dbServiceGet.getUserData("city_aka_name");
    String? bio = await _dbServiceGet.getUserData("bio");
    String? numParticipatedEventsStr = await _dbServiceGet.getUserData("num_participated_events");
    String? showBadge = await _dbServiceGet.getUserData("category_badge");

    // fetching counts
    int followers = 0;
    int followingCount = 0;

    followers = await _dbServiceGet.getFollowersCount();
    List<dynamic> followingList = await _dbServiceGet.getFollowing();
    followingCount = followingList.length;

    // Update the UI safely
    if (mounted) {
      setState(() {
        _profilePhoto = photo!.trim();
        _username = username ?? "Username";
        _city = city ?? "City";
        _cityAkaName = akaName ?? "City AkaName";
        _bio = bio ?? "No Bio.";
        _numParticipatedEvents = int.tryParse(numParticipatedEventsStr ?? "0") ?? 0;
        _numFollowers = followers;
        _numFollowing = followingCount;
        _showBadge = bool.parse(showBadge!);
      });
    }
  }

  // method to update the data on the db
  Future<void> updateData(StateSetter setPopupState) async {
    final String uName = newUsernameController.text.trim();
    final String psw = newPasswordController.text;
    final String cityAkaName = cityAkaNameController.text.trim();
    final String bio = bioController.text.trim();

    // if the email is not empty (so user has digitized it), validate it
    if (uName.length < 3 && uName.isNotEmpty) {
      setPopupState(() => popupError = StringRes.at("username_too_short"));
      return;
    }

    // if the password is not empty (so user has digitized it), validate it
    if (psw.isNotEmpty) {
      if (psw.length < 8 ||
          !RegExp(r'[A-Z]').hasMatch(psw) ||
          !RegExp(r'[a-z]').hasMatch(psw) ||
          !RegExp(r'[0-9]').hasMatch(psw) ||
          !RegExp(r'[!@#$&*~£€?§+]').hasMatch(psw)) {
        setPopupState(() => popupError = StringRes.at("invalid_password"));
        return;
      }
    }

    if (uName.isNotEmpty) { // username
      int response = await _dbServiceSet.updateUserData("username", uName); // request to change the username

      if (response == 409) { // error 409: conflict
        setPopupState(() => popupError = StringRes.at("user_already_exists"));
        return;
      }
      if (uName==_username) { // same username
        setPopupState(() => popupError = StringRes.at("same_username"));
        return;
      }

      setState(() {
        _username = uName;
        return;
      });
    }
    if (psw.isNotEmpty) _dbServiceSet.updateUserData("hash_psw", psw); // password
    if (cityAkaName.isNotEmpty) _dbServiceSet.updateUserData("city_aka_name", cityAkaName); // city aka name
    if (bio.isNotEmpty) _dbServiceSet.updateUserData("bio", bio); // bio
    _dbServiceSet.updateUserData("category_badge", _showBadge); // show/not show the category badge

    // saving the new photo
    String photoUrl = "";
    if (newProfileImage != null) {
      photoUrl = await _RemoteDbService.uploadProfilePhoto(newProfileImage!, _username) ?? "";
      _dbServiceSet.updateUserData("profile_photo", photoUrl); // saving on the db
    }

    // updating local vars with the new data
    setState(() {
      if (cityAkaName.isNotEmpty) _cityAkaName = cityAkaName;
      if (bio.isNotEmpty) _bio = bio;
      // mock update per foto profilo se cambiata
      if (newProfileImage != null) _profilePhoto = photoUrl;
    });
  }

  // --- SUPPORT WIDGETS ---
  // Widget helper per le icone delle statistiche
  Widget _buildStatItem(String iconPath, String value, double s) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          iconPath,
          width: 30,
          height: 30,
          color: Colors.white, // Forza il colore se l'icona è trasparente, rimuovilo se l'asset è già bianco
        ),
        SizedBox(height: 1 * s),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'InstagramSans',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // --- POPUPS EDIT PROFILE ---
  void _showEditProfilePopup(double s) {
    // Helper per creare i campi di testo in stile "Glass" richiesto
    Widget buildPopupInput({
      required String hint,
      required TextEditingController controller,
      int? maxLength,
      int maxLines = 1,
      bool obscure = false,
      Widget? suffixIcon,
      Widget? suffixText,
      required StateSetter setPopupState,
    }) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(maxLines > 1 ? 20 : 30),
          border: Border.all(color: Colors.white54, width: 1.5),
        ),
        child: TextField(
          controller: controller,
          onChanged: (value) => setPopupState(() {}),
          maxLength: maxLength,
          maxLines: maxLines,
          obscureText: obscure,
          style: const TextStyle(color: Colors.white, fontFamily: 'InstagramSans', fontWeight: FontWeight.bold, fontSize: 20),
          decoration: InputDecoration(
            hintText: hint,
            suffixText: maxLength != null
                ? "${controller.text.length}/$maxLength"
                : null,
            hintStyle: const TextStyle(color: Colors.white54),
            border: InputBorder.none,
            counterText: "", // Nasconde il numerino dei caratteri rimanenti
            suffixIcon: suffixIcon,
            suffixIconConstraints: const BoxConstraints(),
          ),
        ),
      );
    }

    VezPopup.show(
      context: context,
      width: MediaQuery.of(context).size.width * 0.85,
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setPopupState) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- SPAZIO SOPRA IMMAGINE ---
                SizedBox(height: 30 * s),

                // --- IMMAGINE PROFILO ---
                GestureDetector(
                  onTap: () async {
                    final XFile? pickedFile = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 512, maxHeight: 512, imageQuality: 75,
                    );
                    if (pickedFile != null) {
                      setPopupState(() => newProfileImage = File(pickedFile.path));
                    }
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      image: DecorationImage(
                        image: newProfileImage != null
                            ? FileImage(newProfileImage!) as ImageProvider
                            : (_profilePhoto.isNotEmpty
                            ? NetworkImage(_profilePhoto)
                            : const AssetImage("assets/icons/auth/icon_camera_90x90.png")) as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                // Spazio tra immagine e campi uguale a quello in basso
                SizedBox(height: 30 * s),

                // --- CAMPI DI TESTO ---
                buildPopupInput(
                  hint: StringRes.at("new_username"),
                  controller: newUsernameController,
                  maxLength: 15,
                  setPopupState: setPopupState,
                ),
                buildPopupInput(
                  hint: StringRes.at("new_password"),
                  controller: newPasswordController,
                  obscure: !_showPassword, // icon show/not show psw

                  // Detector for the tap on the eye icon
                  suffixIcon: GestureDetector(
                    onTap: () => setPopupState(
                            () => _showPassword = !_showPassword),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        !_showPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.white54,
                        size: 20,
                      ),
                    ),
                  ),
                  setPopupState: setPopupState,
                ),

                buildPopupInput(
                  hint: StringRes.at("city_aka_name"),
                  controller: cityAkaNameController,
                  maxLength: 10,
                  setPopupState: setPopupState,
                ),
                buildPopupInput(
                  hint: StringRes.at("bio"),
                  controller: bioController,
                  maxLength: 30,
                  maxLines: 1,
                  setPopupState: setPopupState,
                ),

                // --- TOGGLE CATEGORY BADGE ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(51, 6, 0, 92),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color.fromARGB(128, 0, 10, 218), width: 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: ImageIcon(const AssetImage("assets/icons/categories/hang_out.png"), color: Colors.white, size:20.45),
                      ),
                    ),
                    SizedBox(width: 15 * s),
                    Text(
                      StringRes.at("category_badge"),
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'InstagramSans'),
                    ),
                    SizedBox(width: 30 * s),
                    Switch(
                      value: _showBadge,
                      onChanged: (val) {
                        setPopupState(() => _showBadge = val);
                        setState(() => _showBadge = val);
                      },
                      activeThumbColor: Colors.black,
                      activeTrackColor: Colors.white,
                      inactiveThumbColor: Colors.white54,
                      inactiveTrackColor: Colors.white24,
                    ),
                  ],
                ),

                // --- ERRORE BANNER (appears only if there's an error) ---
                SizedBox(height: 30 * s),

                if (popupError != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      child: AnimatedOpacity(
                        opacity: popupError != null ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        // When null: zero-size placeholder so the layout stays
                        // stable while the opacity animation plays out.
                        child: popupError != null
                            ? VezErrorBanner(message: popupError!)
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),

                  SizedBox(height: 30 * s),
                ],

                // --- PULSANTI AZIONE ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    // button save (green)
                    GestureDetector(
                      onTap: () async {
                        popupError=null; // resetting errors

                        // update the db with the new data
                        await updateData(setPopupState);

                        // if there's no errors close the popup
                        if (popupError == null) {
                          Navigator.pop(context);

                          // cleaning controllers
                          newUsernameController.clear();
                          newPasswordController.clear();
                          cityAkaNameController.clear();
                          bioController.clear();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(128, 8, 157, 13),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color.fromARGB(204, 8, 157, 13), width: 2),
                        ),
                        child: ImageIcon(const AssetImage("assets/icons/profile_page/save.png"), color: Colors.white, size:30),
                      ),
                    ),

                    SizedBox(width: 30 * s),

                    // button discard (red)
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);

                        // cleaning controllers
                        newUsernameController.clear();
                        newPasswordController.clear();
                        cityAkaNameController.clear();
                        bioController.clear();

                        // disabling the error banner
                        popupError = null;
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(128, 255, 49, 49),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color.fromARGB(204, 255, 49, 49), width: 2),
                        ),
                        child: ImageIcon(const AssetImage("assets/icons/profile_page/delete.png"), color: Colors.white, size:30),
                      ),
                    ),
                  ],
                ),

                // --- SPAZIO SOTTO PULSANTI ---
                SizedBox(height: 30 * s),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- PAGE LAYOUT ---
  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double s = (screenWidth / 390).clamp(0.8, 1.2);

    return VezPageLayout(
      // --- TOP NAVBAR (PARAMETERS) ---
      searchController: searchController,

      // user profile photo
      profileIconPath: "assets/icons/profile_page/settings.png",
      isProfileAvatar: false,
      // tapping on the profile photo
      onProfileTap: () {
        // TODO: go to the settings page
        print("Settings tapped");
      },
      searchHint: StringRes.at("search"),
      filterIconPath: "assets/icons/profile_page/following_requests.png",
      onFilterSelected: (index) {
        setState(() {
        });
        // TODO: go to the following_requests page
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
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePage()),
                );
              },
            ),

            SizedBox(width: 20 * s),

            IconButton(
              icon: const ImageIcon(AssetImage("assets/icons/nav_bar/create_event.png"), color: Colors.white),
              iconSize: 30,
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateEvent()),
                );
              },
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

      // --- CENTRE (PROFILE CONTENT) ---
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 150*s),

            // --- USER DATA CARD ---
            GestureDetector(
              onTap: () => _showEditProfilePopup(s), // opening the popup to edit the profile
              child: Container(
                width: double.infinity, // Occupa tutta la larghezza concessa dal layout
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E0E0E),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color:Color.fromARGB(128, 255, 255, 255), width:2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromARGB(128, 255, 255, 255),
                      blurRadius: 5.0, // Ombra presente ma contenuta
                      spreadRadius: 0,
                      offset: Offset(0.0, 0.0),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Photo & Category Badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 75,
                          height: 75,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            image: DecorationImage(
                              image: _profilePhoto.isNotEmpty
                                  ? NetworkImage(_profilePhoto)
                                  : const AssetImage("assets/icons/home_page/profile_photo.png") as ImageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        // badge most-participated event category
                        if (_showBadge)
                          Positioned(
                            top: -5,
                            right: -5,
                            child: ClipOval(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(51, 0, 10, 218), // #000ADA 20%
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color.fromARGB(128, 0, 10, 218), // #000ADA 50%
                                      width: 2,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    /// will be automatic set based on the most participated event category
                                    child: Image.asset("assets/icons/categories/pub.png", color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    SizedBox(width: 16*s),

                    // User Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // username
                          Text(
                            _username,
                            style: const TextStyle(
                              fontFamily: 'JollyLodger',
                              fontSize: 30,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),

                          SizedBox(height: 4*s),

                          // aka name of the city & the city
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontFamily: 'InstagramSans',
                                color: Colors.white,
                                fontSize: 15,
                              ),
                              children: [
                                // aka
                                TextSpan(
                                  text: _cityAkaName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                // city
                                TextSpan(
                                  text: " • $_city",
                                  style: const TextStyle(fontWeight: FontWeight.w300), // Light
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 4*s),

                          // bio/des
                          Text(
                            _bio,
                            style: const TextStyle(
                              fontFamily: 'InstagramSans',
                              fontSize: 15,
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
              ),
            ),

            SizedBox(height: 20*s),

            // --- STATS CARD ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30), // La rende più stretta della User Card
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E0E0E),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color:Color.fromARGB(128, 255, 255, 255), width:2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromARGB(128, 255, 255, 255),
                      blurRadius: 5.0,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribuisce le 3 stats perfettamente
                  children: [
                    _buildStatItem("assets/icons/profile_page/followers.png", _numFollowers.toString(), s),
                    _buildStatItem("assets/icons/profile_page/participated_events.png", _numParticipatedEvents.toString(), s),
                    _buildStatItem("assets/icons/profile_page/following_requests.png", _numFollowing.toString(), s),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20 * s),

            // --- PAST EVENTS GRID ---
            SizedBox(
              height: 400,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0.0),
                child: ShaderMask(
                  shaderCallback: (Rect rect) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black, Colors.transparent, Colors.transparent, Colors.black],
                      stops: [0.0, 0.05, 0.95, 1.0],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstOut,
                  child: GridView.builder(
                    padding: const EdgeInsets.only(top: 10, bottom: 80),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: 0,
                    itemBuilder: (context, index) {
                      return Container();
                    },
                  ),
                ),
              ),
            ),
            SizedBox(height: 100*s),
          ],
        ),
      ),
    );
  }
}