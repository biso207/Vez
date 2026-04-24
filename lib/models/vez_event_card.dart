import 'package:flutter/material.dart';

enum EventType { byYou, invited, nearby }

class HomeEventCardData {
  const HomeEventCardData({
    required this.imagePath,
    required this.type,
    required this.title,
    required this.subtitle,
  });

  final String imagePath;
  final EventType type;
  final String title;
  final String subtitle;
}

class VezEventCard extends StatelessWidget {
  const VezEventCard({
    super.key,
    required this.imagePath,
    required this.type,
    this.title = '',
    this.subtitle = '',
  });

  final String imagePath;
  final EventType type;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double cardHeight = screenHeight * 0.65;
    final double cardWidth = screenWidth * 0.85;
    final double s = (screenWidth / 390).clamp(0.8, 1.2);
    final bool isNetworkImage = imagePath.startsWith('http');

    return Center(
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          image: DecorationImage(
            image: isNetworkImage
                ? NetworkImage(imagePath)
                : AssetImage(imagePath) as ImageProvider,
            fit: BoxFit.cover,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.white54,
              blurRadius: 5,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 250,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(40),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.88),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 24 * s,
              right: 24 * s,
              bottom: 28 * s,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title.isNotEmpty ? title : 'Untitled Event',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26 * s,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    SizedBox(height: 6 * s),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15 * s,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
