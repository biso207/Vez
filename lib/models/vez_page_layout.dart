import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vez/models/vez_event_card.dart';
import 'package:vez/models/vez_glass.dart';
import 'package:vez/models/vez_popup.dart';

import '../services/translation_service.dart';

class VezPageLayout extends StatelessWidget {
  final Widget body;
  final Widget? bottomNavBar;
  final double horizontalMargin;
  final TextEditingController searchController;
  final String profileIconPath;
  final bool isProfileAvatar;
  final VoidCallback? onProfileTap;
  final String searchHint;
  final String filterIconPath;
  final ValueChanged<int>? onFilterSelected;

  VezPageLayout({
    super.key,
    required this.body,
    this.bottomNavBar,
    required this.searchController,
    this.profileIconPath = "",
    this.isProfileAvatar = false,
    this.onProfileTap,
    this.searchHint = "Search",
    this.filterIconPath = "",
    this.onFilterSelected,
    this.horizontalMargin = 40.0,
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
      resizeToAvoidBottomInset: false,
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
            height: 300,
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
            child: _buildTopNavBar(context), // standard layout
          ),

          if (bottomNavBar != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 40,
              left: 0, right: 0, // Lasciato a 0 per permettere al Center di centrarla perfettamente nello schermo
              child: Center(child: bottomNavBar!),
            ),
        ],
      ),
    );
  }

  // widget template for the top navbar of every pages
  Widget _buildTopNavBar(BuildContext context) {
    final bool isNetworkImage =
    profileIconPath.startsWith("http");

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: onProfileTap ?? () {},
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isProfileAvatar
                    ? Colors.white
                    : Colors.white54,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: isProfileAvatar
                  ? (profileIconPath.isEmpty
                  ? const Icon(Icons.person,
                  color: Colors.white)
                  : Image(
                image: isNetworkImage
                    ? NetworkImage(profileIconPath)
                    : AssetImage(profileIconPath)
                as ImageProvider,
                fit: BoxFit.cover,
                width: 45,
                height: 45,
              ))
                  : Center(
                child: Image.asset(
                  profileIconPath,
                  width: 30,
                  height: 30,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 20),

        Expanded(
          child: VezGlass.textField(
            controller: searchController,
            hint: searchHint,
            prefixIcon:
            const Icon(Icons.search, color: Colors.white70),
            color: Colors.white,
          ),
        ),

        const SizedBox(width: 20),

        VezGlass.circleButton(
          assetIcon: filterIconPath,
          onTap: () {
            VezPopup.show(
              context: context,
              width: 250,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPopupItem(
                    icon: eventGroupsIcons[0]["icon"],
                    label: StringRes.at("filter_by_you"),
                    onTap: () {
                      onFilterSelected?.call(0);
                      Navigator.pop(context);
                    },
                  ),
                  _customDivider(),
                  _buildPopupItem(
                    icon: eventGroupsIcons[1]["icon"],
                    label: StringRes.at("filter_invited"),
                    onTap: () {
                      onFilterSelected?.call(1);
                      Navigator.pop(context);
                    },
                  ),
                  _customDivider(),
                  _buildPopupItem(
                    icon: eventGroupsIcons[2]["icon"],
                    label: StringRes.at("filter_nearby"),
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
                fontWeight: FontWeight.bold,
                fontSize: 20,
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
}