// Developed and Designed by Outly • © 2026
// Class to manage the graphic of the event's preview

import 'package:flutter/material.dart';

enum EventType { byYou, invited, nearby }

class VezEventCard extends StatelessWidget {
  final String imagePath;
  final EventType type;

  const VezEventCard({
    super.key,
    required this.imagePath,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    // Definizione di dimensioni responsive basate sullo schermo
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    // Altezza impostata al 65% dello schermo, larghezza all'85% per garantire un rettangolo verticale
    final double cardHeight = screenHeight * 0.65;
    final double cardWidth = screenWidth * 0.85;

    return Center(
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white54,
              blurRadius: 5,
              offset: const Offset(0, -1), // Centered glow/shadow effect as requested
            ),
          ],
        ),
        child: Stack(
          children: [
            /// Gradiente interno in basso per far leggere il testo ("Progressive blur")
            Positioned(
              bottom: 0, left: 0, right: 0,
              height: 250,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
              ),
            ),

            /// Qui dentro in futuro metteremo gli switch sul 'type' per mostrare
            /// bottoni, titoli e partecipanti in base al tipo di evento.
            /// Esempio segnaposto:
            Positioned(
              bottom: 30, left: 0, right: 0,
              child: Center(
                child: Text(
                  "Event Details Here",
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}