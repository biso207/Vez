import 'dart:ui';

import 'package:flutter/material.dart';

import '../../models/home_event.dart';
import '../../services/haptic_service.dart';
import '../../services/translation_service.dart';

// ── vez event card ──────────────────────────────────────────────────────────
//
//   used for: polymorphic entry point for event cards.
//   design: decides whether to show a simple or a "by you" event card.
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

  // ── build ──────────────────────────────────────────────────────────────────
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

// ── simple event card ───────────────────────────────────────────────────────
//
//   used for: displaying basic info for invited or nearby events.
//   design: full-bleed background image with bottom text overlay.
class _SimpleEventCard extends StatelessWidget {
  const _SimpleEventCard({required this.event});

  final HomeEventCardData event;

  // ── build ──────────────────────────────────────────────────────────────────
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  if (event.distanceKm != null) ...[
                    SizedBox(height: 8 * s),
                    Text(
                      _formatDistance(event.distanceKm!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14 * s,
                        fontWeight: FontWeight.bold,
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

  // ── format distance ────────────────────────────────────────────────────────
  //
  //   used for: converting numeric km values into readable strings (m/km).
  String _formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(distanceKm < 10 ? 1 : 0)} km';
  }
}

// ── by you event card ───────────────────────────────────────────────────────
//
//   used for: displaying events created by the current user.
//   design: image background with action buttons (edit, guests) and RSVP totals.
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

  // ── build ──────────────────────────────────────────────────────────────────
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // left buttons
                        Row(
                          children: [
                            _CardIconCircle(
                              iconPath: event.categoryIconPath,
                              isBlueAccent: true,
                              size: 44 * s,
                              iconSize: 28 * s,
                            ),
                            SizedBox(width: 10 * s),
                            _CardIconCircle(
                              iconPath: event.typeIconPath,
                              size: 44 * s,
                              iconSize: 28 * s,
                            ),
                          ],
                        ),

                        // right buttons
                        Row(
                          children: [
                            _CardIconCircle(
                              iconPath: 'assets/icons/event/guests.png',
                              onTap: onGuestListTap,
                              size: 44 * s,
                              iconSize: 28 * s,
                            ),
                            SizedBox(width: 10 * s),
                            _CardIconCircle(
                              iconPath: 'assets/icons/event/edit.png',
                              onTap: onEditTap,
                              size: 44 * s,
                              iconSize: 28 * s,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (event.canInviteGuests) ...[
                      Align(
                        alignment: Alignment.center,
                        child: _CardPillButton(
                          label: StringRes.at('add_guests'),
                          onTap: onAddGuestsTap,
                        ),
                      ),
                      SizedBox(height: 14 * s),
                    ],
                    Text(
                      event.title.isNotEmpty ? event.title : 'Untitled Event',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40 * s,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),

                    SizedBox(height: 8 * s),

                    // date
                    if (event.dateLabel.isNotEmpty)
                      Text(
                        event.dateLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15 * s,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    // location
                    if (event.locationLabel.isNotEmpty) ...[
                      SizedBox(height: 2 * s),
                      Text(
                        event.locationLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15 * s,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],

                    SizedBox(height: 14 * s),

                    // guests state banner
                    Align(
                      alignment: Alignment.center,
                      child: _GuestStateBanner(counts: event.guestCounts, s: s),
                    ),
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

// ── card icon circle ────────────────────────────────────────────────────────
//
//   used for: displaying status icons or action buttons on event cards.
//   design: glass-morphism circular container with blur and optional highlight.
class _CardIconCircle extends StatelessWidget {
  const _CardIconCircle({
    required this.iconPath,
    this.onTap,
    this.isBlueAccent = false,
    this.size = 40,
    this.iconSize = 20,
  });

  final String iconPath;
  final VoidCallback? onTap;
  final bool isBlueAccent;
  final double size;
  final double iconSize;

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final Widget child = ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isBlueAccent
                ? const Color.fromARGB(51, 6, 0, 92)
                : const Color.fromARGB(70, 0, 0, 0),
            border: Border.all(
              color: isBlueAccent
                  ? const Color.fromARGB(128, 0, 10, 218)
                  : const Color.fromARGB(150, 255, 255, 255),
              width: 2,
            ),
          ),
          child: Center(
            child: Image.asset(
              iconPath,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
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

// ── card pill button ────────────────────────────────────────────────────────
//
//   used for: call-to-action buttons (like "Add Guests") on event cards.
//   design: frosted-glass pill-shaped capsule with bold text.
class _CardPillButton extends StatelessWidget {
  const _CardPillButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  // ── build ──────────────────────────────────────────────────────────────────
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
              fontSize: 18,
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

// ── guest state banner ──────────────────────────────────────────────────────
//
//   used for: displaying a summary of RSVP totals (Going, Not Going, Maybe).
//   design: horizontal glass banner with three count segments.
class _GuestStateBanner extends StatelessWidget {
  const _GuestStateBanner({required this.counts, required this.s});

  final HomeEventGuestCounts counts;
  final double s;

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(35 * s),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          constraints: BoxConstraints(minWidth: 230 * s, maxWidth: 280 * s),
          padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 11 * s),
          decoration: BoxDecoration(
            color: const Color.fromARGB(51, 0, 0, 0),
            borderRadius: BorderRadius.circular(35 * s),
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
              //Container(width: 1.25, height: 34 * s, color: Colors.white24),
              Expanded(
                child: _GuestStateItem(
                  iconPath:
                      'assets/icons/event/participation_state/not_going.png',
                  label: StringRes.at('not_going'),
                  value: counts.notGoing,
                  s: s,
                ),
              ),
              //Container(width: 1.25, height: 34 * s, color: Colors.white24),
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

// ── guest state item ────────────────────────────────────────────────────────
//
//   used for: a single RSVP category within the guest state banner.
//   design: vertical arrangement of icon, label, and numeric value.
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

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // state icone
        Image.asset(
          iconPath,
          width: 20 * s,
          height: 20 * s,
          fit: BoxFit.contain,
        ),

        SizedBox(height: 4 * s), // distance

        // state name
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12 * s,
            fontWeight: FontWeight.w600,
          ),
        ),

        SizedBox(height: 4 * s), // distance

        // number of guests
        Text(
          '$value',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20 * s,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
