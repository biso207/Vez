import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/event_catalog.dart';
import '../services/haptic_service.dart';
import '../services/translation_service.dart';

enum EventType { byYou, invited, nearby }

class HomeEventGuestCounts {
  const HomeEventGuestCounts({
    this.going = 0,
    this.notGoing = 0,
    this.maybe = 0,
  });

  final int going;
  final int notGoing;
  final int maybe;
}

class HomeEventGuestData {
  const HomeEventGuestData({
    required this.userId,
    required this.username,
    required this.profilePhoto,
    required this.state,
    this.role = 'guest',
  });

  final String userId;
  final String username;
  final String profilePhoto;
  final String state;
  final String role;
}

class HomeEventCardData {
  const HomeEventCardData({
    required this.eventId,
    required this.imagePath,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.typeLabel,
    required this.categoryName,
    required this.categoryIconPath,
    required this.typeIconPath,
    required this.dateLabel,
    required this.locationLabel,
    required this.rawDateEvent,
    required this.creatorUserId,
    required this.creatorUsername,
    required this.creatorProfilePhoto,
    this.description = '',
    this.placeId = '',
    this.placeAddress = '',
    this.locationPrecise = false,
    this.latitude,
    this.longitude,
    this.maxGuests,
    this.price,
    this.guestCounts = const HomeEventGuestCounts(),
    this.guests = const [],
  });

  final String eventId;
  final String imagePath;
  final EventType type;
  final String title;
  final String subtitle;
  final String typeLabel;
  final String categoryName;
  final String categoryIconPath;
  final String typeIconPath;
  final String dateLabel;
  final String locationLabel;
  final String rawDateEvent;
  final String creatorUserId;
  final String creatorUsername;
  final String creatorProfilePhoto;
  final String description;
  final String placeId;
  final String placeAddress;
  final bool locationPrecise;
  final double? latitude;
  final double? longitude;
  final int? maxGuests;
  final int? price;
  final HomeEventGuestCounts guestCounts;
  final List<HomeEventGuestData> guests;

  bool get isByYou => type == EventType.byYou;

  bool get canInviteGuests {
    return isByYou && EventCatalog.canInviteGuests(typeLabel);
  }

  String get resolvedImagePath {
    final String trimmed = imagePath.trim();
    return trimmed.isEmpty ? EventCatalog.defaultBackgroundImage : trimmed;
  }
}

class VezEventCard extends StatelessWidget {
  const VezEventCard({
    super.key,
    required this.event,
    this.onAddGuestsTap,
    this.onGuestListTap,
    this.onEditTap,
  });

  final HomeEventCardData event;
  final VoidCallback? onAddGuestsTap;
  final VoidCallback? onGuestListTap;
  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context) {
    if (event.isByYou) {
      return _ByYouEventCard(
        event: event,
        onAddGuestsTap: onAddGuestsTap,
        onGuestListTap: onGuestListTap,
        onEditTap: onEditTap,
      );
    }

    return _SimpleEventCard(event: event);
  }
}

class _SimpleEventCard extends StatelessWidget {
  const _SimpleEventCard({required this.event});

  final HomeEventCardData event;

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double cardHeight = screenHeight * 0.65;
    final double cardWidth = screenWidth * 0.85;
    final double s = (screenWidth / 390).clamp(0.8, 1.2);
    final bool isNetworkImage = event.resolvedImagePath.startsWith('http');

    return Center(
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          image: DecorationImage(
            image: isNetworkImage
                ? NetworkImage(event.resolvedImagePath)
                : AssetImage(event.resolvedImagePath) as ImageProvider,
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
                      const Color.fromRGBO(0, 0, 0, 0.88),
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
                    event.title.isNotEmpty ? event.title : 'Untitled Event',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26 * s,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (event.subtitle.isNotEmpty) ...[
                    SizedBox(height: 6 * s),
                    Text(
                      event.subtitle,
                      maxLines: 2,
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

class _ByYouEventCard extends StatelessWidget {
  const _ByYouEventCard({
    required this.event,
    required this.onAddGuestsTap,
    required this.onGuestListTap,
    required this.onEditTap,
  });

  final HomeEventCardData event;
  final VoidCallback? onAddGuestsTap;
  final VoidCallback? onGuestListTap;
  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double cardHeight = screenHeight * 0.65;
    final double cardWidth = screenWidth * 0.85;
    final double s = (screenWidth / 390).clamp(0.8, 1.2);
    final bool isNetworkImage = event.resolvedImagePath.startsWith('http');

    return Center(
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          boxShadow: const [
            BoxShadow(
              color: Colors.white54,
              blurRadius: 5,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: isNetworkImage
                        ? NetworkImage(event.resolvedImagePath)
                        : AssetImage(event.resolvedImagePath) as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color.fromRGBO(0, 0, 0, 0.30),
                        const Color.fromRGBO(0, 0, 0, 0.20),
                        const Color.fromRGBO(0, 0, 0, 0.92),
                      ],
                      stops: const [0.0, 0.38, 1.0],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(14 * s, 14 * s, 14 * s, 16 * s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _CardIconCircle(
                              iconPath: event.categoryIconPath,
                              isBlueAccent: true,
                            ),
                            SizedBox(width: 8 * s),
                            _CardIconCircle(iconPath: event.typeIconPath),
                          ],
                        ),
                        Row(
                          children: [
                            _CardIconCircle(
                              iconPath: 'assets/icons/event/guests.png',
                              onTap: onGuestListTap,
                            ),
                            SizedBox(width: 8 * s),
                            _CardIconCircle(
                              iconPath: 'assets/icons/event/edit.png',
                              onTap: onEditTap,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    Opacity(
                      opacity: event.canInviteGuests ? 1.0 : 0.45,
                      child: _CardPillButton(
                        label: StringRes.at('add_guests'),
                        onTap: event.canInviteGuests ? onAddGuestsTap : null,
                      ),
                    ),
                    SizedBox(height: 14 * s),
                    Text(
                      event.title.isNotEmpty ? event.title : 'Untitled Event',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23 * s,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                    SizedBox(height: 8 * s),
                    if (event.dateLabel.isNotEmpty)
                      Text(
                        event.dateLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13 * s,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (event.locationLabel.isNotEmpty) ...[
                      SizedBox(height: 2 * s),
                      Text(
                        event.locationLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13 * s,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    SizedBox(height: 12 * s),
                    _GuestStateBanner(counts: event.guestCounts, s: s),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardIconCircle extends StatelessWidget {
  const _CardIconCircle({
    required this.iconPath,
    this.onTap,
    this.isBlueAccent = false,
  });

  final String iconPath;
  final VoidCallback? onTap;
  final bool isBlueAccent;

  @override
  Widget build(BuildContext context) {
    final Widget child = ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isBlueAccent
                ? const Color.fromARGB(95, 0, 11, 223)
                : const Color.fromARGB(70, 0, 0, 0),
            border: Border.all(
              color: isBlueAccent
                  ? const Color.fromARGB(170, 0, 11, 223)
                  : const Color.fromARGB(150, 255, 255, 255),
              width: 2,
            ),
          ),
          child: Center(
            child: ImageIcon(
              AssetImage(iconPath),
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );

    if (onTap == null) {
      return child;
    }

    return GestureDetector(
      onTap: () {
        HapticService.tap();
        onTap!();
      },
      child: child,
    );
  }
}

class _CardPillButton extends StatelessWidget {
  const _CardPillButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget child = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            color: const Color.fromARGB(51, 255, 255, 255),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color.fromARGB(128, 255, 255, 255),
              width: 2,
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );

    if (onTap == null) {
      return child;
    }

    return GestureDetector(
      onTap: () {
        HapticService.tap();
        onTap!();
      },
      child: child,
    );
  }
}

class _GuestStateBanner extends StatelessWidget {
  const _GuestStateBanner({required this.counts, required this.s});

  final HomeEventGuestCounts counts;
  final double s;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 8 * s),
          decoration: BoxDecoration(
            color: const Color.fromARGB(70, 0, 0, 0),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color.fromARGB(128, 255, 255, 255),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _GuestStateItem(
                  iconPath: 'assets/icons/event/participation_state/going.png',
                  label: StringRes.at('going'),
                  value: counts.going,
                  s: s,
                ),
              ),
              Container(width: 1.5, height: 30 * s, color: Colors.white24),
              Expanded(
                child: _GuestStateItem(
                  iconPath:
                  'assets/icons/event/participation_state/not_going.png',
                  label: StringRes.at('not_going'),
                  value: counts.notGoing,
                  s: s,
                ),
              ),
              Container(width: 1.5, height: 30 * s, color: Colors.white24),
              Expanded(
                child: _GuestStateItem(
                  iconPath: 'assets/icons/event/participation_state/maybe.png',
                  label: StringRes.at('maybe'),
                  value: counts.maybe,
                  s: s,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestStateItem extends StatelessWidget {
  const _GuestStateItem({
    required this.iconPath,
    required this.label,
    required this.value,
    required this.s,
  });

  final String iconPath;
  final String label;
  final int value;
  final double s;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ImageIcon(AssetImage(iconPath), color: Colors.white, size: 18 * s),
        SizedBox(height: 4 * s),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11 * s,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2 * s),
        Text(
          '$value',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15 * s,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}