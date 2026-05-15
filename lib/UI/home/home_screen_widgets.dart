// contains reusable widgets used by the home screen.

import 'package:flutter/material.dart';

import 'home_event.dart';
import '../../services/translation_service.dart';
import '../../views/widgets/vez_event_card.dart';
import '../../views/widgets/vez_glass.dart';

// displays the nearby search radius control.
class NearbyRangeControl extends StatelessWidget {
  const NearbyRangeControl({
    super.key,
    required this.s,
    required this.radiusKm,
    required this.isLoading,
    required this.error,
    required this.onRadiusChanged,
    required this.onRefreshPosition,
  });

  final double s;
  final double radiusKm;
  final bool isLoading;
  final String error;
  final ValueChanged<double> onRadiusChanged;
  final VoidCallback onRefreshPosition;

  @override
  Widget build(BuildContext context) {
    final roundedRadius = radiusKm.round();
    final bool hasError = error.isNotEmpty;

    return Center(
      child: VezGlass.container(
        padding: EdgeInsets.symmetric(horizontal: 8 * s),
        radius: BorderRadius.circular(22 * s),
        child: SizedBox(
          width: 280 * s,
          height: 30 * s,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 44 * s,
                child: Text(
                  hasError ? '!' : '${roundedRadius}Km',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hasError ? const Color(0xFFFF3131) : Colors.white,
                    fontSize: 12 * s,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white38,
                    thumbColor: Colors.white,
                    overlayColor: const Color.fromARGB(45, 255, 255, 255),
                    trackHeight: 2 * s,
                    thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: 5.5 * s,
                      disabledThumbRadius: 5.5 * s,
                    ),
                    overlayShape: RoundSliderOverlayShape(
                      overlayRadius: 12 * s,
                    ),
                    trackShape: const RoundedRectSliderTrackShape(),
                  ),
                  child: Slider(
                    min: 1,
                    max: 100,
                    divisions: 99,
                    value: radiusKm.clamp(1, 100),
                    onChanged: isLoading ? null : onRadiusChanged,
                  ),
                ),
              ),
              Tooltip(
                message: hasError ? error : StringRes.at('filter_nearby'),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: isLoading ? null : onRefreshPosition,
                  child: SizedBox(
                    width: 28 * s,
                    height: 26 * s,
                    child: Center(
                      child: isLoading
                          ? SizedBox(
                              width: 14 * s,
                              height: 14 * s,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Image.asset(
                              "assets/icons/event/my_location.png",
                              color: hasError
                                  ? const Color(0xFFFF3131)
                                  : Colors.white,
                              width: 20 * s,
                              height: 20 * s,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//
//   used for: displaying a vertical list of event cards.
//   design: vertical pageview that supports highlighting specific events.

class HomeEventCarousel extends StatefulWidget {
  const HomeEventCarousel({
    super.key,
    required this.events,
    required this.s,
    required this.isLoading,
    required this.emptyStateTitle,
    required this.emptyStateIconPath,
    required this.highlightedEventId,
    required this.onAddGuestsTap,
    required this.onGuestListTap,
    required this.onManageCohostsTap,
    required this.onEditTap,
    required this.onResponseSelected,
    required this.onUserProfileTap,
  });

  final List<HomeEventCardData> events;
  final double s;
  final bool isLoading;
  final String? emptyStateTitle;
  final String emptyStateIconPath;
  final String? highlightedEventId;
  final ValueChanged<HomeEventCardData> onAddGuestsTap;
  final ValueChanged<HomeEventCardData> onGuestListTap;
  final ValueChanged<HomeEventCardData> onManageCohostsTap;
  final ValueChanged<HomeEventCardData> onEditTap;
  final ValueChanged<String> onUserProfileTap;
  final void Function(HomeEventCardData event, String responseState)
  onResponseSelected;

  @override
  State<HomeEventCarousel> createState() => HomeEventCarouselState();
}

//
//   used for: managing carousel scroll position and event highlighting logic.
class HomeEventCarouselState extends State<HomeEventCarousel> {
  late final PageController _controller;
  String? _lastJumpedEventId;

  //
  //   used for: initializing the page controller and handling post-frame jumps.
  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.79);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeJumpToEvent());
  }

  //
  //   used for: checking if the highlighted event has changed to perform a jump.
  @override
  void didUpdateWidget(covariant HomeEventCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events != widget.events ||
        oldWidget.highlightedEventId != widget.highlightedEventId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeJumpToEvent());
    }
  }

  //
  //   used for: automatically scrolling to a specific event id if requested.
  void _maybeJumpToEvent() {
    if (!mounted || !_controller.hasClients) return;

    final String? eventId = widget.highlightedEventId?.trim();
    if (eventId == null || eventId.isEmpty || eventId == _lastJumpedEventId) {
      return;
    }

    final int targetIndex = widget.events.indexWhere(
      (event) => event.eventId == eventId,
    );
    if (targetIndex < 0) return;

    _controller.jumpToPage(targetIndex);
    _lastJumpedEventId = eventId;
  }

  //
  //   used for: disposing the page controller.
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (widget.events.isEmpty) {
      return EmptyEventsState(
        s: widget.s,
        title: widget.emptyStateTitle,
        iconPath: widget.emptyStateIconPath,
      );
    }

    return PageView.builder(
      scrollDirection: Axis.vertical,
      controller: _controller,
      itemCount: widget.events.length,
      itemBuilder: (context, index) {
        final HomeEventCardData event = widget.events[index];
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 6 * widget.s),
          child: VezEventCard(
            event: event,
            onAddGuestsTap: event.canInviteGuests
                ? () => widget.onAddGuestsTap(event)
                : null,
            onGuestListTap: () => widget.onGuestListTap(event),
            onManageCohostsTap: event.canManageCohosts
                ? () => widget.onManageCohostsTap(event)
                : null,
            onEditTap: event.canEditEvent
                ? () => widget.onEditTap(event)
                : null,
            onUserProfileTap: widget.onUserProfileTap,
            onResponseSelected: !event.isByYou
                ? (responseState) =>
                      widget.onResponseSelected(event, responseState)
                : null,
          ),
        );
      },
    );
  }
}

//
//   used for: displaying a placeholder when no events match the current filter.
//   design: centered icon and text within the event carousel area.
class EmptyEventsState extends StatelessWidget {
  const EmptyEventsState({
    super.key,
    required this.s,
    required this.title,
    required this.iconPath,
  });

  final double s;
  final String? title;
  final String iconPath;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28 * s),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              iconPath,
              width: 90 * s,
              height: 90 * s,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 18 * s),
            Text(
              title ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20 * s,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//
//   used for: main navigation controls at the bottom of the home screen.
//   design: glassy capsule containing home, create, and notification actions.
class HomeBottomNavPill extends StatelessWidget {
  const HomeBottomNavPill({
    super.key,
    required this.s,
    required this.activeIndex,
    required this.onHomeTap,
    required this.onCreateEventTap,
    required this.onNotificationsTap,
  });

  final double s;
  final int activeIndex;
  final VoidCallback onHomeTap;
  final VoidCallback onCreateEventTap;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return VezGlass.container(
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 0),
      radius: BorderRadius.circular(40),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: ImageIcon(
              const AssetImage('assets/icons/nav_bar/go_to_home_page.png'),
              color: activeIndex == 0 ? Colors.white : Colors.white54,
            ),
            iconSize: 30,
            onPressed: onHomeTap,
          ),
          SizedBox(width: 16 * s),
          IconButton(
            icon: ImageIcon(
              const AssetImage('assets/icons/nav_bar/create_event.png'),
              color: activeIndex == 1 ? Colors.white : Colors.white54,
            ),
            iconSize: 30,
            onPressed: onCreateEventTap,
          ),
          SizedBox(width: 16 * s),
          IconButton(
            icon: ImageIcon(
              const AssetImage('assets/icons/nav_bar/notifications.png'),
              color: activeIndex == 2 ? Colors.white : Colors.white54,
            ),
            iconSize: 30,
            onPressed: onNotificationsTap,
          ),
        ],
      ),
    );
  }
}

//
//   used for: the top section of popup windows.
//   design: contains title, close button, and an optional custom action icon.
class PopupHeaderBar extends StatelessWidget {
  const PopupHeaderBar({super.key, required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color.fromARGB(51, 0, 0, 0),
                border: Border.all(
                  color: const Color.fromARGB(128, 255, 255, 255),
                  width: 2,
                ),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 25),
            ),
          ),
        ],
      ),
    );
  }
}

//
//   used for: searching through lists within a popup.
//   design: glassy text field with search icon and custom hints.
class PopupSearchField extends StatelessWidget {
  const PopupSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return VezGlass.textField(
      controller: controller,
      hint: hint,
      height: 40,
      fontSize: 17,
      prefixIcon: const Icon(Icons.search, color: Colors.white),
      color: Colors.white,
      onChanged: onChanged,
    );
  }
}

//
//   used for: selecting categories or states within a popup.
//   design: styled chip with border, translucent background, and icon reference.
class PopupFilterChip extends StatelessWidget {
  const PopupFilterChip({
    super.key,
    this.iconPath,
    this.fallbackIcon,
    required this.isActive,
    required this.onTap,
  });

  final String? iconPath;
  final IconData? fallbackIcon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color.fromARGB(179, 0, 0, 0),
          border: Border.all(
            color: isActive ? Colors.white70 : Colors.white30,
            width: 2,
          ),
        ),
        child: iconPath != null
            ? Image.asset(iconPath!, width: 20, height: 20)
            : Icon(fallbackIcon, color: Colors.white, size: 20),
      ),
    );
  }
}

//
//   used for: displaying a single guest in the guest list popup.
//   design: row with avatar, name, optional action, and status icon.
class PopupGuestRow extends StatelessWidget {
  const PopupGuestRow({
    super.key,
    required this.username,
    required this.profilePhoto,
    required this.state,
    this.userId,
    this.onAvatarTap,
    this.guest,
    this.roleLabel,
    this.trailing,
  });

  final String username;
  final String profilePhoto;
  final String state;
  final String? userId;
  final ValueChanged<String>? onAvatarTap;
  final HomeEventGuestData? guest;
  final String? roleLabel;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color.fromARGB(51, 0, 0, 0),
        border: Border.all(
          color: const Color.fromARGB(128, 255, 255, 255),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          PopupUserAvatar(
            photo: profilePhoto,
            userId: userId,
            onTap: onAvatarTap,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    username.isNotEmpty ? username : 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (roleLabel == null)
            PopupStateIcon(state: state), // no state for the host
          if (roleLabel != null) RoleBadge(label: roleLabel!, guest: guest),

          if (trailing != null) ...[
            // remove guest buttons
            const SizedBox(width: 13), // space from the state icon
            trailing!,
          ],
        ],
      ),
    );
  }
}

//
//   used for: displaying users that can be interacted with (e.g., invited).
//   design: row with avatar, name, relationship label, and action icon.
class PopupSectionLabel extends StatelessWidget {
  const PopupSectionLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class PopupMiniActionButton extends StatelessWidget {
  const PopupMiniActionButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withAlpha(90),
          border: Border.all(color: color.withAlpha(210), width: 1.5),
        ),
        child: Icon(icon, color: Colors.white, size: 17),
      ),
    );
  }
}

// displays a cohost with its demotion action.
class CohostPermissionRow extends StatelessWidget {
  const CohostPermissionRow({
    super.key,
    required this.guest,
    required this.isBusy,
    this.onAvatarTap,
    required this.onDemote,
  });

  final HomeEventGuestData guest;
  final bool isBusy;
  final ValueChanged<String>? onAvatarTap;
  final VoidCallback onDemote;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color.fromARGB(51, 0, 0, 0),
        border: Border.all(
          color: const Color.fromARGB(128, 255, 255, 255),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              PopupUserAvatar(
                photo: guest.profilePhoto,
                userId: guest.userId,
                onTap: onAvatarTap,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  guest.username.isNotEmpty ? guest.username : 'User',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMiniActionButton(
                icon: Icons.person_remove_alt_1_rounded,
                color: const Color(0xFFFF3131),
                onTap: isBusy ? null : onDemote,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// displays a compact boolean permission toggle.
class PermissionToggle extends StatelessWidget {
  const PermissionToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 34,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: value
                  ? const Color.fromARGB(130, 8, 157, 13)
                  : const Color.fromARGB(90, 255, 49, 49),
              border: Border.all(color: Colors.white30, width: 1.5),
            ),
            child: Icon(
              value ? Icons.check_rounded : Icons.close_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class PopupUserSelectionRow extends StatelessWidget {
  const PopupUserSelectionRow({
    super.key,
    required this.username,
    required this.profilePhoto,
    required this.userId,
    this.onAvatarTap,
    required this.relationIconPath,
    required this.onAdd,
  });

  final String username;
  final String profilePhoto;
  final String userId;
  final ValueChanged<String>? onAvatarTap;
  final String relationIconPath;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color.fromARGB(51, 0, 0, 0),
        border: Border.all(
          color: const Color.fromARGB(128, 255, 255, 255),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          PopupUserAvatar(
            photo: profilePhoto,
            userId: userId,
            onTap: onAvatarTap,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              username.isNotEmpty ? username : 'User',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // displays the relationship icon.
          Image.asset(
            relationIconPath,
            width: 24,
            height: 24,
            color: Colors.white,
          ),
          const SizedBox(width: 13),
          // displays the add user action.
          GestureDetector(
            onTap: onAdd,
            child: const Icon(
              Icons.person_add_alt_1_rounded, // todo: change (?)
              color: Color(0xFF089D0D),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

//
//   used for: displaying a circular user profile picture within popups.
//   design: handles both network and asset images with a placeholder icon.
class PopupUserAvatar extends StatelessWidget {
  const PopupUserAvatar({
    super.key,
    required this.photo,
    this.userId,
    this.onTap,
  });

  final String photo;
  final String? userId;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isNetworkImage = photo.startsWith('http');

    final String safeUserId = userId?.trim() ?? '';
    final child = Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white30, width: 2),
      ),
      child: ClipOval(
        child: photo.isEmpty
            ? Image.asset(
                'assets/icons/home_page/profile_photo.png', // TODO: modify the path here
                fit: BoxFit.cover,
              )
            : Image(
                image: isNetworkImage
                    ? NetworkImage(photo)
                    : AssetImage(photo) as ImageProvider,
                fit: BoxFit.cover,
              ),
      ),
    );
    if (safeUserId.isEmpty || onTap == null) return child;
    return GestureDetector(onTap: () => onTap!(safeUserId), child: child);
  }
}

//
//   used for: visual representation of a guest's participation status.
//   design: displays different icons for going, not going, or maybe.
class PopupStateIcon extends StatelessWidget {
  const PopupStateIcon({super.key, required this.state});

  final String state;

  @override
  Widget build(BuildContext context) {
    final String iconPath = switch (state) {
      'going' => 'assets/icons/event/participation_state/going.png',
      'not_going' => 'assets/icons/event/participation_state/not_going.png',
      _ => 'assets/icons/event/participation_state/maybe.png',
    };

    return Image.asset(iconPath, width: 22, height: 22);
  }
}

//
//   used for: summarizing rsvp totals at the bottom of the guest list popup.
//   design: horizontal bar showing counts for going, not going, and maybe.
class PopupCountsFooter extends StatelessWidget {
  const PopupCountsFooter({super.key, required this.counts});

  final HomeEventGuestCounts counts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: const Color.fromARGB(51, 0, 0, 0),
        border: Border.all(
          color: const Color.fromARGB(128, 255, 255, 255),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: PopupCountItem(
              iconPath: 'assets/icons/event/participation_state/going.png',
              label: StringRes.at('going'),
              value: counts.going,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: PopupCountItem(
              iconPath: 'assets/icons/event/participation_state/not_going.png',
              label: StringRes.at('not_going'),
              value: counts.notGoing,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: PopupCountItem(
              iconPath: 'assets/icons/event/participation_state/maybe.png',
              label: StringRes.at('maybe'),
              value: counts.maybe,
            ),
          ),
        ],
      ),
    );
  }
}

//
//   used for: a single statistic entry within the counts footer.
//   design: vertical stack of icon, label, and numeric value.
class PopupCountItem extends StatelessWidget {
  const PopupCountItem({
    super.key,
    required this.iconPath,
    required this.label,
    required this.value,
  });

  final String iconPath;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(iconPath, width: 22, height: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

//
//   used for: displaying a message when a popup list has no items.
//   design: glassy container with centered descriptive text.
class PopupEmptyState extends StatelessWidget {
  const PopupEmptyState({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color.fromARGB(51, 0, 0, 0),
        border: Border.all(
          color: const Color.fromARGB(128, 255, 255, 255),
          width: 2,
        ),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 30,
        ),
      ),
    );
  }
}

//
//   used for: highlighting a user's role (e.g., "host").
//   design: small, colored capsule with bold text.
class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.label, this.guest});

  final String label;
  final HomeEventGuestData? guest;

  @override
  Widget build(BuildContext context) {
    // host rows don't have a guest object; co-host rows do, so the badge color
    // can be derived without passing a second role flag around.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Text(
        label,
        style: TextStyle(
          color: const Color.fromARGB(255, 255, 195, 0),
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
