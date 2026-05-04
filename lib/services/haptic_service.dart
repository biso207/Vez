// Developed and Designed by Outly • © 2026
// service for providing tactile haptic feedback across different platforms.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// ── haptic service ───────────────────────────────────────────────────────────
//
//   used for: triggering vibrations and tactile effects for UI interactions.
class HapticService {
  static const MethodChannel _channel = MethodChannel('com.outly.vez/haptics');

  // ── tap ────────────────────────────────────────────────────────────────────
  //
  //   used for: standard light touch feedback (buttons, switches).
  static void tap() => unawaited(_play(_HapticType.tap));

  // ── selection ──────────────────────────────────────────────────────────────
  //
  //   used for: feedback when changing a selection or focused item.
  static void selection() => unawaited(_play(_HapticType.selection));

  // ── emphasis ───────────────────────────────────────────────────────────────
  //
  //   used for: strong feedback to highlight important actions.
  static void emphasis() => unawaited(_play(_HapticType.emphasis));

  // ── success ────────────────────────────────────────────────────────────────
  //
  //   used for: confirming a completed action or positive result.
  static void success() => unawaited(_play(_HapticType.success));

  // ── play ───────────────────────────────────────────────────────────────────
  //
  //   used for: orchestrating the feedback play based on platform availability.
  static Future<void> _play(_HapticType type) async {
    if (kIsWeb) return;

    try {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          await _channel.invokeMethod<void>('play', {'type': type.name});
          return;
        case TargetPlatform.iOS:
          await _playIosFallback(type);
          return;
        default:
          await _playDefaultFallback(type);
          return;
      }
    } catch (_) {
      await _playDefaultFallback(type);
    }
  }

  // ── play ios fallback ──────────────────────────────────────────────────────
  //
  //   used for: mapping custom types to native iOS haptic feedback patterns.
  static Future<void> _playIosFallback(_HapticType type) {
    switch (type) {
      case _HapticType.selection:
        return HapticFeedback.selectionClick();
      case _HapticType.tap:
        return HapticFeedback.lightImpact();
      case _HapticType.emphasis:
        return HapticFeedback.mediumImpact();
      case _HapticType.success:
        return HapticFeedback.heavyImpact();
    }
  }

  // ── play default fallback ──────────────────────────────────────────────────
  //
  //   used for: providing a generic feedback pattern for unhandled platforms.
  static Future<void> _playDefaultFallback(_HapticType type) {
    switch (type) {
      case _HapticType.selection:
        return HapticFeedback.selectionClick();
      case _HapticType.tap:
        return HapticFeedback.lightImpact();
      case _HapticType.emphasis:
        return HapticFeedback.mediumImpact();
      case _HapticType.success:
        return HapticFeedback.heavyImpact();
    }
  }
}

// ── haptic type ──────────────────────────────────────────────────────────────
//
//   used for: defining standard feedback intensities and patterns.
enum _HapticType {
  selection,
  tap,
  emphasis,
  success,
}
