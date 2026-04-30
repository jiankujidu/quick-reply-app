import 'dart:io';
import 'package:flutter/services.dart';

/// 悬浮窗服务 - 基于原生 Android MethodChannel 实现
class OverlayService {
  static const _channel = MethodChannel('app.quickreply/overlay');
  static bool _bubbleActive = false;
  static bool get isBubbleActive => _bubbleActive;

  /// 检查悬浮窗权限
  static Future<bool> checkPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('checkPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// 请求悬浮窗权限（跳转到系统设置页面）
  static Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      await _channel.invokeMethod<bool>('requestPermission');
      return true;
    } on PlatformException {
      return false;
    }
  }

  /// 启动悬浮气泡（显示话术列表）
  /// [messages] 话术列表，每条包含 id, title, content, category, subcategory
  static Future<bool> startFloatingBubble(List<Map<String, dynamic>> messages) async {
    if (!Platform.isAndroid) return false;

    try {
      // 先检查权限
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        await requestPermission();
        // 给用户时间授权
        await Future.delayed(const Duration(seconds: 1));
        final granted = await checkPermission();
        if (!granted) {
          print('悬浮窗权限未授予');
          return false;
        }
      }

      final result = await _channel.invokeMethod<bool>('startBubble', {
        'messages': messages,
      });

      _bubbleActive = result ?? false;
      return _bubbleActive;
    } on PlatformException catch (e) {
      print('启动悬浮气泡失败: ${e.message}');
      _bubbleActive = false;
      return false;
    }
  }

  /// 停止悬浮气泡
  static Future<void> stopFloatingBubble() async {
    try {
      await _channel.invokeMethod<bool>('stopBubble');
    } on PlatformException {
      // ignore
    }
    _bubbleActive = false;
  }

  /// 更新悬浮气泡中的话术列表
  static Future<void> updateMessages(List<Map<String, dynamic>> messages) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('updateMessages', {
        'messages': messages,
      });
    } on PlatformException catch (e) {
      print('更新话术列表失败: ${e.message}');
    }
  }

  // ============ 兼容旧 API ============

  /// 兼容旧 API: 检查悬浮窗是否激活
  static bool get isOverlayActive => _bubbleActive;

  /// 兼容旧 API: 显示单条消息的悬浮窗
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
      print('显示悬浮窗失败: ${e.message}');
    }
  }

  /// 兼容旧 API: 关闭悬浮窗
  static Future<void> closeOverlay() async {
    try {
      await _channel.invokeMethod<bool>('closeOverlay');
    } on PlatformException {
      // ignore
    }
    _bubbleActive = false;
  }
}