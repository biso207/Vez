import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class HapticService {
  static const MethodChannel _channel = MethodChannel('com.outly.vez/haptics');

  static void tap() => unawaited(_play(_HapticType.tap));

  static void selection() => unawaited(_play(_HapticType.selection));

  static void emphasis() => unawaited(_play(_HapticType.emphasis));

  static void success() => unawaited(_play(_HapticType.success));

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

enum _HapticType {
  selection,
  tap,
  emphasis,
  success,
}
