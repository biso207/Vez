// Developed and Designed by Outly • © 2026
// Screen to manage the user profile page
// When a logged user views a profile or wants to see his profile, this screen is opened.

import 'package:flutter/material.dart';
import '../models/vez_glass.dart';
import '../models/vez_page_layout.dart';
import '../services/getters_service.dart';
import '../services/user_session.dart'; // Importato come richiesto
import 'home_screen.dart';

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

  // instance of the remote db service
  final RemoteDbService _dbService = RemoteDbService(username: UserSession().username);

  // --- USER DATA ---
  String _profilePhoto = ""; // profile photo
  String _cityAkaName = "City AkaName"; // city akaName
  String _city = "City"; // city
  String _bio = "No Bio."; // bio
  int _numFollowers = 0; // numFollowers
  int _numFollowing = 0;// numFollowing
  int _numParticipatedEvents = 0; // numParticipatedEvents

  // default event group index
  int _indexEventGroup = 1;

  @override
  void initState() {
    super.initState();
    // getting the user data at the start of the page
    getUserData();
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
            fontSize: 16,
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
          _indexEventGroup = index;
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

      // --- CENTRE (PROFILE CONTENT) ---
      body: Column(
        children: [
          const SizedBox(height: 20),

          // --- USER DATA CARD ---
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3), // Leggero sfondo scuro per far risaltare il testo
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 2
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: 15,
                  spreadRadius: -2,
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
                              : const AssetImage("assets/images/default_avatar.png") as ImageProvider, // Immagine di fallback
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Badge categoria evento preferito
                    Positioned(
                      top: -5,
                      right: -5,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2C3E50), // Colore blu del badge
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          // Sostituisci questo path con la vera icona della categoria (es. birra)
                          child: Image.asset("assets/icons/categories/beer.png", color: Colors.white),
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
                      // Username
                      Text(
                        UserSession().username ?? "Username",
                        style: const TextStyle(
                          fontFamily: 'JollyLodger',
                          fontSize: 34,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Aka Name & City
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontFamily: 'InstagramSans',
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          children: [
                            TextSpan(
                              text: _cityAkaName ?? "City AkaName",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: " • ${_city ?? "City"}",
                              style: const TextStyle(fontWeight: FontWeight.w300), // Light
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Bio / Description
                      Text(
                        _bio ?? "Nessuna descrizione inserita.",
                        style: const TextStyle(
                          fontFamily: 'InstagramSans',
                          fontSize: 11,
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

          const SizedBox(height: 20),

          // --- STATS CARD ---
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 60), // Più stretta come da richiesta
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20), // Più bassa
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(40), // Molto arrotondata
              border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 2
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: 15,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Ricordati di cambiare i path con quelli corretti delle tue icone
                _buildStatItem("assets/icons/profile_page/followers.png", _numFollowers.toString() ?? "0"),
                _buildStatItem("assets/icons/profile_page/partecipated_events.png", _numParticipatedEvents.toString() ?? "0"),
                _buildStatItem("assets/icons/profile_page/following_requests.png", _numFollowing.toString() ?? "0"),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- PAST EVENTS GRID (Empty for now) ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              // Lo shaderMask creerà l'effetto ombra/sfumatura superiore e inferiore richiesto
              child: ShaderMask(
                shaderCallback: (Rect rect) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black, Colors.transparent, Colors.transparent, Colors.black],
                    stops: [0.0, 0.05, 0.95, 1.0], // Regola l'intensità della sfumatura
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstOut,
                child: GridView.builder(
                  padding: const EdgeInsets.only(top: 10, bottom: 80), // Padding inferiore per la bottom bar
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.7, // Proporzione per card rettangolari verticali
                  ),
                  itemCount: 0, // Attualmente vuota come richiesto
                  itemBuilder: (context, index) {
                    // Qui andranno inserite in futuro le VezEventCard
                    return Container();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- GETTER FOR USER DATA ---
  void getUserData() async {
    // getting userID
    String? userID = await _dbService.getUserData("id");

    // Fetching all string data
    String? photo = await _dbService.getUserData("profile_photo");
    String? city = await _dbService.getUserData("city");
    String? akaName = await _dbService.getUserData("city_aka_name");
    String? bio = await _dbService.getUserData("bio"); // Added bio fetch
    String? numParticipatedEventsStr = await _dbService.getUserData("num_participated_events");

    // Fetching counts (defaulting to 0 initially)
    int followers = 0;
    int followingCount = 0;

    if (userID != null) {
      followers = await _dbService.getFollowersCount(userID);
      List<dynamic> followingList = await _dbService.getFollowing(userID);
      followingCount = followingList.length;
    }

    // Update the UI safely
    if (mounted) {
      setState(() {
        _profilePhoto = photo ?? "";
        _city = city ?? "City";
        _cityAkaName = akaName ?? "City AkaName";
        _bio = bio ?? "Nessuna descrizione inserita.";
        _numParticipatedEvents = int.tryParse(numParticipatedEventsStr ?? "0") ?? 0;
        _numFollowers = followers;
        _numFollowing = followingCount;
      });
    }
  }
}
