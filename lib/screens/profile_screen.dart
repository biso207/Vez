// Developed and Designed by Outly • © 2026
// Screen to manage the user profile page
// When a logged user views a profile or wants to see his profile, this screen is opened.


import 'package:flutter/material.dart';
import '../models/vez_glass.dart';
import '../models/vez_page_layout.dart';
import '../models/vez_event_card.dart';
import '../models/vez_popup.dart';
import '../services/getters_service.dart';
import '../services/user_session.dart';
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

  // Lista fittizia per il carosello
  /// questa lista sarà dinamicamente creata in base agli eventi per l'utente
  /// loggato e al filtro di eventi che vuole visualizzare
  final List<Map<String, dynamic>> dummyEvents = [
    {"image": "assets/images/bg/bg_signup.jpg", "type": EventType.nearby},
    {"image": "assets/images/bg/bg_login.jpg", "type": EventType.invited},
    {"image": "assets/images/bg/bg_signup.jpg", "type": EventType.byYou}
  ];

  // list of icons of the event types
  final List<Map<String, dynamic>> eventGroupsIcons = [
    {"icon": "assets/icons/home_page/by_you_events.png", "type": EventType.byYou},
    {"icon": "assets/icons/home_page/invited_events.png", "type": EventType.invited},
    {"icon": "assets/icons/home_page/nearby_events.png", "type": EventType.nearby}
  ];

  // default event group index
  int _indexEventGroup = 1;

  // instance of the remote db service
  final RemoteDbService _dbService = RemoteDbService();
  // user profile photo
  String _profilePhoto = "";

  // trigger
  @override
  void initState() {
    super.initState();
    // getting the profile photo of the user at the start of the page
    getUserProfilePhoto();
  }

  // getter of the user profile photo
  void getUserProfilePhoto() async {
    // Recuperiamo il path dal servizio
    String photo = await _dbService.getProfilePhoto(UserSession().username);

    // Aggiorniamo lo stato per far apparire la foto
    if (mounted) { // Controllo di sicurezza: l'utente potrebbe aver cambiato pagina nel frattempo
      setState(() {
        _profilePhoto = photo;
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // --- PAGE LAYOUT ---
  @override
  Widget build(BuildContext context) {
    return VezPageLayout(
      // --- TOP NAVBAR (PARAMETERS) ---
      searchController: searchController,

      // user profile photo
      profileIconPath: "assets/icons/profile_page/settings.png",
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
              icon: ImageIcon(const AssetImage("assets/icons/nav_bar/go_to_home_page.png"), color: Colors.white),
              iconSize: 30,
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => HomePage()),
                );
              },
            ),
            IconButton(
              icon: ImageIcon(const AssetImage("assets/icons/nav_bar/create_event.png"), color: Colors.white),
              iconSize: 30,
              onPressed: () {},
            ),
            IconButton(
              icon: ImageIcon(const AssetImage("assets/icons/nav_bar/notifications.png"), color: Colors.white),
              iconSize: 30,
              onPressed: () {},
            ),
          ],
        ),
      ),

      // --- CENTRE (EVENTS CAROUSEL) ---
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        controller: PageController(viewportFraction: 0.75),
        itemCount: dummyEvents.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: VezEventCard(
              imagePath: dummyEvents[index]["image"],
              type: dummyEvents[index]["type"],
            ),
          );
        },
      ),
    );
  }
}