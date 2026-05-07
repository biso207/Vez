// Developed and Designed by Outly • © 2026
// Reusable in-app preview event card

import 'dart:ui';
import 'package:flutter/material.dart';

import '../../models/home_event.dart';
import '../../services/haptic_service.dart';
import '../../services/translation_service.dart';
import '../../services/user_session.dart';

const double kBlurValue = 5.0;

// ── vez event card ──────────────────────────────────────────────────────────
//
// used for: polymorphic entry point for event cards.
// design: decides whether to show a detailed "by you" card or a preview rsvp card.
class VezEventCard extends StatelessWidget {
  const VezEventCard({
    super.key,
    required this.event,
    this.onAddGuestsTap,
    this.onGuestListTap,
    this.onManageCohostsTap,
    this.onEditTap,
    this.onResponseSelected,
  });

  final HomeEventCardData event;
  final VoidCallback? onAddGuestsTap;
  final VoidCallback? onGuestListTap;
  final VoidCallback? onManageCohostsTap;
  final VoidCallback? onEditTap;
  final ValueChanged<String>? onResponseSelected;

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // if the event is created by the user, use the management style card.
    if (event.isByYou) {
      return _ByYouEventCard(
        event: event,
        onAddGuestsTap: onAddGuestsTap,
        onGuestListTap: onGuestListTap,
        onManageCohostsTap: onManageCohostsTap,
        onEditTap: onEditTap,
      );
    }

    // for both invited and nearby events, use the preview rsvp style card.
    // nearby events are only shown here if they have a precise location (logic handled in controller).
    return _PreviewEventCard(
      event: event,
      onAddGuestsTap: onAddGuestsTap,
      onGuestListTap: onGuestListTap,
      onResponseSelected: onResponseSelected,
    );
  }
}

// ── preview event card ───────────────────────────────────────────────────────
//
// used for: displaying info and RSVP slider for invited or nearby events.
// design: full-bleed background image with bottom rsvp and metrics overlay.
class _PreviewEventCard extends StatefulWidget {
  const _PreviewEventCard({
    required this.event,
    required this.onGuestListTap,
    required this.onResponseSelected,
    this.onAddGuestsTap,
  });

  final HomeEventCardData event;
  final VoidCallback? onAddGuestsTap;
  final VoidCallback? onGuestListTap;
  final ValueChanged<String>? onResponseSelected;

  @override
  State<_PreviewEventCard> createState() => _PreviewEventCardState();
}

class _PreviewEventCardState extends State<_PreviewEventCard> {
  int _selectedIndex = 2;
  bool _isStepping = false;

  static const List<String> _states = ['going', 'not_going', 'maybe'];

  @override
  void initState() {
    super.initState();
    _selectedIndex = _indexForState(_currentUserState());
  }

  @override
  void didUpdateWidget(covariant _PreviewEventCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.event != widget.event) {
      _selectedIndex = _indexForState(_currentUserState());
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double cardHeight = screenHeight * 0.65;
    final double cardWidth = screenWidth * 0.85;
    final double s = (screenWidth / 390).clamp(0.8, 1.2);
    final bool isNetworkImage = widget.event.resolvedImagePath.startsWith(
      'http',
    );

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
              // 1. background image
              DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: isNetworkImage
                        ? NetworkImage(widget.event.resolvedImagePath)
                        : AssetImage(widget.event.resolvedImagePath)
                    as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // 2. dark gradient overlay for text readability
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color.fromRGBO(0, 0, 0, 0.24),
                        const Color.fromRGBO(0, 0, 0, 0.10),
                        const Color.fromRGBO(0, 0, 0, 0.92),
                      ],
                      stops: const [0.0, 0.42, 1.0],
                    ),
                  ),
                ),
              ),
              // 3. content layer
              Padding(
                padding: EdgeInsets.fromLTRB(16 * s, 16 * s, 16 * s, 16 * s),
                child: Column(
                  children: [
                    // top
                    _CardTopBar(
                      event: widget.event,
                      s: s,
                      onGuestListTap: widget.onGuestListTap,
                    ),

                    const Spacer(),

                    // add guests button (owner o cohost)
                    if (widget.event.canInviteGuests) ...[
                      _CardPillButton(
                        label: StringRes.at('add_guest'),
                        onTap: widget.onAddGuestsTap,
                        maxGuests: widget.event.maxGuests?.toInt() ?? 0,
                        goingGuests: widget.event.guestCounts.going,
                      ),
                      SizedBox(height: 20 * s),
                    ],

                    // title
                    Text(
                      widget.event.title.isNotEmpty
                          ? widget.event.title
                          : 'Untitled Event',
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

                    // date and place
                    if (widget.event.dateLabel.isNotEmpty)
                      _PreviewInfoText(text: widget.event.dateLabel, s: s),
                    if (widget.event.locationLabel.isNotEmpty) ...[
                      SizedBox(height: 2 * s),
                      _PreviewInfoText(text: widget.event.locationLabel, s: s),
                    ],
                    // distance is particularly relevant for "nearby" events
                    if (widget.event.distanceKm != null) ...[
                      SizedBox(height: 2 * s),
                      _PreviewInfoText(
                        text: _formatDistance(widget.event.distanceKm!),
                        s: s,
                      ),
                    ],

                    SizedBox(height: 8 * s),

                    // slider to make a choice
                    _ResponseSlider(
                      s: s,
                      selectedIndex: _selectedIndex,
                      onSelected: _selectState,
                    ),

                    SizedBox(height: 12 * s),

                    // bottom details
                    Row(
                      children: [
                        Expanded(
                          child: _GuestLimitPill(event: widget.event, s: s),
                        ),
                        SizedBox(width: 36 * s),
                        Expanded(
                          child: _PricePill(event: widget.event, s: s),
                        ),
                      ],
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

  // ── helpers ────────────────────────────────────────────────────────────────

  Future<void> _selectState(int targetIndex) async {
    if (_isStepping || targetIndex == _selectedIndex) return;
    HapticService.tap();
    _isStepping = true;
    while (mounted && _selectedIndex != targetIndex) {
      setState(() {
        _selectedIndex += targetIndex > _selectedIndex ? 1 : -1;
      });
      await Future<void>.delayed(const Duration(milliseconds: 130));
    }
    _isStepping = false;
    widget.onResponseSelected?.call(_states[_selectedIndex]);
  }

  String _currentUserState() {
    final String userId = UserSession().userID;
    for (final HomeEventGuestData guest in widget.event.guests) {
      if (guest.userId == userId) return guest.state;
    }
    return 'maybe';
  }

  int _indexForState(String state) {
    final int index = _states.indexOf(state);
    return index < 0 ? 2 : index;
  }

  String _formatDistance(double distanceKm) {
    if (distanceKm < 1) return '${(distanceKm * 1000).round()} m';
    return '${distanceKm.toStringAsFixed(distanceKm < 10 ? 1 : 0)} km';
  }
}

// ── response slider ─────────────────────────────────────────────────────────
class _ResponseSlider extends StatelessWidget {
  const _ResponseSlider({
    required this.s,
    required this.selectedIndex,
    required this.onSelected,
  });

  final double s;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const List<_ResponseSliderItemData> _items = [
    _ResponseSliderItemData(
      state: 'going',
      iconPath: 'assets/icons/event/participation_state/going.png',
    ),
    _ResponseSliderItemData(
      state: 'not_going',
      iconPath: 'assets/icons/event/participation_state/not_going.png',
    ),
    _ResponseSliderItemData(
      state: 'maybe',
      iconPath: 'assets/icons/event/participation_state/maybe.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final double height = 60 * s;
    return ClipRRect(
      borderRadius: BorderRadius.circular(30 * s),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: kBlurValue, sigmaY: kBlurValue),
        child: SizedBox(
          height: height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double segmentWidth = constraints.maxWidth / _items.length;
              return Stack(
                children: [
                  Container(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(51, 0, 0, 0),
                      borderRadius: BorderRadius.circular(30 * s),
                      border: Border.all(
                        color: const Color.fromARGB(128, 255, 255, 255),
                        width: 2,
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeInOutCubic,
                    left: segmentWidth * selectedIndex,
                    top: 0,
                    bottom: 0,
                    width: segmentWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(51, 255, 255, 255),
                        borderRadius: BorderRadius.circular(30 * s),
                        border: Border.all(
                          color: const Color.fromARGB(128, 255, 255, 255),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (int i = 0; i < _items.length; i++)
                        Expanded(
                          child: _ResponseSliderItem(
                            data: _items[i],
                            s: s,
                            onTap: () => onSelected(i),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ResponseSliderItem extends StatelessWidget {
  const _ResponseSliderItem({
    required this.data,
    required this.s,
    required this.onTap,
  });
  final _ResponseSliderItemData data;
  final double s;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String label = switch (data.state) {
      'going' => StringRes.at('going'),
      'not_going' => StringRes.at('not_going'),
      _ => StringRes.at('maybe'),
    };
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(data.iconPath, width: 22 * s, height: 22 * s),
          SizedBox(height: 3 * s),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12 * s,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponseSliderItemData {
  const _ResponseSliderItemData({required this.state, required this.iconPath});
  final String state;
  final String iconPath;
}

// ── guest limit pill ────────────────────────────────────────────────────────
class _GuestLimitPill extends StatelessWidget {
  const _GuestLimitPill({required this.event, required this.s});
  final HomeEventCardData event;
  final double s;

  @override
  Widget build(BuildContext context) {
    final int? maxGuests = event.maxGuests;
    final int going = event.guestCounts.going;
    final String value = (maxGuests == null || maxGuests <= 0)
        ? StringRes.at('no_limit')
        : '$going/$maxGuests';
    final double progress = (maxGuests == null || maxGuests <= 0)
        ? 0
        : (going / maxGuests).clamp(0.0, 1.0);

    return _MetricPill(
      s: s,
      iconPath: 'assets/icons/event/guests.png',
      value: value,
      progress: progress,
      progressColor: const Color.fromARGB(102, 8, 157, 13),
    );
  }
}

// ── price pill ──────────────────────────────────────────────────────────────
class _PricePill extends StatelessWidget {
  const _PricePill({required this.event, required this.s});
  final HomeEventCardData event;
  final double s;

  @override
  Widget build(BuildContext context) {
    final int? price = event.price;
    final String value = (price == null || price <= 0)
        ? StringRes.at('no_price')
        : '€ $price,00';
    return _MetricPill(
      s: s,
      iconPath: 'assets/icons/event/price.png',
      fallbackIcon: Icons.payments_outlined,
      value: value,
      progress: 0,
      progressColor: Colors.transparent,
    );
  }
}

// ── metric pill ─────────────────────────────────────────────────────────────
class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.s,
    required this.iconPath,
    required this.value,
    required this.progress,
    required this.progressColor,
    this.fallbackIcon,
  });
  final double s;
  final String iconPath;
  final String value;
  final double progress;
  final Color progressColor;
  final IconData? fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30 * s),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: kBlurValue, sigmaY: kBlurValue),
        child: Container(
          height: 56 * s,
          decoration: const BoxDecoration(color: Color.fromARGB(51, 0, 0, 0)),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  if (progress > 0)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      width: constraints.maxWidth * progress,
                      height: constraints.maxHeight,
                      color: progressColor.withAlpha(199),
                    ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SafeAssetIcon(
                          iconPath: iconPath,
                          fallbackIcon: fallbackIcon,
                          size: 20 * s,
                        ),
                        SizedBox(height: 4 * s),
                        Text(
                          value,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15 * s,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30 * s),
                        border: Border.all(
                          color: const Color.fromARGB(128, 255, 255, 255),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── by you event card ───────────────────────────────────────────────────────
//
// used for: displaying info for yours events.
// design: full-bleed background image with bottom rsvp and metrics overlay.
class _ByYouEventCard extends StatelessWidget {
  const _ByYouEventCard({
    required this.event,
    required this.onAddGuestsTap,
    required this.onGuestListTap,
    required this.onManageCohostsTap,
    required this.onEditTap,
  });

  final HomeEventCardData event;
  final VoidCallback? onAddGuestsTap;
  final VoidCallback? onGuestListTap;
  final VoidCallback? onManageCohostsTap;
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
                padding: EdgeInsets.fromLTRB(16 * s, 16 * s, 16 * s, 16 * s),
                child: Column(
                  children: [
                    // top
                    _CardTopBar(
                      event: event,
                      s: s,
                      onGuestListTap: onGuestListTap,
                      onEditTap: onEditTap,
                    ),
                    if (event.canManageCohosts)
                      Padding(
                        padding: EdgeInsets.only(top: 12 * s),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _CardIconLabelButton(
                            label: StringRes.at('cohosts'),
                            icon: Icons.manage_accounts_rounded,
                            onTap: onManageCohostsTap,
                            s: s,
                          ),
                        ),
                      ),

                    const Spacer(),

                    // add guests button
                    if (event.canInviteGuests) ...[
                      _CardPillButton(
                        label: StringRes.at('add_guest'),
                        onTap: onAddGuestsTap,
                        maxGuests: event.maxGuests!.toInt(),
                        goingGuests: event.guestCounts.going,
                      ),
                      SizedBox(height: 20 * s),
                    ],

                    // title
                    Text(
                      event.title.isNotEmpty ? event.title : 'Untitled Event',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40 * s,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: 6 * s),

                    // date and place
                    if (event.dateLabel.isNotEmpty)
                      _PreviewInfoText(text: event.dateLabel, s: s),
                    if (event.locationLabel.isNotEmpty) ...[
                      SizedBox(height: 2 * s),
                      _PreviewInfoText(text: event.locationLabel, s: s),
                    ],
                    SizedBox(height: 8 * s),

                    // guests state info
                    _GuestStateBanner(counts: event.guestCounts, s: s),
                    SizedBox(height: 10 * s),

                    // bottom details
                    Row(
                      children: [
                        Expanded(
                          child: _GuestLimitPill(event: event, s: s),
                        ), // guest limit
                        SizedBox(width: 36 * s),
                        Expanded(
                          child: _PricePill(event: event, s: s),
                        ), // price
                      ],
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

// ── shared widgets ──────────────────────────────────────────────────────────

class _PreviewInfoText extends StatelessWidget {
  const _PreviewInfoText({required this.text, required this.s});
  final String text;
  final double s;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: 15 * s,
        fontWeight: FontWeight.normal,
        height: 1,
      ),
    );
  }
}

class _CardIconCircle extends StatelessWidget {
  const _CardIconCircle({
    required this.iconPath,
    this.onTap,
    this.isBlueAccent = false,
    this.showCohostBadge = false,
    this.size = 40,
    this.iconSize = 20,
  });
  final String iconPath;
  final VoidCallback? onTap;
  final bool isBlueAccent;
  final bool showCohostBadge;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final Widget child = Stack(
      clipBehavior: Clip
          .none, // Permette al badge di uscire dai bordi senza essere tagliato
      children: [
        // 1. Widget Base (Il cerchio principale)
        ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: kBlurValue, sigmaY: kBlurValue),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isBlueAccent
                    ? const Color.fromARGB(51, 6, 0, 92)
                    : const Color.fromARGB(51, 0, 0, 0),
                border: Border.all(
                  color: isBlueAccent
                      ? const Color.fromARGB(128, 0, 10, 218)
                      : const Color.fromARGB(128, 255, 255, 255),
                  width: 2,
                ),
              ),
              child: Center(
                child: Image.asset(iconPath, width: iconSize, height: iconSize),
              ),
            ),
          ),
        ),

        // Only the guest-list icon should show the co-host capability badge.
        // Category/type/edit icons reuse this widget without the badge.
        if (showCohostBadge)
          Positioned(
            bottom: -12,
            right: -12,
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: kBlurValue,
                  sigmaY: kBlurValue,
                ),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(102, 13, 113, 0),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color.fromARGB(204, 30, 255, 0),
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Image.asset(
                    'assets/icons/event/co_host.png',
                    color: Colors.white,
                    height: 22,
                    width: 22,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
    return onTap == null
        ? child
        : GestureDetector(
      onTap: () {
        HapticService.tap();
        onTap!();
      },
      child: child,
    );
  }
}

class _CardPillButton extends StatelessWidget {
  const _CardPillButton({
    required this.label,
    this.onTap,
    this.maxGuests, this.goingGuests,
  });
  final String label;
  final VoidCallback? onTap;
  final int? maxGuests;
  final int? goingGuests;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if(goingGuests!<maxGuests! || maxGuests==0) {
          HapticService.tap();
          onTap?.call();
        }
        else {null;}
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: kBlurValue, sigmaY: kBlurValue),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              color: goingGuests!<maxGuests! || maxGuests==0
                  ? Color.fromARGB(51, 255, 255, 255)
                  : Color.fromARGB(13, 255, 255, 255),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: goingGuests!<maxGuests! || maxGuests==0
                    ? Color.fromARGB(128, 255, 255, 255)
                    : Color.fromARGB(26, 255, 255, 255),
                width: 2,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: goingGuests!<maxGuests! || maxGuests==0
                    ? Color.fromARGB(255, 255, 255, 255)
                    : Color.fromARGB(51, 255, 255, 255),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
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
      borderRadius: BorderRadius.circular(35 * s),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: kBlurValue, sigmaY: kBlurValue),
        child: Container(
          constraints: BoxConstraints(minWidth: 250 * s, maxWidth: 300 * s),
          padding: EdgeInsets.symmetric(horizontal: 5 * s, vertical: 6 * s),
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
              _stateItem('going', counts.going),
              _stateItem('not_going', counts.notGoing),
              _stateItem('maybe', counts.maybe),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stateItem(String state, int val) {
    final String path = 'assets/icons/event/participation_state/$state.png';
    return Expanded(
      child: Column(
        children: [
          Image.asset(path, width: 22 * s, height: 22 * s),
          SizedBox(height: 6 * s),
          Text(
            '$val',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20 * s,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePhotoCircle extends StatelessWidget {
  const _ProfilePhotoCircle({required this.photo, required this.size});
  final String photo;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color.fromARGB(204, 255, 195, 0),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: photo.isEmpty
            ? Icon(Icons.person, color: Colors.white70, size: size * 0.52)
            : Image(
          image: photo.startsWith('http')
              ? NetworkImage(photo)
              : AssetImage(photo) as ImageProvider,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _SafeAssetIcon extends StatelessWidget {
  const _SafeAssetIcon({
    required this.iconPath,
    required this.size,
    this.fallbackIcon,
  });
  final String iconPath;
  final double size;
  final IconData? fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      iconPath,
      width: size,
      height: size,
      errorBuilder: (_, _, _) => Icon(
        fallbackIcon ?? Icons.info_outline,
        color: Colors.white,
        size: size,
      ),
    );
  }
}

class _CardTopBar extends StatelessWidget {
  const _CardTopBar({
    required this.event,
    required this.s,
    this.onGuestListTap,
    this.onEditTap,
  });
  final HomeEventCardData event;
  final double s;
  final VoidCallback? onGuestListTap;
  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // left: category e type
        Row(
          children: [
            _CardIconCircle(
              iconPath: event.categoryIconPath,
              isBlueAccent: true,
              size: 44 * s,
              iconSize: 28 * s,
            ),
            SizedBox(width: 12 * s),
            _CardIconCircle(
              iconPath: event.typeIconPath,
              size: 44 * s,
              iconSize: 28 * s,
            ),
          ],
        ),
        // right: guests + (edit btn or host profile photo)
        Row(
          children: [
            _CardIconCircle(
              iconPath: 'assets/icons/event/guests.png',
              showCohostBadge: event.isCurrentUserCohost,
              onTap: onGuestListTap,
              size: 44 * s,
              iconSize: 28 * s,
            ),
            SizedBox(width: 12 * s),
            // showing the edit button 'cause the event is 'By You'
            if (event.isByYou)
              _CardIconCircle(
                iconPath: 'assets/icons/event/edit.png',
                onTap: onEditTap,
                size: 44 * s,
                iconSize: 28 * s,
              )
            else // showing the profile photo of the host
              _ProfilePhotoCircle(
                photo: event.creatorProfilePhoto,
                size: 44 * s,
              ),
          ],
        ),
      ],
    );
  }
}

class _CardIconLabelButton extends StatelessWidget {
  const _CardIconLabelButton({
    required this.label,
    required this.icon,
    required this.s,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final double s;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.tap();
        onTap?.call();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18 * s),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: kBlurValue, sigmaY: kBlurValue),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 5 * s),
            decoration: BoxDecoration(
              color: const Color.fromARGB(45, 0, 0, 0),
              borderRadius: BorderRadius.circular(18 * s),
              border: Border.all(
                color: const Color.fromARGB(105, 255, 255, 255),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 15 * s),
                SizedBox(width: 5 * s),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13 * s,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}