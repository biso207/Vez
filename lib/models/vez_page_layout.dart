import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vez/models/vez_event_card.dart';
import 'package:vez/models/vez_glass.dart';
import 'package:vez/models/vez_popup.dart';
import 'package:vez/screens/home_screen.dart';

class VezPageLayout extends StatelessWidget {
  final Widget body;
  final Widget? bottomNavBar;
  final double horizontalMargin;
  final TextEditingController searchController;
  final String profileIconPath;
  final VoidCallback? onProfileTap;
  final String searchHint;
  final String filterIconPath;
  final ValueChanged<int>? onFilterSelected;

  VezPageLayout({
    super.key,
    required this.body,
    this.bottomNavBar,
    required this.searchController, // Required
    this.profileIconPath = "", // Optional
    this.onProfileTap, // Optional
    this.searchHint = "Search", // Optional
    this.filterIconPath = "", // Optional
    this.onFilterSelected, // Optional
    this.horizontalMargin = 52.0,
  });

  // list of icons of the event types
  final List<Map<String, dynamic>> eventGroupsIcons = [
    {"icon": "assets/icons/home_page/by_you_events.png", "type": EventType.byYou},
    {"icon": "assets/icons/home_page/invited_events.png", "type": EventType.invited},
    {"icon": "assets/icons/home_page/nearby_events.png", "type": EventType.nearby}
  ];

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFF0E0E0E);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          /// 1) Sfondo Globale: (Già impostato dal backgroundColor dello Scaffold)

          /// 2) Contenuto Centrale allineato alla Griglia
          Positioned(
            top: 0,
            bottom: 0,
            left: horizontalMargin,  // <-- Applica la linea blu di sinistra
            right: horizontalMargin, // <-- Applica la linea blu di destra
            child: body,
          ),

          /// 3) OVERGROUND: Blur Progressivo (Top) - Rimane a tutto schermo!
          Positioned(
            top: 0, left: 0, right: 0,
            height: 200,
            child: IgnorePointer(
              child: ShaderMask(
                shaderCallback: (rect) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black, Colors.transparent],
                    stops: [0.1, 1.0],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [bgColor.withOpacity(0.8), Colors.transparent],
                        )
                    ),
                  ),
                ),
              ),
            ),
          ),

          /// 4) OVERGROUND: Blur Progressivo (Bottom) - Rimane a tutto schermo!
          Positioned(
            bottom: 0, left: 0, right: 0,
            height: 200,
            child: IgnorePointer(
              child: ShaderMask(
                shaderCallback: (rect) {
                  return const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black, Colors.transparent],
                    stops: [0.1, 1.0],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [bgColor.withOpacity(0.8), Colors.transparent],
                        )
                    ),
                  ),
                ),
              ),
            ),
          ),

          /// 5) Navbars
          Positioned(
            top: MediaQuery.of(context).padding.top + 40,
            left: horizontalMargin,  // <-- Allineata alla griglia sx
            right: horizontalMargin, // <-- Allineata alla griglia dx
            child: _buildTopNavBar(context), // <--- Usa il nuovo layout
          ),

          if (bottomNavBar != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 0, right: 0, // Lasciato a 0 per permettere al Center di centrarla perfettamente nello schermo
              child: Center(child: bottomNavBar!),
            ),
        ],
      ),
    );
  }

  Widget _buildTopNavBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        VezGlass.circleButton(
          assetIcon: profileIconPath,
          onTap: onProfileTap ?? () {},
          size: 45,
          iconSize: 24,
        ),
        const SizedBox(width: 20), // Spazio significativo
        Expanded(
          child: VezGlass.textField(
            controller: searchController,
            hint: searchHint,
            prefixIcon: const Icon(Icons.search, color: Colors.white70), color: Colors.white,
            // Regolerò l'altezza e il raggio di curvatura per abbinare le immagini
            // L'altezza è di 44. Il raggio di curvatura del container glass
          ),
        ),
        const SizedBox(width: 20), // Spazio significativo


        // PULSANTE FILTRO MODIFICATO
        VezGlass.circleButton(
          assetIcon: filterIconPath,
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
                      onFilterSelected?.call(0);
                      Navigator.pop(context);
                    },
                  ),
                  _customDivider(),
                  _buildPopupItem(
                    icon: eventGroupsIcons[1]["icon"],
                    label: "Invited",
                    onTap: () {
                      onFilterSelected?.call(1);
                      Navigator.pop(context);
                    },
                  ),
                  _customDivider(),
                  _buildPopupItem(
                    icon: eventGroupsIcons[2]["icon"],
                    label: "Nearby",
                    onTap: () {
                      onFilterSelected?.call(2);
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
    );
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

  void setState(int Function() param0) {}
}