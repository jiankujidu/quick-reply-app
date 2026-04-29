import 'package:flutter/services.dart';

/// 鎵嬫満閫氳瘽璁板綍鏈嶅姟 - 閫氳繃鍘熺敓灞傝鍙栫郴缁熼€氳瘽璁板綍
class CallLogService {
  static const _channel = MethodChannel('app.quickreply/overlay');

  /// 璇诲彇鎵嬫満閫氳瘽璁板綍
  static Future<List<DeviceCallLog>> readCallLogs() async {
    try {
      final result = await _channel.invokeMethod('readCallLogs');
      if (result == null) return [];
      
      final list = result as List<dynamic>;
      return list.map((item) => DeviceCallLog.fromMap(item as Map<dynamic, dynamic>)).toList();
    } on PlatformException catch (e) {
      print('readCallLogs error: ${e.message}');
      return [];
    }
  }

  /// 鏄惁鏈夋潈闄?  static Future<bool> hasPermission() async {
    try {
      final result = await _channel.invokeMethod('checkPermission');
      return result == true;
    } catch (_) {
      return false;
    }
  }

  /// 璇锋眰鏉冮檺锛堣烦杞缃〉锛?  static Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod('requestPermission');
    } catch (_) {}
  }
}

/// 閫氳瘽璁板綍鏁版嵁妯″瀷锛堜粠鎵嬫満璇诲彇锛?class DeviceCallLog {
  final String phoneNumber;
  final String contactName;
  final int startTime; // 姣鏃堕棿鎴?  final int durationSeconds;
  final String callType; // incoming, outgoing, missed

  DeviceCallLog({
    required this.phoneNumber,
    required this.contactName,
    required this.startTime,
    required this.durationSeconds,
    required this.callType,
  });

  factory DeviceCallLog.fromMap(Map<dynamic, dynamic> map) {
    return DeviceCallLog(
      phoneNumber: map['phoneNumber']?.toString() ?? '',
      contactName: map['contactName']?.toString() ?? '',
      startTime: (map['startTime'] as num?)?.toInt() ?? 0,
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
      callType: map['callType']?.toString() ?? 'unknown',
    );
  }

  DateTime get startDateTime => DateTime.fromMillisecondsSinceEpoch(startTime);

  /// 鏍煎紡鍖栨椂闀挎樉绀?  String get durationFormatted {
    if (durationSeconds < 60) return '${durationSeconds}绉?;
    final min = durationSeconds ~/ 60;
    final sec = durationSeconds % 60;
    if (sec == 0) return '${min}鍒?;
    return '${min}鍒?{sec}绉?;
  }

  /// 鏄惁瓒呰繃鎸囧畾绉掓暟
  bool isLongerThan(int seconds) => durationSeconds >= seconds;

  /// 鑾峰彇鍘婚噸鍚庣殑鍙风爜闆嗗悎
  static Set<String> getUniqueNumbers(List<DeviceCallLog> logs) {
    return logs.map((e) => e.phoneNumber).toSet();
  }

  /// 缁熻閲嶅娆℃暟
  static int getRepeatCount(List<DeviceCallLog> logs, String phone) {
    return logs.where((e) => e.phoneNumber == phone).length;
  }

  /// 鑾峰彇浠婃棩閫氳瘽璁板綍
  static List<DeviceCallLog> getTodayLogs(List<DeviceCallLog> logs) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    return logs.where((e) => e.startTime >= todayStart).toList();
  }

  /// 浠婃棩缁熻
  static Map<String, int> getTodayStats(List<DeviceCallLog> logs) {
    final today = getTodayLogs(logs);
    return {
      'total': today.length,
      'over30s': today.where((e) => e.isLongerThan(30)).length,
      'over50s': today.where((e) => e.isLongerThan(50)).length,
      'over1min': today.where((e) => e.isLongerThan(60)).length,
      'over2min': today.where((e) => e.isLongerThan(120)).length,
      'unique': getUniqueNumbers(today).length,
    };
  }

  /// 鎸夊彿鐮佸垎缁勭粺璁?  static Map<String, List<DeviceCallLog>> groupByNumber(List<DeviceCallLog> logs) {
    final map = <String, List<DeviceCallLog>>{};
    for (final log in logs) {
      map.putIfAbsent(log.phoneNumber, () => []).add(log);
    }
    return map;
  }
}
