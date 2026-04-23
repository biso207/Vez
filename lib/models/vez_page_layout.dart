// developed and designed by outly • © 2026
// universal 4-zone page layout template used by every screen in the app.
//
// zone architecture (bottom → top in the stack):
//   zone 1 — background  : solid dark color (#0E0E0E), fills the whole scaffold
//   zone 2 — body        : the central content (carousel, event card, profile …)
//                          constrained horizontally by [horizontalMargin]
//   zone 3 — blur veil   : two progressive frosted-glass gradients (top & bottom)
//                          that softly mask zone-2 content as it scrolls in / out
//   zone 4 — navbars     : top search / filter bar  +  optional bottom nav pill
//
// usage: wrap every screen's Scaffold body with VezPageLayout and pass:
//   • [body]          → the central zone-2 widget
//   • [bottomNavBar]  → the pill-shaped bottom navigation row
//   • [searchController], [profileIconPath], [filterIconPath] … → top-bar props

import 'dart:ui';
import 'package:flutter/material.dart';

import '../models/vez_event_card.dart';
import '../models/vez_glass.dart';
import '../models/vez_popup.dart';
import '../services/haptic_service.dart';
import '../services/translation_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// constants shared across the whole layout
// ─────────────────────────────────────────────────────────────────────────────

/// base background color for every screen
const Color kBgColor = Color(0xFF0E0E0E);

/// height of the top progressive blur veil
const double kBlurVeilTop = 260.0;

/// height of the bottom progressive blur veil
const double kBlurVeilBottom = 180.0;

/// sigma used for both blur veils
const double kBlurSigma = 10.0;

// ─────────────────────────────────────────────────────────────────────────────
// VezPageLayout widget
// ─────────────────────────────────────────────────────────────────────────────

class VezPageLayout extends StatelessWidget {
  // ---------- zone-2 body ----------
  /// the main content widget placed in the centre of the screen
  final Widget body;

  // ---------- zone-4 bottom navbar ----------
  /// optional pill-shaped bottom navigation row
  final Widget? bottomNavBar;

  // ---------- top-bar configuration ----------
  /// controller bound to the search text field
  final TextEditingController searchController;

  /// asset path or network url for the left circular button
  final String profileIconPath;

  /// when true the left button renders as a photo avatar; otherwise as an icon
  final bool isProfileAvatar;

  /// callback fired when the user taps the left (profile) button
  final VoidCallback? onProfileTap;

  /// placeholder text inside the search field
  final String searchHint;

  /// asset path for the right filter/action circular button
  final String filterIconPath;

  /// callback fired when a filter option is chosen from the popup (passes index)
  final ValueChanged<int>? onFilterSelected;

  // ---------- layout ----------
  /// horizontal margin that constrains the body on wide screens.
  /// on small phones (<600 px wide) it is clamped to [kSmallScreenMargin].
  final double horizontalMargin;

  const VezPageLayout({
    super.key,
    required this.body,
    this.bottomNavBar,
    required this.searchController,
    this.profileIconPath = '',
    this.isProfileAvatar = false,
    this.onProfileTap,
    this.searchHint = 'Search',
    this.filterIconPath = '',
    this.onFilterSelected,
    this.horizontalMargin = 20.0,
  });

  // filter-popup entries — kept here so the popup can always render them
  static const List<Map<String, dynamic>> _filterIcons = [
    {'icon': 'assets/icons/home_page/by_you_events.png',  'type': EventType.byYou},
    {'icon': 'assets/icons/home_page/invited_events.png', 'type': EventType.invited},
    {'icon': 'assets/icons/home_page/nearby_events.png',  'type': EventType.nearby},
  ];

  // ─── build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    // responsive scale factor — 1.0 at 390 px wide, clamped [0.8 – 1.2]
    final double s = (sw / 390).clamp(0.8, 1.2);
    // collapse margins on small handsets
    final double margin = sw < 600 ? 20.0 : horizontalMargin;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: kBgColor,
      body: Stack(
        children: [
          // ── zone 1: background ─────────────────────────────────────────
          // handled by Scaffold.backgroundColor above; nothing extra needed.

          // ── zone 2: central body ───────────────────────────────────────
          Positioned.fill(
            left:  margin,
            right: margin,
            child: body,
          ),

          // ── zone 3a: top blur veil ─────────────────────────────────────
          // masks the content as it scrolls under the top navbar
          Positioned(
            top: 0, left: 0, right: 0,
            height: kBlurVeilTop,
            child: IgnorePointer(
              child: _ProgressiveBlur(
                fromAlignment: Alignment.topCenter,
                toAlignment:   Alignment.bottomCenter,
              ),
            ),
          ),

          // ── zone 3b: bottom blur veil ──────────────────────────────────
          // masks the content as it disappears below the bottom navbar
          Positioned(
            bottom: 0, left: 0, right: 0,
            height: kBlurVeilBottom,
            child: IgnorePointer(
              child: _ProgressiveBlur(
                fromAlignment: Alignment.bottomCenter,
                toAlignment:   Alignment.topCenter,
              ),
            ),
          ),

          // ── zone 4a: top navbar ────────────────────────────────────────
          Positioned(
            top:   MediaQuery.of(context).padding.top + 24 * s,
            left:  margin,
            right: margin,
            child: _TopNavBar(
              s:                s,
              profileIconPath:  profileIconPath,
              isProfileAvatar:  isProfileAvatar,
              onProfileTap:     onProfileTap,
              searchController: searchController,
              searchHint:       searchHint,
              filterIconPath:   filterIconPath,
              onFilterSelected: onFilterSelected,
              filterIcons:      _filterIcons,
            ),
          ),

          // ── zone 4b: bottom navbar ─────────────────────────────────────
          if (bottomNavBar != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24 * s,
              left: 0, right: 0,
              child: Center(child: bottomNavBar!),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ProgressiveBlur — reusable frosted-glass veil (zone 3)
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressiveBlur extends StatelessWidget {
  final Alignment fromAlignment;
  final Alignment toAlignment;

  const _ProgressiveBlur({
    required this.fromAlignment,
    required this.toAlignment,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => LinearGradient(
        begin: fromAlignment,
        end:   toAlignment,
        // opaque at the edge, fully transparent toward the middle
        colors: const [Colors.black, Colors.transparent],
        stops:  const [0.15, 1.0],
      ).createShader(rect),
      blendMode: BlendMode.dstIn,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: kBlurSigma, sigmaY: kBlurSigma),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: fromAlignment,
              end:   toAlignment,
              colors: [kBgColor.withOpacity(0.85), Colors.transparent],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TopNavBar — search field flanked by two circular glass buttons (zone 4a)
// ─────────────────────────────────────────────────────────────────────────────

class _TopNavBar extends StatelessWidget {
  final double s;
  final String profileIconPath;
  final bool isProfileAvatar;
  final VoidCallback? onProfileTap;
  final TextEditingController searchController;
  final String searchHint;
  final String filterIconPath;
  final ValueChanged<int>? onFilterSelected;
  final List<Map<String, dynamic>> filterIcons;

  const _TopNavBar({
    required this.s,
    required this.profileIconPath,
    required this.isProfileAvatar,
    required this.onProfileTap,
    required this.searchController,
    required this.searchHint,
    required this.filterIconPath,
    required this.onFilterSelected,
    required this.filterIcons,
  });

  @override
  Widget build(BuildContext context) {
    final bool isNetworkImage = profileIconPath.startsWith('http');
    final double popupWidth = MediaQuery.of(context).size.width * 0.50;

    return Row(
      children: [
        // ── left: profile / settings button ─────────────────────────────
        GestureDetector(
          onTap: onProfileTap ?? () {},
          child: _CircleButton(
            size: 45,
            border: Border.all(
              color: isProfileAvatar ? Colors.white : Colors.white54,
              width: 2,
            ),
            child: isProfileAvatar
                ? (profileIconPath.isEmpty
                    ? const Icon(Icons.person, color: Colors.white)
                    : Image(
                        image: isNetworkImage
                            ? NetworkImage(profileIconPath)
                            : AssetImage(profileIconPath) as ImageProvider,
                        fit: BoxFit.cover,
                        width: 45, height: 45,
                      ))
                : Center(
                    child: Image.asset(
                      profileIconPath,
                      width: 28, height: 28,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),

        SizedBox(width: 12 * s),

        // ── centre: search field ─────────────────────────────────────────
        Expanded(
          child: VezGlass.textField(
            controller: searchController,
            hint: searchHint,
            prefixIcon: const Icon(Icons.search, color: Colors.white),
            color: Colors.white,
          ),
        ),

        SizedBox(width: 12 * s),

        // ── right: filter button ─────────────────────────────────────────
        VezGlass.circleButton(
          assetIcon: filterIconPath,
          size: 45,
          iconSize: 28,
          onTap: () {
            HapticService.tap();
            _showFilterPopup(context, popupWidth);
          },
        ),
      ],
    );
  }

  // filter popup — lists the three event-group options
  void _showFilterPopup(BuildContext context, double width) {
    // localized filter labels
    final labels = [
      StringRes.at('filter_by_you'),
      StringRes.at('filter_invited'),
      StringRes.at('filter_nearby'),
    ];

    VezPopup.show(
      context: context,
      width: width,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(filterIcons.length, (i) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // filter row item
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  onFilterSelected?.call(i);
                  Navigator.pop(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  child: Row(
                    children: [
                      Image.asset(filterIcons[i]['icon'] as String, width: 38, height: 38),
                      const SizedBox(width: 14),
                      Text(
                        labels[i],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // divider between items (skip after last)
              if (i < filterIcons.length - 1)
                _PopupDivider(parentWidth: width),
            ],
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CircleButton — generic clipped circular container
// ─────────────────────────────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final double size;
  final BoxBorder? border;
  final Widget child;

  const _CircleButton({required this.size, this.border, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: border,
      ),
      child: ClipOval(child: child),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PopupDivider — thin horizontal rule used inside popups
// ─────────────────────────────────────────────────────────────────────────────

class _PopupDivider extends StatelessWidget {
  final double parentWidth;

  const _PopupDivider({required this.parentWidth});

  @override
  Widget build(BuildContext context) {
    // divider width is ~70 % of the popup, clamped to a sensible range
    final double w = (parentWidth * 0.7).clamp(120.0, parentWidth - 32.0);
    return Center(
      child: Container(
        width: w, height: 2,
        decoration: BoxDecoration(
          color: Colors.white38,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
