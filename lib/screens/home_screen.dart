// Developed and Designed by Outly • © 2026
// Screen to manage the home page of the app

import 'package:flutter/material.dart';
import '../models/vez_glass.dart';
import '../models/vez_page_layout.dart';
import '../models/vez_event_card.dart';
import '../models/vez_popup.dart';
import '../services/getters_service.dart';

class HomePage extends StatefulWidget {
  // attributes/variables for the class
  final String username;

  // costruttore
  const HomePage({
    super.key,
    required this.username,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
    {"icon": "assets/images/icons/home_page/by_you_events.png", "type": EventType.byYou},
    {"icon": "assets/images/icons/home_page/invited_events.png", "type": EventType.invited},
    {"icon": "assets/images/icons/home_page/nearby_events.png", "type": EventType.nearby}
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

  void getUserProfilePhoto() async {
    // Recuperiamo il path dal servizio
    String photo = await _dbService.getProfilePhoto(widget.username);

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

  @override
  Widget build(BuildContext context) {
    return VezPageLayout(
      // --- TOP NAVBAR ---
      topNavBar: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          VezGlass.circleButton(
            // Se _profilePhoto è vuota, il widget userà il default asset definito in vez_glass
            assetIcon: _profilePhoto,
            onTap: () {
              // futura apertura della pagina di profilo
            },
            size: 44,
            iconSize: 24,
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: VezGlass.textField(
                controller: searchController,
                hint: "Search",
                width: 100, height: 44,
                color: Colors.white54,
                suffixIcon: ImageIcon(const AssetImage("assets/images/icons/home_page/search.png"), size: 30, color: Colors.white)
              ),
            ),
          ),

          // PULSANTE FILTRO MODIFICATO
          VezGlass.circleButton(
            assetIcon: eventGroupsIcons[_indexEventGroup]["icon"],
            onTap: () {
              VezPopup.show(
                context: context,
                width: 250, // Più largo come richiesto
                alignment: Alignment.center, // Centered on the page
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPopupItem(
                      icon: eventGroupsIcons[0]["icon"],
                      label: "By You",
                      onTap: () {
                        setState(() => _indexEventGroup = 0);
                        Navigator.pop(context);
                      },
                    ),
                    _customDivider(),
                    _buildPopupItem(
                      icon: eventGroupsIcons[1]["icon"],
                      label: "Invited",
                      onTap: () {
                        setState(() => _indexEventGroup = 1);
                        Navigator.pop(context);
                      },
                    ),
                    _customDivider(),
                    _buildPopupItem(
                      icon: eventGroupsIcons[2]["icon"],
                      label: "Nearby",
                      onTap: () {
                        setState(() => _indexEventGroup = 2);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            },
            size: 44,
            iconSize: 30,
          ),
        ],
      ),

      // --- BOTTOM NAVBAR ---
      bottomNavBar: VezGlass.container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0), // Padding ridotto
        radius: BorderRadius.circular(40),
        child: Row(
          mainAxisSize: MainAxisSize.min, // adapt the width to the icons (the children)
          children: [
            IconButton(
              icon: ImageIcon(const AssetImage("assets/images/icons/nav_bar/go_to_home_page.png"), color: Colors.white),
              iconSize: 30,
              onPressed: () {},
            ),
            IconButton(
              icon: ImageIcon(const AssetImage("assets/images/icons/nav_bar/create_event.png"), color: Colors.white),
              iconSize: 30,
              onPressed: () {},
            ),
            IconButton(
              icon: ImageIcon(const AssetImage("assets/images/icons/nav_bar/notifications.png"), color: Colors.white),
              iconSize: 30,
              onPressed: () {},
            ),
          ],
        ),
      ),

      // --- CENTRE (EVENTS CAROUSEL) ---
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        controller: PageController(viewportFraction: 0.75), // Fa sbordare il prossimo/precedente evento
        itemCount: dummyEvents.length, // number of events to display
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

// --- Helper Widgets per mantenere il codice pulito ---

Widget _buildPopupItem({required String icon, required String label, required VoidCallback onTap}) {
  return GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque, // Rende cliccabile tutta l'area
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
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _customDivider() {
  return Center(
    child: Container(
      width: 200, // Divider più stretto del popup
      height: 2,
      color: Colors.white54,
    ),
  );
}