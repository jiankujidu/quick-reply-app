import 'dart:io';
import 'package:flutter/services.dart';

/// 鎮诞绐楁湇鍔?- 鍩轰簬鍘熺敓 Android MethodChannel 瀹炵幇
class OverlayService {
  static const _channel = MethodChannel('app.quickreply/overlay');
  static bool _bubbleActive = false;
  static bool get isBubbleActive => _bubbleActive;

  /// 妫€鏌ユ偓娴獥鏉冮檺
  static Future<bool> checkPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('checkPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// 璇锋眰鎮诞绐楁潈闄愶紙璺宠浆鍒扮郴缁熻缃〉闈級
  static Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      await _channel.invokeMethod<bool>('requestPermission');
      return true;
    } on PlatformException {
      return false;
    }
  }

  /// 鍚姩鎮诞姘旀场锛堟樉绀鸿瘽鏈垪琛級
  /// [messages] 璇濇湳鍒楄〃锛屾瘡鏉″寘鍚?id, title, content, category, subcategory
  static Future<bool> startFloatingBubble(List<Map<String, dynamic>> messages) async {
    if (!Platform.isAndroid) return false;

    try {
      // 鍏堟鏌ユ潈闄?      final hasPermission = await checkPermission();
      if (!hasPermission) {
        await requestPermission();
        // 缁欑敤鎴锋椂闂存巿鏉?        await Future.delayed(const Duration(seconds: 1));
        final granted = await checkPermission();
        if (!granted) {
          print('鎮诞绐楁潈闄愭湭鎺堜簣');
          return false;
        }
      }

      final result = await _channel.invokeMethod<bool>('startBubble', {
        'messages': messages,
      });

      _bubbleActive = result ?? false;
      return _bubbleActive;
    } on PlatformException catch (e) {
      print('鍚姩鎮诞姘旀场澶辫触: ${e.message}');
      _bubbleActive = false;
      return false;
    }
  }

  /// 鍋滄鎮诞姘旀场
  static Future<void> stopFloatingBubble() async {
    try {
      await _channel.invokeMethod<bool>('stopBubble');
    } on PlatformException {
      // ignore
    }
    _bubbleActive = false;
  }

  /// 鏇存柊鎮诞姘旀场涓殑璇濇湳鍒楄〃
  static Future<void> updateMessages(List<Map<String, dynamic>> messages) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('updateMessages', {
        'messages': messages,
      });
    } on PlatformException catch (e) {
      print('鏇存柊璇濇湳鍒楄〃澶辫触: ${e.message}');
    }
  }

  // ============ 鍏煎鏃?API ============

  /// 鍏煎鏃?API: 妫€鏌ユ偓娴獥鏄惁婵€娲?  static bool get isOverlayActive => _bubbleActive;

  /// 鍏煎鏃?API: 鏄剧ず鍗曟潯娑堟伅鐨勬偓娴獥
  static Future<void> showOverlayWithMessage({
    required String title,
    required String content,
    List<String>? images,
    List<String>? files,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        await requestPermission();
        await Future.delayed(const Duration(seconds: 1));
        final granted = await checkPermission();
        if (!granted) return;
      }
      await _channel.invokeMethod<bool>('showOverlay', {
        'title': title,
        'content': content,
        'images': images ?? [],
        'files': files ?? [],
      });
      _bubbleActive = true;
    } on PlatformException catch (e) {
      print('鏄剧ず鎮诞绐楀け璐? ${e.message}');
    }
  }

  /// 鍏煎鏃?API: 鍏抽棴鎮诞绐?  static Future<void> closeOverlay() async {
    try {
      await _channel.invokeMethod<bool>('closeOverlay');
    } on PlatformException {
      // ignore
    }
    _bubbleActive = false;
  }
}