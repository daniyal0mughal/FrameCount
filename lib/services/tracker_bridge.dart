import 'package:flutter/services.dart';

class TrackerBridge {
  static const MethodChannel _channel = MethodChannel('com.framecount.tracker/bridge');

  static Future<bool> checkOverlayPermission() async {
    try {
      final bool result = await _channel.invokeMethod('checkOverlayPermission');
      return result;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (_) {}
  }

  static Future<bool> checkAccessibilityPermission() async {
    try {
      final bool result = await _channel.invokeMethod('checkAccessibilityPermission');
      return result;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestAccessibilityPermission() async {
    try {
      await _channel.invokeMethod('requestAccessibilityPermission');
    } catch (_) {}
  }

  static Future<Map<String, int>> getTodayStats() async {
    try {
      final Map<dynamic, dynamic>? res = await _channel.invokeMethod('getTodayStats');
      if (res != null) {
        return {
          'reels': (res['reels'] as num?)?.toInt() ?? 0,
          'tiktok': (res['tiktok'] as num?)?.toInt() ?? 0,
          'shorts': (res['shorts'] as num?)?.toInt() ?? 0,
          'total': (res['total'] as num?)?.toInt() ?? 0,
        };
      }
    } catch (_) {}
    return {'reels': 0, 'tiktok': 0, 'shorts': 0, 'total': 0};
  }

  static Future<bool> clearAllData() async {
    try {
      final bool? res = await _channel.invokeMethod('clearAllData');
      return res ?? true;
    } catch (_) {
      return false;
    }
  }
}
