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
import '../services/user_session.dart';
import 'create_event_screen.dart';
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
  String _cityAkaName = "City AkaName"; // city akaName
  String _city = "City"; // city
  String _bio = "No Bio."; // bio
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

  // Widget helper per le icone delle statistiche
  Widget _buildStatItem(String iconPath, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          iconPath,
          width: 30,
          height: 30,
          color: Colors.white, // Forza il colore se l'icona è trasparente, rimuovilo se l'asset è già bianco
        ),
        const SizedBox(height: 5),
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

  // --- PAGE LAYOUT ---
  @override
  Widget build(BuildContext context) {
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
      searchHint: "Search",
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
            const SizedBox(width: 20),
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
            const SizedBox(width: 20),
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
            const SizedBox(height: 180),

            // --- USER DATA CARD ---
            GestureDetector(
              onTap: () => _showEditProfilePopup(), // opening the popup to edit the profile
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4), // Sfondo leggermente più coprente
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: Colors.white54, // Bordo più delicato
                        width: 2 // Spessore ridotto
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.white10, // Ombra più "soffice" e densa
                        blurRadius: 12,
                        spreadRadius: 0, // Lo zero crea un alone perfetto sui lati
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

                      const SizedBox(width: 16),

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

                            const SizedBox(height: 4),

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

                            const SizedBox(height: 4),

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

            const SizedBox(height: 20),

            // --- STATS CARD ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 50),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                    color: Colors.white54,
                    width:2
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.white10,
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem("assets/icons/profile_page/followers.png", _numFollowers.toString()),
                  _buildStatItem("assets/icons/profile_page/participated_events.png", _numParticipatedEvents.toString()),
                  _buildStatItem("assets/icons/profile_page/following_requests.png", _numFollowing.toString()),
                ],
              ),
            ),

            const SizedBox(height: 20),

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
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // --- POPUP MODIFICA PROFILO ---
  void _showEditProfilePopup() {

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

                // Spazio uguale a quello in basso
                const SizedBox(height: 32),

                // --- CAMPI DI TESTO ---
                buildPopupInput(
                  hint: "New Username",
                  controller: newUsernameController,
                  maxLength: 15,
                  setPopupState: setPopupState,
                ),
                buildPopupInput(
                  hint: "New Password",
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
                  hint: "City Aka Name",
                  controller: cityAkaNameController,
                  maxLength: 10,
                  setPopupState: setPopupState,
                ),
                buildPopupInput(
                  hint: "Bio",
                  controller: bioController,
                  maxLength: 30,
                  maxLines: 2,
                  setPopupState: setPopupState,
                ),

                // --- TOGGLE CATEGORY BADGE ---
                Row(
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
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Category Badge",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'InstagramSans'),
                      ),
                    ),
                    Switch(
                      value: _showBadge,
                      onChanged: (val) {
                        setPopupState(() => _showBadge = val); // changing the toggle UI
                        setState(() => _showBadge = val); // changing the badge in the UI page
                      },
                      activeThumbColor: Colors.black,
                      activeTrackColor: Colors.white,
                      inactiveThumbColor: Colors.white54,
                      inactiveTrackColor: Colors.white24,
                    ),
                  ],
                ),

                // --- ERRORE BANNER (appears only if there's an error) ---
                const SizedBox(height: 32),

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
                ],

                const SizedBox(height: 32),

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

                    const SizedBox(width: 30),

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
              ],
            ),
          );
        },
      ),
    );
  }

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
      setPopupState(() => popupError = "Username is too short (Min. 3 chars).");
      return;
    }

    // if the password is not empty (so user has digitized it), validate it
    if (psw.isNotEmpty) {
      if (psw.length < 8 ||
          !RegExp(r'[A-Z]').hasMatch(psw) ||
          !RegExp(r'[a-z]').hasMatch(psw) ||
          !RegExp(r'[0-9]').hasMatch(psw) ||
          !RegExp(r'[!@#$&*~£€?§+]').hasMatch(psw)) {
        setPopupState(() => popupError = "Invalid Password.\nNeed 8 chars, 1 uppercase, 1 lowercase, 1 number, 1 special.");
        return;
      }
    }

    if (uName.isNotEmpty) { // username
      int response = await _dbServiceSet.updateUserData("username", uName); // request to change the username

      if (response == 409) { // error 409: conflict
        setPopupState(() => popupError = "User already exists");
        return;
      }
      if (uName==_username) { // same username
        setPopupState(() => popupError = "New username is the same as the old one");
        return;
      }
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
}