// developed and designed by outly • © 2026
// unified popup system for all event-detail interactions.
//
// every popup in this file shares the same design language:
//   • VezPopup glass shell (blur + border)
//   • optional title row with icon
//   • content rows use _VezPopupRow (icon + label, same as category/type popups)
//   • dividers use _VezPopupDivider
//   • text inputs use _VezPopupInput (glass pill, same as profile edit)
//   • action buttons use _VezPopupActionCircle (green save / red discard)
//
// usage:
//   VezEventPopups.showTextInput(context, ...)
//   VezEventPopups.showLocationSelector(context, ...)
//   VezEventPopups.showConfirmation(context, ...)

import 'dart:ui';
import 'package:flutter/material.dart';

import '../../services/haptic_service.dart';
import '../../services/translation_service.dart';
import 'vez_popup.dart';

// ─────────────────────────────────────────────────────────────────────────────
// VezEventPopups — static entry points
// ─────────────────────────────────────────────────────────────────────────────

class VezEventPopups {
  VezEventPopups._(); // prevent instantiation

  // ── text input popup ───────────────────────────────────────────────────────
  //
  // used for: description, max guests, price, location name.
  // design: glass pill input field + green save / red discard circle buttons.

  static void showTextInput(
    BuildContext context, {
    required String title,
    String? titleIcon, // optional asset icon shown beside the title
    String? currentValue,
    required ValueChanged<String> onSave,
    bool isNumeric = false,
    bool isMultiline = false,
    int? maxLength,
  }) {
    final double pw = MediaQuery.of(context).size.width * 0.80;
    final TextEditingController ctrl = TextEditingController(
      text: currentValue,
    );

    VezPopup.show(
      context: context,
      width: pw,
      child: _TextInputContent(
        title: title,
        titleIcon: titleIcon,
        controller: ctrl,
        isNumeric: isNumeric,
        isMultiline: isMultiline,
        maxLength: maxLength,
        onSave: (value) {
          FocusScope.of(context).unfocus();
          onSave(value);
          Navigator.pop(context);
        },
        onDiscard: () {
          FocusScope.of(context).unfocus();
          Navigator.pop(context);
        },
      ),
    );
  }

  // ── location selector popup ────────────────────────────────────────────────
  //
  // used for: choosing between "simple name" and "map picker".
  // design: title + two icon-label rows separated by a divider (same as type popup).

  static void showLocationSelector(
    BuildContext context, {
    required VoidCallback onSimpleNameTap,
    required VoidCallback onMapTap,
  }) {
    final double pw = MediaQuery.of(context).size.width * 0.78;

    VezPopup.show(
      context: context,
      width: pw,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // header
          _VezPopupHeader(
            icon: 'assets/icons/event/location.png',
            label: StringRes.at('set_location'),
          ),

          _VezPopupDivider(parentWidth: pw),

          // option 1: simple text name
          _VezPopupRow(
            iconPath: 'assets/icons/event/known_place.png',
            label: StringRes.at('location_simple_name'),
            onTap: () {
              Navigator.pop(context);
              onSimpleNameTap();
            },
          ),

          _VezPopupDivider(parentWidth: pw),

          // option 2: precise map picker
          _VezPopupRow(
            iconPath: 'assets/icons/event/precise_spot.png',
            label: StringRes.at('location_map'),
            onTap: () {
              Navigator.pop(context);
              onMapTap();
            },
          ),
        ],
      ),
    );
  }

  // ── confirmation popup ─────────────────────────────────────────────────────
  //
  // used for: save event, delete/reset event data.
  // design: title + two icon-label rows (confirm / cancel) with a divider.

  static void showConfirmation(
    BuildContext context, {
    required String title,
    String? titleIcon,
    required VoidCallback onConfirm,
    String confirmLabel = 'OK',
    String cancelLabel = 'Cancel',
  }) {
    final double pw = MediaQuery.of(context).size.width * 0.60;

    VezPopup.show(
      context: context,
      width: pw,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // header
          _VezPopupHeader(icon: titleIcon, label: title),

          _VezPopupDivider(parentWidth: pw),

          // confirm row (green accent)
          _VezPopupRow(
            iconPath: 'assets/icons/event/confirm.png',
            label: confirmLabel,
            accentColor: const Color(0xFF089D0D),
            onTap: () {
              HapticService.success();
              Navigator.pop(context);
              onConfirm();
            },
          ),

          _VezPopupDivider(parentWidth: pw),

          // cancel row (red accent)
          _VezPopupRow(
            iconPath: 'assets/icons/event/cancel.png',
            label: cancelLabel,
            accentColor: const Color(0xFFFF3131),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TextInputContent — body of the text-input popup
// ─────────────────────────────────────────────────────────────────────────────

class _TextInputContent extends StatefulWidget {
  final String title;
  final String? titleIcon;
  final TextEditingController controller;
  final bool isNumeric, isMultiline;
  final int? maxLength;
  final ValueChanged<String> onSave;
  final VoidCallback onDiscard;

  const _TextInputContent({
    required this.title,
    required this.titleIcon,
    required this.controller,
    required this.isNumeric,
    required this.isMultiline,
    required this.maxLength,
    required this.onSave,
    required this.onDiscard,
  });

  @override
  State<_TextInputContent> createState() => _TextInputContentState();
}

class _TextInputContentState extends State<_TextInputContent> {
  @override
  Widget build(BuildContext context) {
    final double pw = MediaQuery.of(context).size.width * 0.80;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // header with icon and title
        _VezPopupHeader(icon: widget.titleIcon, label: widget.title),

        _VezPopupDivider(parentWidth: pw),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            children: [
              // glass-style input field (same as profile edit inputs)
              _VezPopupInput(
                controller: widget.controller,
                isNumeric: widget.isNumeric,
                isMultiline: widget.isMultiline,
                maxLength: widget.maxLength,
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 18),

              // save / discard circle buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _VezPopupActionCircle(
                    iconPath: 'assets/icons/event/check.png',
                    color: const Color.fromARGB(128, 8, 157, 13),
                    borderColor: const Color.fromARGB(200, 8, 157, 13),
                    onTap: () => widget.onSave(widget.controller.text),
                  ),
                  const SizedBox(width: 28),
                  _VezPopupActionCircle(
                    iconPath: 'assets/icons/event/close.png',
                    color: const Color.fromARGB(128, 255, 49, 49),
                    borderColor: const Color.fromARGB(200, 255, 49, 49),
                    onTap: widget.onDiscard,
                  ),
                ],
              ),

              const SizedBox(height: 4),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// shared sub-widgets — used by every popup in this file
// ─────────────────────────────────────────────────────────────────────────────

// ── _VezPopupHeader — title row with optional asset icon ─────────────────────

class _VezPopupHeader extends StatelessWidget {
  final String? icon; // asset path or null
  final String label;

  const _VezPopupHeader({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        mainAxisAlignment: icon != null
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            ImageIcon(AssetImage(icon!), color: Colors.white, size: 28),
            const SizedBox(width: 12),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

// ── _VezPopupRow — icon + label tappable row (matches category/type popup rows)

class _VezPopupRow extends StatelessWidget {
  final String iconPath;
  final String label;
  final Color? accentColor; // optional tint for icon and label
  final VoidCallback onTap;

  const _VezPopupRow({
    required this.iconPath,
    required this.label,
    required this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color c = accentColor ?? Colors.white;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            ImageIcon(AssetImage(iconPath), color: c, size: 28),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: c,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _VezPopupDivider — thin horizontal rule between rows ─────────────────────

class _VezPopupDivider extends StatelessWidget {
  final double parentWidth;

  const _VezPopupDivider({required this.parentWidth});

  @override
  Widget build(BuildContext context) {
    final double w = (parentWidth * 0.70).clamp(100.0, parentWidth - 32.0);
    return Center(
      child: Container(
        width: w,
        height: 2,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

// ── _VezPopupInput — glass pill text field (matches profile edit fields) ──────

class _VezPopupInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isNumeric, isMultiline;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  const _VezPopupInput({
    required this.controller,
    required this.isNumeric,
    required this.isMultiline,
    this.maxLength,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMultiline ? 20 : 30),
        border: Border.all(color: Colors.white38, width: 2),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        maxLength: maxLength,
        maxLines: isMultiline ? 4 : 1,
        keyboardType: isNumeric
            ? TextInputType.number
            : (isMultiline ? TextInputType.multiline : TextInputType.text),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          counterText: '',
          // live character counter shown when maxLength is set
          suffixText: maxLength != null
              ? '${controller.text.length}/$maxLength'
              : null,
          suffixStyle: const TextStyle(color: Colors.white38, fontSize: 13),
          hintStyle: const TextStyle(color: Colors.white38),
        ),
      ),
    );
  }
}

// ── _VezPopupActionCircle — circle icon button (green save / red discard) ─────

class _VezPopupActionCircle extends StatelessWidget {
  final String iconPath;
  final Color color;
  final Color borderColor;
  final VoidCallback onTap;

  const _VezPopupActionCircle({
    required this.iconPath,
    required this.color,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.tap();
        onTap();
      },
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 2),
            ),
            child: ImageIcon(
              AssetImage(iconPath),
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
