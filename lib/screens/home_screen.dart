// Developed and Designed by Outly • © 2026
// Screen to manage the home page of the app

import 'package:flutter/material.dart';
import '../models/vez_glass.dart';
import '../models/vez_page_layout.dart';
import '../models/vez_event_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

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
  final List<Map<String, dynamic>> eventTypesIcons = [
    {"icon": "assets/images/icons/home_page/by_you_events.png", "type": EventType.byYou},
    {"icon": "assets/images/icons/home_page/invited_events.png", "type": EventType.invited},
    {"icon": "assets/images/icons/home_page/nearby_events.png", "type": EventType.nearby}
  ];


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
          // Icona Profilo
          VezGlass.circleButton(
            assetIcon: "assets/images/icons/icon_profile.png", // Metti la tua icona
            onTap: () {},
            size: 45, iconSize: 24,
          ),

          // Barra di Ricerca Centrale
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: VezGlass.textField(
                controller: searchController,
                hint: "Search",
                height: 45,
                color: Colors.white70
              ),
            ),
          ),

          // filter events icon
          VezGlass.circleButton(
            assetIcon: eventTypesIcons[1]["icon"], // icon based on the event type
            onTap: () {}, // opens the filter selection overscreen
            size: 45, iconSize: 24,
          ),
        ],
      ),

      // --- BOTTOM NAVBAR ---
      bottomNavBar: VezGlass.container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        radius: BorderRadius.circular(22),
        child: SizedBox(
          width: 140, // Larghezza netta interna per i bottoni
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: ImageIcon( const AssetImage("assets/images/icons/nav_bar/go_to_home_page.png")),
                onPressed: () {},
              ),
              IconButton(
                icon: ImageIcon( const AssetImage("assets/images/icons/nav_bar/create_event.png")),
                onPressed: () {},
              ),
              // Il nostro nuovo tasto notifiche
              IconButton(
                icon: ImageIcon( const AssetImage("assets/images/icons/nav_bar/notifications.png")),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),

      // --- CENTRE (EVENTS CAROUSEL) ---
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        controller: PageController(viewportFraction: 0.8), // Fa sbordare il prossimo/precedente evento
        itemCount: dummyEvents.length, // number of events to display
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1), // space between the events
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