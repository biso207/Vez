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
    return Center(
      child: Container(
        width: 320,
        height: 550,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
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